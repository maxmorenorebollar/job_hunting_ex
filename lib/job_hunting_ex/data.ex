defmodule JobHuntingEx.Data do
  require Logger
  import JobHuntingEx.Jobs

  def polite_sleep do
    :timer.sleep(Enum.random([1_000, 2_000, 3_000]))
  end

  def get_urls(params) do
    with {:ok, %{result: payload}} <- JobHuntingEx.McpClient.call_tool("search_jobs", params),
         %{"content" => [%{"text" => text} | _]} <- payload,
         {:ok, %{"data" => jobs}} <- Jason.decode(text) do
      Enum.map(jobs, fn job -> job["detailsPageUrl"] end)
    end
  end

  def get_html(url) do
    html_string = Req.get!(url).body
    {:ok, html} = Floki.parse_document(html_string)
    Logger.info("Retrieved html for #{url}")
    Floki.find(html, "[class^='job-detail-description']") |> List.first() |> Floki.text()
  end

  def get_embeddings(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => Enum.map(documents, fn {_url, html} -> html end)
    }

    response =
      Req.post!(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer #{Application.get_env(:job_hunting_ex, :openrouter_api_key)}",
          content_type: "application/json"
        ],
        json: body
      )

    Enum.zip(documents, Enum.map(response.body["data"], & &1["embedding"]))
    |> Enum.map(fn {{url, html}, embedding} ->
      %{
        "url" => url,
        "description" => html,
        "embeddings" => embedding
      }
    end)
  end

  def fetch_years_of_exerience(html) do
    body = %{
      "model" => "google/gemma-3-27b-it",
      "messages" => [
        %{
          "role" => "system",
          "content" =>
            "You are given a job listing. Determine what the minimum number of years of experience that would qualify someone for this role. Return the answer or -1 if not found"
        },
        %{
          "role" => "user",
          "content" => html
        }
      ],
      "response_format" => %{
        "type" => "json_schema",
        "json_schema" => %{
          "name" => "listing",
          "strict" => "true",
          "schema" => %{
            "type" => "object",
            "properties" => %{
              "minimum_years_of_experience" => %{
                "type" => "number",
                "description" => "The minimum years of experience required for the job"
              }
            }
          }
        }
      }
    }

    response =
      Req.post(
        url: "https://openrouter.ai/api/v1/chat/completions",
        headers: [
          authorization: "Bearer #{Application.get_env(:job_hunting_ex, :openrouter_api_key)}",
          content_type: "application/json"
        ],
        json: body
      )

    case response do
      {:ok, res} ->
        res.body
        |> Map.get("choices")
        |> List.first()
        |> Map.get("message")
        |> Map.get("content")
        |> Jason.decode!()
        |> Map.get("minimum_years_of_experience")

      error ->
        -1
    end
  end

  def extract_years_of_experience(html) do
    patterns = [
      ~r/(\d+)\+?\s*years?\s+of\s+experience/i,
      ~r/(\d+)\+?\s*years?\s+experience/i,
      ~r/(\d+)\+?\s*years?\s+professional\s+experience/i,
      ~r/(\d+)\+?\s*years?\s+relevant\s+experience/i,
      ~r/minimum\s+of\s+(\d+)\s*years?/i,
      ~r/at\s+least\s+(\d+)\s*years?/i,
      ~r/(\d+)\+?\s*years?\b/i
    ]

    years =
      Enum.flat_map(patterns, fn pattern ->
        Regex.scan(pattern, html)
        |> Enum.map(fn [_, num] -> String.to_integer(num) end)
      end)

    case years do
      [] -> nil
      list -> Enum.max(list)
    end
  end

  def process(params) do
    get_urls(params)
    |> Task.async_stream(
      fn url ->
        polite_sleep()
        html = get_html(url)
        {url, html}
      end,
      max_concurrency: 2,
      ordered: false,
      timeout: 10_000
    )
    |> Stream.map(fn {:ok, pair} -> pair end)
    |> Stream.chunk_every(25)
    |> Task.async_stream(fn batch -> get_embeddings(batch) end,
      max_concurrency: 3,
      ordered: false,
      timeout: 60_000
    )
    |> Enum.map(fn {:ok, result} -> result end)
    |> List.flatten()
    |> Enum.map(fn listing ->
      min_yoe = fetch_years_of_exerience(listing["description"])

      Map.put(listing, "years_of_experience", min_yoe)
    end)
    |> Enum.each(&create_listing(&1))
  end
end
