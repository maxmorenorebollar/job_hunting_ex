defmodule JobHuntingEx.Queries.Data do
  require Logger
  alias JobHuntingEx.Jobs.Listings
  alias JobHuntingEx.Queries.Data

  defstruct [
    :url,
    :html,
    :job_title,
    :description,
    :skills,
    :years_of_experience,
    :summary,
    :embeddings,
    :error
  ]

  defp polite_sleep do
    :timer.sleep(Enum.random([1_000, 2_000, 3_000]))
  end

  @spec fetch_urls(String.t()) :: list(String.t())
  defp fetch_urls(params) do
    static_params = %{
      "radius_unit" => "mi",
      "jobs_per_page" => 10,
      "posted_date" => "ONE",
      "workplace_types" => ["On-Site", "Hybrid"]
    }

    query_params = Map.merge(params, static_params)

    with {:ok, %{result: payload}} <-
           JobHuntingEx.McpClient.call_tool("search_jobs", query_params),
         %{"content" => [%{"text" => text} | _]} <- payload,
         {:ok, %{"data" => jobs}} <- Jason.decode(text) do
      {:ok, Enum.map(jobs, fn job -> job["detailsPageUrl"] end)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @spec extract_description(String.t()) :: {:ok, String.t()} | {:error, String.t()}
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

  def get_embeddings(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => Enum.map(documents, fn document -> document.description end)
    }

    response =
      Req.post(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer ",
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

  def fetch_job_data(description) do
    body = %{
      "model" => "openai/gpt-oss-20b",
      "messages" => [
        %{
          "role" => "user",
          "content" =>
            "You are given a job listing. Determine what the minimum number of years of experience that would qualify someone for this role. Often you will see jobs requiring either a masters and some number of years of experience or a bachelors with more required years of experience. Take the years of expererience as if the applicant doesn't have a masters. You are allowed to make an educated guess on the years of experience based on the title. If it says senior then you can infer the required years of experience is 5 etc. Return the answer or -1 if not found. As well, determine what are the top 5 most needed skills for this role are and limit them to 1 or two words. If there are less than 5 skills needed that's okay. Also provide a one sentence summary of the description. Pay close attention to what you would actually be working on in the job like particular teams. Here is the listing: #{description}"
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
        auth: {:bearer, ""},
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

  defp handle_result({:ok, %{error: _reason} = _data}) do
    []
  end

  defp handle_result({:exit, _reason}) do
    []
  end

  def process(params) do
    _myoe = params["minimum_years_of_experience"]

    params_modified =
      Map.filter(params, fn {key, _value} -> key != "minimum_years_of_experience" end)

    result =
      with {:ok, urls} <- fetch_urls(params_modified) do
        urls
        |> Enum.map(fn url -> %Data{url: url} end)
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
        |> Stream.chunk_every(25)
        |> Task.async_stream(
          fn batch ->
            case get_embeddings(batch) do
              {:ok, embeddings} ->
                Enum.zip(batch, embeddings)
                |> Enum.map(fn
                  {data, emb} -> %{data | embeddings: emb}
                end)

              {:error, reason} ->
                Enum.map(batch, fn data -> %{data | error: "Embedding Error: #{reason}"} end)
            end
          end,
          max_concurrency: 2,
          ordered: false,
          timeout: 60_000
        )
        |> Stream.flat_map(&handle_result(&1))
        |> Enum.map(fn data -> Listings.create(Map.from_struct(data)) end)
        |> IO.inspect()
        |> Enum.flat_map(fn
          {:ok, struct} -> [struct]
          # throw away all errors for now
          {:error, _struct} -> []
        end)
      else
        {:error, err} ->
          Logger.error("Could not query Dice MCP", "reason: #{err}")
          {:error, "Failled on start"}
      end

    result
  end
end
