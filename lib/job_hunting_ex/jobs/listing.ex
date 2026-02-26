defmodule JobHuntingEx.Jobs.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listings" do
    field :url, :string
    field :title, :string
    field :description, :string
    field :embeddings, Pgvector.Ecto.Vector
    field :years_of_experience, :integer
    field :location, :string
    field :distance, :integer
    field :skills, {:array, :string}
    field :summary, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [
      :url,
      :title,
      :description,
      :embeddings,
      :years_of_experience,
      :location,
      :distance,
      :skills,
      :summary
    ])
    |> validate_required([:url, :description, :years_of_experience])
  end
end
