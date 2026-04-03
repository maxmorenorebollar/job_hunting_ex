defmodule JobHuntingEx.Workers.ScheduledWorker do
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  alias JobHuntingEx.Queries.Data

  @one_day 60 * 60 * 24

  def perform(%{
        args: %{"user_query_id" => user_query_id, "user_id" => user_id} = args,
        attempt: 1
      }) do
    args
    |> new(schedule_in: @one_day)
    |> Oban.insert!()

    case Data.process_for_user_query(user_query_id, user_id) do
      {:ok, _pretty_query_id} -> :ok
      {:error, :not_found} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%{
        args: %{"user_query_id" => user_query_id, "user_id" => user_id}
      }) do
    case Data.process_for_user_query(user_query_id, user_id) do
      {:ok, _pretty_query_id} -> :ok
      {:error, :not_found} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
