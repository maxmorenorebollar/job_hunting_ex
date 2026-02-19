Postgrex.Types.define(
  JobHuntingEx.PostgrexTypes,
  Pgvector.extensions() ++ Ecto.Adapters.Postgres.extensions(),
  []
)
