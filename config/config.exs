import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  truncate: :infinity

config :pg_siphon, :broadcaster,
  # Add valid module.
  log_channel: PgSiphon
