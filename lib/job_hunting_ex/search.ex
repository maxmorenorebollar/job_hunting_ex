defmodule JobHuntingEx.Search do
  import Ecto.Query, only: [from: 2]

  def search_text(text) do
  end

  def search_embeddings(embedding) do
  end

  def get_resume(embedding) do
    query =
      from l in "listings",
        where: l.url == "resume",
        select: l.id and l.description

    Jobs.Repo.all(query)
  end
end
