defmodule JobHuntingEx.Repo.Migrations.AddQueryIdToUserQueries do
  use Ecto.Migration

  def change do
    alter table(:user_queries) do
      add :user_id, references(:users)
    end
  end
end
