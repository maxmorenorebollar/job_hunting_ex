defmodule JobHuntingEx.Repo.Migrations.AddResumeTable do
  use Ecto.Migration

  def change do
    create table(:resumes) do
      add :embeddings, :vector, size: 1024
      timestamps()
    end
  end
end
