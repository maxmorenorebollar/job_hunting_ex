defmodule JobHuntingEx.Repo.Migrations.AddQueryResultsTable do
  use Ecto.Migration

  def change do
    create table(:query_results, primary_key: false) do
      add :job_id, :uuid, primary_key: true, null: false
      add :listing_id, :integer, null: false
      add :sequence, :integer, null: false
    end
  end
end
