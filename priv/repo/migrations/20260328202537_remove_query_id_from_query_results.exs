defmodule JobHuntingEx.Repo.Migrations.RemoveQueryIdFromQueryResults do
  use Ecto.Migration

  def up do
    alter table(:query_results) do
      remove :query_id
    end
  end

  def down do
    alter table(:query_results) do
      add :query_id, :uuid
    end
  end
end
