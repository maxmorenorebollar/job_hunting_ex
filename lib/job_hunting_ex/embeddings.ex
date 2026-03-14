defmodule JobHuntingEx.Embeddings do
  @moduledoc """
  Provides functions to retrieve embeddings for a single document and multiple documents
  """
  alias JobHuntingEx.Error

  defp http_client() do
    Application.get_env(:job_hunting_ex, :http_client)
  end

  @spec get_embeddings(list(String.t())) :: {:ok, list(list(float()))} | {:error, String.t()}
  def get_embeddings(documents) when is_list(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => documents
    }

    # response body will have map %{"data" => [list of embeddings]} as response
    response =
      http_client().post(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
          content_type: "application/json"
        ],
        json: body
      )

    case response do
      {:ok, res} ->
        embeddings = Enum.map(res.body["data"], & &1["embedding"])
        {:ok, embeddings}

      {:error, err} ->
        {:error, Error.normalize_error(err)}
    end
  end

  @spec get_embeddings(String.t()) :: {:ok, list(float())} | {:error, String.t()}
  def get_embeddings(document) when is_binary(document) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => document
    }

    response =
      http_client().post(
        url: "https://openrouter.ai/api/v1/embeddings",
        headers: [
          authorization: "Bearer #{System.get_env("OPENROUTER_API_KEY")}",
          content_type: "application/json"
        ],
        json: body
      )

    case response do
      {:ok, res} ->
        [embeddings] = Enum.map(res.body["data"], & &1["embedding"])
        {:ok, embeddings}

      {:error, err} ->
        {:error, Error.normalize_error(err)}
    end
  end
end
