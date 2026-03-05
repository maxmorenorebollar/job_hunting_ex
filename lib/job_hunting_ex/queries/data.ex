defmodule JobHuntingEx.Queries.Data do
  require Logger
  alias JobHuntingEx.Jobs.Listings
  alias JobHuntingEx.Queries.Data
  alias JobHuntingEx.Resumes.Resumes
  alias JobHuntingEx.Jobs.Listing

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

  defp polite_sleep do
    :timer.sleep(Enum.random([1_000, 1_500, 1_750]))
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

  def test(params) do
    static_params = %{
      "radius_unit" => "mi",
      "jobs_per_page" => 100,
      "posted_date" => "THREE",
      "workplace_types" => ["On-Site", "Hybrid"]
    }

    query_params = Map.merge(params, static_params)

    {:ok, %{result: payload}} =
      JobHuntingEx.McpClient.call_tool("search_jobs", query_params)

    payload
  end

  def extract_description(html_string) do
    case Floki.parse_document(html_string) do
      {:ok, document} ->
        description =
          document
          |> Floki.find("[class^='job-detail-description']")
          |> List.first()
          |> Floki.text()

        {:ok, description}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec fetch_description(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp fetch_description(url) do
    with {:ok, response} <- Req.get(url),
         {:ok, description} <- extract_description(response.body) do
      case description do
        "" -> {:error, "Description could not be found"}
        _ -> {:ok, description}
      end
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def get_embeddings(documents) when is_list(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => Enum.map(documents, fn document -> document.description end)
    }

    response =
      Req.post(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
          content_type: "application/json"
        ],
        json: body
      )

    # response body will have map %{"data" => [list of embeddings]} as response
    case response do
      {:ok, res} ->
        embeddings =
          res.body["data"]
          |> Enum.map(& &1["embedding"])

        {:ok, embeddings}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec get_embeddings(String.t()) :: list(float())
  def get_embeddings(document) when is_binary(document) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => document
    }

    response =
      Req.post(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
          content_type: "application/json"
        ],
        json: body
      )

    # response body will have map %{"data" => [list of embeddings]} as response
    case response do
      {:ok, res} ->
        embeddings =
          res.body["data"]
          |> List.first()
          |> Map.get("embedding")

        {:ok, embeddings}

      {:error, reason} ->
        {:error, reason}
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
        IO.inspect(res.body)

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
    Logger.error("Failure: #{IO.inspect(reason)} )")
    []
  end

  defp handle_result({:exit, reason}) do
    Logger.error("Exit: #{IO.inspect(reason)}")
    []
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
    IO.inspect(params)

    static_params = %{
      "radius_unit" => "mi",
      "jobs_per_page" => 100,
      "posted_date" => "THREE"
    }

    {min_yoe, _remainder} = Integer.parse(params["minimum_years_of_experience"])
    {max_yoe, _remainder} = Integer.parse(params["maximum_years_of_experience"])

    static_params =
      if params["remote?"] do
        Map.put(static_params, "workplace_types", ["On-Site", "Hybrid", "Remote"])
      else
        Map.put(static_params, "workplace_types", ["On-Site", "Hybrid"])
      end

    params_modified =
      Map.filter(params, fn {key, _value} -> key != "minimum_years_of_experience" end)
      |> Map.filter(fn {key, _value} -> key != "maximum_years_of_experience" end)
      |> Map.filter(fn {key, _value} -> key != "remote?" end)

    params_merged = Map.merge(static_params, params_modified)

    listing_ids =
      with {:ok, jobs} <- fetch_jobs(params_merged) do
        jobs
        |> Enum.map(fn {url, company_name, company_location} ->
          %Data{url: url, company_name: company_name, company_location: company_location}
        end)
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
        |> Enum.map(fn data -> Listings.create(Map.from_struct(data)) end)
        |> Enum.flat_map(fn
          {:ok, struct} -> [struct.id]
          # throw away all errors for now
          {:error, _struct} -> []
        end)
      else
        {:error, err} ->
          Logger.error("Could not query Dice MCP", "reason: #{IO.inspect(err)}")
          {:error, "Failled on start"}
      end

    case listing_ids do
      {:error, reason} ->
        {:error, reason}

      ids when is_list(ids) ->
        {:ok, embeddings} = get_embeddings(resume_text)
        {:ok, resume} = Resumes.create(%{"embeddings" => embeddings})

        JobHuntingEx.Repo.all(
          from i in Listing,
            where:
              i.id in ^ids and i.years_of_experience >= ^min_yoe and
                i.years_of_experience <= ^max_yoe,
            order_by: cosine_distance(i.embeddings, ^resume.embeddings)
        )
    end
  end
end
