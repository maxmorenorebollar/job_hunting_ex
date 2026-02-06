defmodule Jobs.Repo.Migrations.ChangeDescriptionToText do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      modify :description, :text
    end
  end
end
