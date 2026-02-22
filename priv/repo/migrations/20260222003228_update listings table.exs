defmodule :"Elixir.JobHuntingEx.Repo.Migrations.Update listings table" do
  use Ecto.Migration

  def change do
    create table(:listings) do
      add :url, :string
      add :title, :string
      add :description, :text
      add :embeddings, :vector, size: 1024
      add :years_of_experience, :integer
      add :location, :string
      add :distance, :integer
    end
  end
end
