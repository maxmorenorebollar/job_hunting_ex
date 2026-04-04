defmodule JobHuntingEx.Embeddings do
  @moduledoc """
  Provides functions to retrieve embeddings for a single document and multiple documents
  """
  alias JobHuntingEx.Error
  alias JobHuntingEx.Embeddings

  @spec fetch_embeddings(list(String.t())) :: {:ok, list(list(float()))} | {:error, String.t()}
  def fetch_embeddings(documents) when is_list(documents) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => documents
    }

    req_options = [
      method: :post,
      url: "https://openrouter.ai/api/v1/embeddings",
      json: body
    ]

    request =
      req_options
      |> Keyword.merge(Application.get_env(:job_hunting_ex, :openrouter_req_options))
      |> Req.request()

    # response should be of the form %Req.Response{body: %{"data" => [%{"embedding" => single embedding list}, ...many more maps]}}
    # data is a list with n elements where each element is a map with key embedding and value of list of floats

    with {:ok, %Req.Response{status: 200, body: body}} <- request,
         changeset <-
           Embeddings.OpenrouterResponse.changeset(%Embeddings.OpenrouterResponse{}, body),
         %Ecto.Changeset{valid?: true} = valid_changeset <- changeset do
      all_embeddings =
        valid_changeset
        |> Ecto.Changeset.apply_changes()
        |> then(fn response_body -> response_body.data end)
        |> Enum.map(& &1.embedding)

      {:ok, all_embeddings}
    else
      {:ok, %Req.Response{status: status_code}} ->
        {:error, "Request failed with status code #{status_code}"}

      {:error, err} ->
        {:error, Error.normalize_error(err)}

      %{} ->
        {:error, "Openrouter request body was malformed"}
    end
  end

  @spec fetch_embeddings(String.t()) :: {:ok, list(float())} | {:error, String.t()}
  def fetch_embeddings(document) when is_binary(document) do
    body = %{
      "model" => "baai/bge-m3",
      "input" => document
    }

    req_options = [
      method: :post,
      url: "https://openrouter.ai/api/v1/embeddings",
      json: body
    ]

    request =
      req_options
      |> Keyword.merge(Application.get_env(:job_hunting_ex, :openrouter_req_options))
      |> Req.request()

    # response should be of the form %Req.Response{body: %{"data" => [%{"embedding" => single embedding list}]}}
    # data is a list with 1 element: a map with key embedding and value of list of floats
    with {:ok, %Req.Response{status: 200, body: body}} <- request,
         changeset <-
           Embeddings.OpenrouterResponse.changeset(%Embeddings.OpenrouterResponse{}, body),
         %Ecto.Changeset{valid?: true} = valid_changeset <- changeset do
      [all_embeddings] =
        valid_changeset
        |> Ecto.Changeset.apply_changes()
        |> then(fn response_body -> response_body.data end)
        |> Enum.map(& &1.embedding)

      {:ok, all_embeddings}
    else
      {:ok, %Req.Response{status: status_code}} ->
        {:error, "Openrouter request failed with status code #{status_code}"}

      {:error, err} ->
        {:error, Error.normalize_error(err)}

      %{} ->
        {:error, "Openrouter request body was malformed"}
    end
  end
end
