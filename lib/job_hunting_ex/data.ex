defmodule JobHuntingEx.Data do
  import JobHuntingEx.Jobs

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
      "model" => "baai/bge-m3",
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
    |> Enum.map(fn {{url, html}, embedding} ->
      %{"url" => url, "description" => html, "embeddings" => embedding}
    end)
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
    |> Enum.map(fn {:ok, result} -> result end)
    |> List.flatten()
    |> Enum.each(&create_listing(&1))
  end
end
