import Config

config :job_hunting_ex, Jobs.Repo, database: "job_hunting_ex_repo.db"

config :job_hunting_ex, ecto_repos: [Jobs.Repo]
