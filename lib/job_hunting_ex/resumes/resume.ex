defmodule JobHuntingEx.Resumes.Resume do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resumes" do
    field :embeddings, Pgvector.Ecto.Vector

    timestamps(type: :utc_datetime)
  end

  def changeset(resume, params) do
    resume
    |> cast(params, [:embeddings])
    |> validate_required([:embeddings])
  end
end
