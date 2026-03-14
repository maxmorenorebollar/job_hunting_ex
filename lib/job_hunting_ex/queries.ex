defmodule JobHuntingEx.Queries do
  @moduledoc """
  Queries Context
  """
  import Ecto.Query

  alias JobHuntingEx.Repo

  def get_listing_ids(job_id) do
    query =
      from q in JobHuntingEx.Queries.QueryResult,
        where: q.job_id == ^job_id,
        order_by: q.sequence

    Repo.all(query)
  end

  def get_listings(job_id) do
    query =
      from l in JobHuntingEx.Jobs.Listing,
        join: q in JobHuntingEx.Queries.QueryResult,
        on: q.listing_id == l.id,
        where: q.job_id == ^job_id,
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
end
