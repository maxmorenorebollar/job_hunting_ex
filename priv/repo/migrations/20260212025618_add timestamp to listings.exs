defmodule :"Elixir.Jobs.Repo.Migrations.Add timestamp to listings" do
  use Ecto.Migration

  def change do
    alter table(:listings) do
      timestamps(default: fragment("now()"))
    end
  end
end
