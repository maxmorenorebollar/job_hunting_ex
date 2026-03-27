defmodule JobHuntingEx.Repo.Migrations.AddQueryId do
  use Ecto.Migration

  def change do
    alter table(:query_results) do
      add :query_id, references("user_queries")
    end
  end
end
