defmodule JobHuntingEx.Repo.Migrations.CreateUserQueryTable do
  use Ecto.Migration

  def change do
    create table(:user_queries) do
      add :keyword, :string
      add :location, :string
      add :radius, :integer
      add :workplace_types, {:array, :string}
      add :minimum_years_of_experience, :integer
      add :maximum_years_of_experience, :integer
      add :remote?, :boolean

      timestamps(type: :utc_datetime)
    end
  end
end
