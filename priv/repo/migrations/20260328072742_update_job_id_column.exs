defmodule JobHuntingEx.Repo.Migrations.UpdateJobIdColumn do
  use Ecto.Migration

  def change do
    rename table(:query_results), :job_id, to: :query_id
  end
end
