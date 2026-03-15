defmodule JobHuntingEx.Scraper do
  @moduledoc """
  Provides function to download, and process html
  """

  alias JobHuntingEx.Error

  defp http_client() do
    Application.get_env(:job_hunting_ex, :http_client)
  end

  @spec extract_description(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract_description(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      description =
        document
        |> Floki.find("[class^='job-detail-description']")
        |> List.first()
        |> Floki.text()

      case description do
        "" -> {:error, "Description could not be found"}
        _ -> {:ok, description}
      end
    end
  end

  @spec extract_title(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def extract_title(html) do
    with {:ok, document} <- Floki.parse_document(html) do
      job_title =
        document
        |> Floki.find("h1")
        |> List.first()
        |> Floki.text()

      case job_title do
        "" -> {:error, "Job title could not be found"}
        _ -> {:ok, job_title}
      end
    end
  end

  @spec fetch_html(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def fetch_html(url) do
    case http_client().get(url) do
      {:ok, response} ->
        {:ok, response.body}

      {:error, err} ->
        {:error, "Failed to fetch description. Reason: #{Error.normalize_error(err)}"}
    end
  end
end
