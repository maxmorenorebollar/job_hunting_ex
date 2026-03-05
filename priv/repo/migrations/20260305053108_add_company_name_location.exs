defmodule JobHuntingEx.Repo.Migrations.AddCompanyNameLocation do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      add :company_name, :string
      add :company_location, :string
    end
  end
end
