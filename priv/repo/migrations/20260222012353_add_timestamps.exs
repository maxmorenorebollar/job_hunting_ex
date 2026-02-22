defmodule JobHuntingEx.Repo.Migrations.AddTimestamps do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      timestamps()
    end
  end
end
