defmodule JobHuntingEx.LlmApi.GroqResponse do
  @moduledoc """
  Embedded Schema to validate incoming requests from Groq
  """
  use Ecto.Schema

  alias Ecto.Changeset

  @type t :: %__MODULE__{
          min_years_of_experience: integer(),
          skills: [String.t()],
          summary: String.t()
        }

  @primary_key false
  embedded_schema do
    field :min_years_of_experience, :integer
    field :skills, {:array, :string}
    field :summary, :string
  end

  def changeset(groq_response, params \\ %{}) do
    groq_response
    |> Changeset.cast(params, [:min_years_of_experience, :skills, :summary])
    |> Changeset.validate_required([:min_years_of_experience, :skills, :summary])
    |> Changeset.validate_number(:min_years_of_experience, greater_than: 0)
  end
end
