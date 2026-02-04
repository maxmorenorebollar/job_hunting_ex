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
    IO.puts("starting getting embeddings")

    body = %{
      "model" => "qwen/qwen3-embedding-8b",
      "input" => Enum.map(documents, fn {_url, html} -> html end)
    }

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

    Enum.zip(documents, Enum.map(response.body["data"], & &1["embedding"]))
  end

  def write_all(embeddings) do
  end

  def process(params) do
    get_urls(params)
    |> Task.async_stream(
      fn url ->
        html = get_html(url)
        {url, html}
      end,
      max_concurrency: 2,
      ordered: false
    )
    |> Stream.map(fn {:ok, pair} -> pair end)
    |> Stream.chunk_every(25)
    |> Task.async_stream(fn batch -> get_embeddings(batch) end,
      max_concurrency: 2,
      ordered: false
    )
    |> Enum.take(1)
  end
end
