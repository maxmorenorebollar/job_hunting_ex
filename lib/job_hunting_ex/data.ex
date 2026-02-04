defmodule JobHuntingEx.Data do
  def polite_sleep do
    :timer.sleep(Enum.random(1000..3000))
  end

  def get_urls(params) do
    with {:ok, %{result: payload}} <- JobHuntingEx.McpClient.call_tool("search_jobs", params),
         %{"content" => [%{"text" => text} | _]} <- payload,
         {:ok, %{"data" => jobs}} <- Jason.decode(text) do
      IO.puts("extrating urls")
      Enum.map(jobs, fn job -> job["detailsPageUrl"] end)
    end
  end

  def get_html(url) do
    html_string = Req.get!(url).body
    {:ok, html} = Floki.parse_document(html_string)
    IO.puts("Retrieved html for #{url}")
    Floki.find(html, "[class^='job-detail-description']") |> List.first() |> Floki.text()
  end

  def get_embeddings(documents) do
    body = %{"model" => "qwen/qwen3-embedding-8b", "input" => elem(documents, 1)}

    response =
      Req.post!(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization:
            "Bearer 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",
          content_type: "application/json"
        ],
        json: body
      )

    Enum.map(response.body["data"], & &1["embedding"])
    |> Enum.zip(elem(documents, 0))
  end

  def process(params) do
    get_urls(params)
    |> Task.async_stream(fn url -> get_html(url) end, max_concurrency: 2, ordered: false)
    |> Stream.chunk_every(25)
    |> Task.async_stream()
    |> IO.inspect()
  end
end
