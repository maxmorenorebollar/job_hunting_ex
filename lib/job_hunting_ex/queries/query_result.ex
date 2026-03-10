defmodule JobHuntingEx.Queries.QueryResult do
  use Ecto.Schema
  import Ecto.Changeset

  schema "query_results" do
    field :job_id, :binary_id
    field :listing_id, :integer
    field :sequence, :integer
  end

  def changeset(query_result, params) do
    query_result
    |> cast(params, [:job_id, :listing_id, :sequence])
    |> validate_required([:job_id, :listing_id, :sequence])
  end
end
