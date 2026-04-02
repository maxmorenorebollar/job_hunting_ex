defmodule JobHuntingEx.Repo.Migrations.AddResumeTextToUserQueryTable do
  use Ecto.Migration

  def change do
    alter table(:user_queries) do
      add :resume_text, :text
    end
  end
end
