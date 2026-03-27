defmodule JobHuntingEx.Queries do
  @moduledoc """
  Queries Context
  """
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias JobHuntingEx.Repo

  def get_listing_ids(query_id) do
    query =
      from q in JobHuntingEx.Queries.QueryResult,
        where: q.query_id == ^query_id,
        order_by: q.sequence

    Repo.all(query)
  end

  def get_listings(query_id) do
    query =
      from l in JobHuntingEx.Jobs.Listing,
        join: q in JobHuntingEx.Queries.QueryResult,
        on: q.listing_id == l.id,
        where: q.query_id == ^query_id,
        order_by: q.sequence

    Repo.all(query)
  end

  defp create_query_result(params) do
    %JobHuntingEx.Queries.QueryResult{}
    |> JobHuntingEx.Queries.QueryResult.changeset(params)
    |> Repo.insert()
  end

  def create_query_results(query_results) do
    Repo.transact(fn ->
      results =
        Enum.reduce(query_results, [], fn params, acc ->
          case create_query_result(params) do
            {:ok, result} -> [result | acc]
            {:error, _reason} -> Repo.rollback(:transaction_failed)
          end
        end)

      {:ok, results}
    end)
  end

  def get_listings_from(days_ago) do
    cut_off_time = DateTime.shift(DateTime.utc_now(), day: days_ago)

    query =
      from l in JobHuntingEx.Jobs.Listing,
        where: l.inserted_at >= ^cut_off_time,
        select: [l.url, l.title, l.company_name]

    Repo.all(query)
  end

  def cosine_search(resume, listing_urls, min_yoe, max_yoe) do
    query =
      from i in JobHuntingEx.Jobs.Listing,
        where:
          i.url in ^listing_urls and i.years_of_experience >= ^min_yoe and
            i.years_of_experience <= ^max_yoe,
        order_by: cosine_distance(i.embeddings, ^resume.embeddings)

    Repo.all(query)
  end

  def create_user_query(params) do
    %JobHuntingEx.Queries.UserQuery{}
    |> JobHuntingEx.Queries.UserQuery.changeset(params)
    |> Repo.insert()
  end

  def get_query_from_pretty_query_id(pretty_query_id) do
    query =
      from i in JobHuntingEx.Queries.UserQuery,
        where: i.pretty_query_id == ^pretty_query_id

    Repo.one(query)
  end
end
