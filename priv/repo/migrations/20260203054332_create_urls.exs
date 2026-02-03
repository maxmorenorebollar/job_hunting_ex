defmodule Jobs.Repo.Migrations.CreateUrls do
  use Ecto.Migration

  def change do
    create table(:urls) do
      add :url, :string
      add :description, :string
      add :embeddings, :blob
    end
  end
end
