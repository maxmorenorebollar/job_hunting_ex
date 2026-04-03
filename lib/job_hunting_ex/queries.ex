defmodule JobHuntingEx.Queries do
  @moduledoc """
  Queries Context
  """
  import Ecto.Query
  import Pgvector.Ecto.Query

  alias JobHuntingEx.Repo
  alias JobHuntingEx.Queries.{QueryResult, UserQuery}

  @pretty_id_size 8

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

  def delete_query_results_for_query(query_id) do
    from(q in QueryResult, where: q.query_id == ^query_id)
    |> Repo.delete_all()
  end

  def replace_query_results(query_id, query_results) do
    Repo.transact(fn ->
      _ = delete_query_results_for_query(query_id)

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

  def get_user_query_from_user_id(id, user_id) do
    query =
      from q in UserQuery,
        where: q.id == ^id and q.user_id == ^user_id

    Repo.one(query)
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

  def create_user_query(%{"user_id" => _user_id} = params) do
    %JobHuntingEx.Queries.UserQuery{}
    |> JobHuntingEx.Queries.UserQuery.user_query_changeset(params)
    |> Repo.insert()
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

  def save_user_query(params, user_id, resume_text) do
    params =
      params
      |> Map.put("pretty_query_id", Nanoid.generate(@pretty_id_size))
      |> Map.put("user_id", user_id)
      |> Map.put("resume_text", resume_text)

    changeset =
      %UserQuery{}
      |> UserQuery.changeset(params)

    case Repo.insert(changeset,
           on_conflict: {:replace, [:resume_text, :updated_at]},
           conflict_target: [
             :user_id,
             :keyword,
             :location,
             :radius,
             :minimum_years_of_experience,
             :maximum_years_of_experience,
             :remote?
           ],
           returning: true
         ) do
      {:ok, %UserQuery{id: id}} -> {:ok, id}
      {:error, _changeset} -> {:error, "insertion failed"}
    end
  end
end
