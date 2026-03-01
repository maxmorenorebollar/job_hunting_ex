defmodule JobHuntingEx.Resumes.Resumes do
  alias JobHuntingEx.Resumes.Resume

  def create(params) do
    %Resume{}
    |> Resume.changeset(params)
    |> JobHuntingEx.Repo.insert()
  end
end
