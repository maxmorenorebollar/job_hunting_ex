defmodule JobHuntingEx.Repo.Migrations.MakeTimeStampsUtc do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      modify :inserted_at, :utc_datetime, from: :naive_datetime
      modify :updated_at, :utc_datetime, from: :naive_datetime
    end

    alter table(:resumes) do
      modify :inserted_at, :utc_datetime, from: :naive_datetime
      modify :updated_at, :utc_datetime, from: :naive_datetime
    end

    alter table(:query_results) do
      add :inserted_at, :utc_datetime, null: false, default: fragment("NOW()")
      add :updated_at, :utc_datetime, null: false, default: fragment("NOW()")
    end
  end
end
