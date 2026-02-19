defmodule :"Elixir.JobHuntingEx.Repo.Migrations.Create vector extension" do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"
  end

  def down do
    execute "DROP EXTENSION vector"
  end
end
