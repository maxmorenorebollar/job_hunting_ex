defmodule JobHuntingEx.Queries.QueryResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "query_results" do
    field :query_id, :integer
    field :listing_id, :integer
    field :sequence, :integer
    timestamps(type: :utc_datetime)
  end

  def changeset(query_result, params) do
    query_result
    |> cast(params, [:query_id, :listing_id, :sequence])
    |> validate_required([:query_id, :listing_id, :sequence])
  end
end
