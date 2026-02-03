defmodule JobHuntingEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :job_hunting_ex,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {JobHuntingEx.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:plug_cowboy, "~> 2.0"},
      {:anubis_mcp, "~> 0.17.0"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0"},
{:floki, "~> 0.38.0"},
{:ecto_sql, "~> 3.0"},
{:postgrex, ">= 0.0.0"}
    ]
  end
end
