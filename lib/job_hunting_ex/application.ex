defmodule JobHuntingEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("Server runnging at http://localhost:4001")

    children = [
      # Starts a worker by calling: JobHuntingEx.Worker.start_link(arg)
      # {JobHuntingEx.Worker, arg}
      Plug.Cowboy.child_spec(scheme: :http, plug: JobHuntingEx.Router, options: [port: 4001]),
      {JobHuntingEx.McpClient, transport: {:streamable_http, base_url: "https://mcp.dice.com/"}},
      Jobs.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: JobHuntingEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
