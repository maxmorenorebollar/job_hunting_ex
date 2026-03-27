defmodule JobHuntingEx.Repo.Migrations.AddPrettyQueryId do
  use Ecto.Migration

  def change do
    alter table(:user_queries) do
      add :pretty_query_id, :string
    end
  end
end
