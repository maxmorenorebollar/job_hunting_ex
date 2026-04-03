defmodule JobHuntingEx.Queries.UserQuery do
  use Ecto.Schema
  alias Ecto.Changeset

  schema "user_queries" do
    field :keyword, :string
    field :location, :string
    field :radius, :integer
    field :workplace_types, {:array, :string}
    field :minimum_years_of_experience, :integer
    field :maximum_years_of_experience, :integer
    field :remote?, :boolean
    field :pretty_query_id, :string
    field :user_id, :integer
    field :resume_text, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(query, params \\ %{}) do
    query
    |> Changeset.cast(params, [
      :keyword,
      :location,
      :radius,
      :workplace_types,
      :minimum_years_of_experience,
      :maximum_years_of_experience,
      :remote?,
      :pretty_query_id
    ])
    |> Changeset.validate_required([
      :keyword,
      :location,
      :radius,
      :workplace_types,
      :minimum_years_of_experience,
      :maximum_years_of_experience,
      :remote?,
      :pretty_query_id
    ])
  end

  def user_query_changeset(query, params \\ %{}) do
    query
    |> Changeset.cast(params, [
      :keyword,
      :location,
      :radius,
      :workplace_types,
      :minimum_years_of_experience,
      :maximum_years_of_experience,
      :remote?,
      :pretty_query_id,
      :user_id,
      :resume_text
    ])
    |> Changeset.validate_required([
      :keyword,
      :location,
      :radius,
      :workplace_types,
      :minimum_years_of_experience,
      :maximum_years_of_experience,
      :remote?,
      :pretty_query_id,
      :user_id,
      :resume_text
    ])
  end
end
