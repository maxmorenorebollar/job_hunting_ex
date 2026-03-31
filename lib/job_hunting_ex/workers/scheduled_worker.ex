defmodule JobHuntingEx.Workers.ScheduledWorker do
  use Oban.Worker, queue: :scheduled, max_attempts: 3

  @one_day 60 * 60 * 24

  def perform(%{
        args:
          %{
            "query_params" => query_params,
            "resume_text" => resume_text,
            "user_id" => user_id
          } = args,
        attempt: 1
      }) do
    args
    |> new(schedule_in: @one_day)
    |> Oban.insert!()

    case JobHuntingEx.Data.process(query_params, resume_text, user_id) do
      {:ok, _query_id} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%{
        args: %{
          "query_params" => query_params,
          "resume_text" => resume_text,
          "user_id" => user_id
        }
      }) do
    {:ok, query_id} = JobHuntingEx.Data.process(query_params, resume_text, user_id)
  end
end
