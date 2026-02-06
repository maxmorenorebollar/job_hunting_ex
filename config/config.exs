import Config

config :job_hunting_ex, ecto_repos: [Jobs.Repo]

config :job_hunting_ex, Jobs.Repo,
  database: "jobs",
  username: "maxmoreno",
  password: "",
  hostname: "localhost",
  types: JobHuntingEx.PostgrexTypes
