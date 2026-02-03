defmodule Jobs.Repo.Migrations.CreateListings do
  use Ecto.Migration

  def change do
    create table(:listings) do
     add :url, :string
     add :description, :string
     add :embeddings, :binary
    end
  end
end
