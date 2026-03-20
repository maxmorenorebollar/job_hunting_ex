defmodule JobHuntingEx.Jobs.Listing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "listings" do
    field :url, :string
    field :title, :string
    field :company_name, :string
    field :company_location, :string
    field :description, :string
    field :embeddings, Pgvector.Ecto.Vector
    field :years_of_experience, :integer
    field :location, :string
    field :distance, :integer
    field :skills, {:array, :string}
    field :summary, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(listing, params) do
    listing
    |> cast(params, [
      :url,
      :title,
      :company_name,
      :company_location,
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
