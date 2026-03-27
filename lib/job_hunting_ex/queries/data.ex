defmodule JobHuntingEx.Queries.Data do
  @moduledoc """
  Provides the main functionality to handle processing a query
  """

  require Logger

  alias JobHuntingEx.Queries.Data
  alias JobHuntingEx.Resumes.Resumes
  alias JobHuntingEx.Jobs.Listing
  alias JobHuntingEx.Cache
  alias JobHuntingEx.Embeddings
  alias JobHuntingEx.LlmApi
  alias JobHuntingEx.Scraper

  @id_size 8

  defstruct [
    :url,
    :html,
    :company_name,
    :company_location,
    :title,
    :description,
    :skills,
    :years_of_experience,
    :summary,
    :embeddings,
    :error
  ]

  defp polite_sleep do
    :timer.sleep(Enum.random([750, 1_000, 1_250]))
  end

  def fetch_jobs(params) do
    with {:ok, %{result: payload}} <- JobHuntingEx.McpClient.call_tool("search_jobs", params),
         %{"content" => [%{"text" => text} | _]} <- payload,
         {:ok, %{"data" => jobs}} <- Jason.decode(text) do
      jobs_with_data =
        jobs
        |> Enum.map(fn job ->
          {job["detailsPageUrl"], job["companyName"], job["jobLocation"]["displayName"]}
        end)

      {:ok, jobs_with_data}
    else
      reason -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_result({:ok, %{error: nil} = data}) do
    [data]
  end

  defp handle_result({:ok, list}) when is_list(list) do
    Enum.filter(list, fn data -> data.error == nil end)
  end

  defp handle_result({:ok, %{error: reason} = _data}) do
    Logger.error("Failure: #{inspect(reason)}")
    []
  end

  defp handle_result({:exit, reason}) do
    Logger.error("Exit: #{inspect(reason)}")
    []
  end

  defp normalize_query_params(params) do
    static_params = %{
      "radius_unit" => "mi",
      "jobs_per_page" => 100,
      "posted_date" => "THREE"
    }

    static_params =
      if params["remote?"] do
        Map.put(static_params, "workplace_types", ["On-Site", "Hybrid", "Remote"])
      else
        Map.put(static_params, "workplace_types", ["On-Site", "Hybrid"])
      end

    {_extra_keys, needed_keys} =
      Map.split(params, ["minimum_years_of_experience", "maximum_years_of_experience", "remote?"])

    Map.merge(static_params, needed_keys)
  end

  defp get_jobs(params_merged) do
    with {:ok, jobs} <- fetch_jobs(params_merged) do
      jobs
      |> Enum.map(fn {url, company_name, company_location} ->
        %Data{url: url, company_name: company_name, company_location: company_location}
      end)
      |> Enum.split_with(fn data ->
        case Cachex.exists?(:cache, data.url) do
          {:ok, true} -> true
          {:ok, false} -> false
        end
      end)
    end
  end

  def process(%{
        "keyword" => keyword,
        "minimum_years_of_experience" => min,
        "maximum_years_of_experience" => max,
        "radius" => radius
      })
      when keyword == "" or min == "" or max == "" or radius == "" do
    Logger.error("Query is malformed")
    {:error, "Query is malformed"}
  end

  def process(params, resume_text) do
    {min_yoe, _remainder} = Integer.parse(params["minimum_years_of_experience"])
    {max_yoe, _remainder} = Integer.parse(params["maximum_years_of_experience"])

    mcp_params = normalize_query_params(params)
    pretty_query_id = Nanoid.generate(@id_size)

    query_params =
      mcp_params
      |> Map.put("pretty_query_id", pretty_query_id)
      |> Map.put("minimum_years_of_experience", min_yoe)
      |> Map.put("maximum_years_of_experience", max_yoe)
      |> Map.put("remote?", params["remote?"])

    {:ok, user_query} = JobHuntingEx.Queries.create_user_query(query_params)

    listing_urls =
      with {processed, need_to_process} when is_list(processed) <- get_jobs(mcp_params) do
        need_to_process
        |> Task.async_stream(
          fn data ->
            polite_sleep()

            with {:ok, html} <- Scraper.fetch_html(data.url),
                 {:ok, description} <- Scraper.extract_description(html),
                 {:ok, job_title} <- Scraper.extract_title(html) do
              Logger.info(job_title)
              %{data | description: description, title: job_title}
            else
              {:error, reason} -> %{data | error: reason}
            end
          end,
          max_concurrency: 6,
          ordered: false,
          timeout: 10_000,
          on_timeout: :kill_task
        )
        |> Stream.flat_map(&handle_result(&1))
        |> Task.async_stream(
          fn data ->
            case LlmApi.fetch_job_data(data.description) do
              {:ok, result} ->
                %{
                  data
                  | years_of_experience: result.min_years_of_experience,
                    skills: result.skills,
                    summary: result.summary
                }

              {:error, reason} ->
                %{data | error: reason}
            end
          end,
          max_concurrency: 20,
          ordered: false,
          timeout: 10_000,
          on_timeout: :kill_task
        )
        |> Stream.flat_map(&handle_result(&1))
        |> Stream.chunk_every(20)
        |> Task.async_stream(
          fn batch ->
            case Embeddings.fetch_embeddings(Enum.map(batch, & &1.description)) do
              {:ok, embeddings} ->
                Enum.zip(batch, embeddings)
                |> Enum.map(fn
                  {data, emb} -> %{data | embeddings: emb}
                end)

              {:error, reason} ->
                Enum.map(batch, fn data ->
                  %{data | error: reason}
                end)
            end
          end,
          max_concurrency: 2,
          ordered: false,
          timeout: 100_000
        )
        |> Stream.flat_map(&handle_result(&1))
        |> Enum.to_list()
        |> Cache.write_through()
        |> case do
          {:ok, listings} -> Enum.map(listings, & &1.url) ++ Enum.map(processed, & &1.url)
          {:error, reason} -> {:error, reason}
        end
      else
        {:error, err} ->
          Logger.error("Could not query Dice MCP, reason: #{inspect(err)}")
          {:error, "Failled on start"}
      end

    case listing_urls do
      urls when is_list(urls) ->
        with {:ok, embeddings} <- Embeddings.fetch_embeddings(resume_text),
             {:ok, resume} <- Resumes.create(%{"embeddings" => embeddings}) do
          ordered_listings =
            JobHuntingEx.Queries.cosine_search(resume, urls, min_yoe, max_yoe)

          query_results =
            Enum.with_index(ordered_listings, fn listing, index ->
              %{query_id: user_query.id, listing_id: listing.id, sequence: index}
            end)

          case JobHuntingEx.Queries.create_query_results(query_results) do
            {:ok, _results} -> {:ok, pretty_query_id}
            {:error, reason} -> {:error, reason}
          end
        else
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
