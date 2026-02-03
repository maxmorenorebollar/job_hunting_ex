defmodule Jobs.Listing do
  use Ecto.Schema

  schema "listing" do
    field :url, :string
    field :description, :string
    field :embeddings, :binary
  end
end
