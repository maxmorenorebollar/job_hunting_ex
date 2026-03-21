defmodule JobHuntingEx.Embeddings.EmbeddingData do
  @moduledoc """
  Embedded Schema to validate each document
  embeddings from an openrouter repsonse body
  """
  use Ecto.Schema
  alias Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :embedding, {:array, :float}
  end

  def changeset(embedding_data, params \\ %{}) do
    embedding_data
    |> Changeset.cast(params, [:embedding])
    |> Changeset.validate_required(:embedding)
  end
end
