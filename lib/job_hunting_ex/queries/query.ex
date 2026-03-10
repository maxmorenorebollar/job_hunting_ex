defmodule JobHuntingEx.Queries.Query do
  use Ecto.Schema
  alias Ecto.Changeset

  embedded_schema do
    field :keyword, :string
    field :location, :string
    field :radius, :integer
    field :posted_date, :string
    field :workplace_types, {:array, :string}
    field :minimum_years_of_experience, :integer
    field :maximum_years_of_experience, :integer
    field :remote?, :boolean
  end

  def changeset(query, params \\ %{}) do
    query
    |> Changeset.cast(params, [
      :keyword,
      :location,
      :radius,
      :posted_date,
      :workplace_types,
      :minimum_years_of_experience,
      :maximum_years_of_experience,
      :remote?
    ])
    |> Changeset.validate_required([
      :keyword,
      :minimum_years_of_experience,
      :maximum_years_of_experience
    ])
  end
end
