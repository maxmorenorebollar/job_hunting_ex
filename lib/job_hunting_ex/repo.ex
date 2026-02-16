defmodule JobHuntingEx.Repo do
  use Ecto.Repo,
    otp_app: :job_hunting_ex,
    adapter: Ecto.Adapters.Postgres
end
