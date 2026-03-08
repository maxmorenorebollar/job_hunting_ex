defmodule JobHuntingEx.Queries.Data do
  require Logger
  # alias JobHuntingEx.Jobs.Listings
  alias JobHuntingEx.Queries.Data
  alias JobHuntingEx.Resumes.Resumes
  alias JobHuntingEx.Jobs.Listing

  alias JobHuntingEx.Cache

  import Ecto.Query
  import Pgvector.Ecto.Query

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

  defp http_client() do
    Application.get_env(:job_hunting_ex, :http_client)
  end

  defp polite_sleep do
    :timer.sleep(Enum.random([1_000, 1_500, 1_750]))
  end

  defp normalize_error(err) when is_binary(err) do
    err
  end

  defp normalize_error(err) when is_exception(err) do
    Exception.message(err)
  end

  defp normalize_error(err) do
    inspect(err)
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
      {:error, reason} -> {:error, reason}
    end
  end

  @spec fetch_description(String.t(), module()) :: {:ok, String.t()} | {:error, String.t()}
  def fetch_description(url, http_client \\ Req) do
    with {:ok, response} <- http_client.get(url),
         {:ok, description} <- extract_description(response.body) do
      {:ok, description}
    else
      {:error, err} ->
        {:error, ["Failed to fetch description for", url, normalize_error(err)]}
    end
  end

  defp extract_description(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      description =
        document
        |> Floki.find("[class^='job-detail-description']")
        |> List.first()
        |> Floki.text()

      case description do
        "" -> {:error, ["Description could not be found"]}
        _ -> {:ok, description}
      end
    end
  end

  @spec get_embeddings(list(String.t())) :: list(list(float()))
  def get_embeddings(documents) when is_list(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => Enum.map(documents, fn document -> document.description end)
    }

    # response body will have map %{"data" => [list of embeddings]} as response
    with {:ok, res} <-
           http_client().post(
             url: "https://openrouter.ai/api/v1/embeddings",
             headers: [
               authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
               content_type: "application/json"
             ],
             json: body
           ) do
      embeddings =
        res.body["data"]
        |> Enum.map(& &1["embedding"])

      {:ok, embeddings}
    else
      {:error, err} -> {:error, [normalize_error(err)]}
    end
  end

  @spec get_embeddings(String.t()) :: {:ok, list(float())} | {:error, list()}
  def get_embeddings(document) when is_binary(document) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => document
    }

    with {:ok, res} <-
           http_client().post(
             url: "https://openrouter.ai/api/v1/embeddings",
             headers: [
               authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
               content_type: "application/json"
             ],
             json: body
           ) do
      [embedding] =
        res.body["data"]
        |> Enum.map(& &1["embedding"])

      {:ok, embedding}
    else
      {:error, err} -> {:error, [normalize_error(err)]}
    end
  end

  def fetch_job_data(description) do
    body = %{
      "model" => "openai/gpt-oss-20b",
      "messages" => [
        %{
          "role" => "user",
          "content" =>
            "You are given a job listing. Determine what the minimum number of years of experience that would qualify someone for this role. Often you will see jobs requiring either a masters and some number of years of experience or a bachelors with more required years of experience. Take the years of expererience as if the applicant doesn't have a masters. You are allowed to make an educated guess on the years of experience based on the title. Overall, you should return the years of experience as a whole number number rounding up. If it says senior then you can infer the required years of experience is 5 etc. Return the answer or -1 if not found. As well, determine what are the top 5 most needed skills for this role are and limit them to 1 or two words. If there are less than 5 skills needed that's okay. Also provide a one sentence summary of the description. Pay close attention to what you would actually be working on in the job like particular teams. Here is the listing: #{description}"
        }
      ],
      "response_format" => %{
        "type" => "json_schema",
        "json_schema" => %{
          "name" => "listing",
          "strict" => true,
          "schema" => %{
            "type" => "object",
            "properties" => %{
              "min_years_of_experience" => %{
                "type" => "number"
              },
              "skills" => %{
                "type" => "array",
                "items" => %{"type" => "string"}
              },
              "summary" => %{
                "type" => "string"
              }
            },
            "required" => ["min_years_of_experience", "skills", "summary"],
            "additionalProperties" => false
          }
        }
      }
    }

    response =
      Req.post(
        url: "https://api.groq.com/openai/v1/chat/completions",
        auth: {:bearer, "#{System.get_env("GROQ_API_KEY")}"},
        json: body
      )

    case response do
      {:ok, res} ->
        json_content =
          res.body
          |> Map.get("choices")
          |> List.first()
          |> Map.get("message")
          |> Map.get("content")
          |> Jason.decode()

        case json_content do
          {:ok, %{"min_years_of_experience" => -1}} ->
            {:error, "Minimum years of experience could not be extracted"}

          {:ok,
           %{
             "min_years_of_experience" => years,
             "skills" => skills,
             "summary" => summary
           }} ->
            {:ok,
             %{
               "min_years_of_experience" => years,
               "skills" => skills,
               "summary" => summary
             }}
        end

      {:error, reason} ->
        {:error, reason}
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

    params_merged = normalize_query_params(params)

    listing_ids =
      with {processed, need_to_process} when is_list(processed) <- get_jobs(params_merged) do
        Logger.info(length(processed))

        need_to_process
        |> Task.async_stream(
          fn data ->
            polite_sleep()

            case fetch_description(data.url) do
              {:ok, description} ->
                %{data | description: description}

              {:error, reason} ->
                %{data | error: reason}
            end
          end,
          max_concurrency: 2,
          ordered: false,
          timeout: 10_000,
          on_timeout: :kill_task
        )
        |> Stream.flat_map(&handle_result(&1))
        |> Task.async_stream(
          fn data ->
            case fetch_job_data(data.description) do
              {:ok, result} ->
                %{
                  data
                  | years_of_experience: result["min_years_of_experience"],
                    skills: result["skills"],
                    summary: result["summary"]
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
            case get_embeddings(batch) do
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
          Logger.error("Could not query Dice MCP", "reason: #{IO.inspect(err)}")
          {:error, "Failled on start"}
      end

    case listing_ids do
      {:error, reason} ->
        {:error, reason}

      ids when is_list(ids) ->
        with {:ok, embeddings} <- get_embeddings(resume_text),
             {:ok, resume} <- Resumes.create(%{"embeddings" => embeddings}) do
          JobHuntingEx.Repo.all(
            from i in Listing,
              where:
                i.url in ^ids and i.years_of_experience >= ^min_yoe and
                  i.years_of_experience <= ^max_yoe,
              order_by: cosine_distance(i.embeddings, ^resume.embeddings)
          )
        else
          {:error, reason} -> {:error, reason}
        end
    end
  end
end
