defmodule JobHuntingEx.Embeddings.OpenrouterResponse do
  @moduledoc """
  Embedded Schema to validate incoming requests from Openrouter
  """
  use Ecto.Schema

  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many :data, JobHuntingEx.Embeddings.EmbeddingData
  end

  def changeset(openrouter_response, params \\ %{}) do
    openrouter_response
    |> Changeset.cast(params, [])
    |> Changeset.cast_embed(:data, required: true)
  end
end
