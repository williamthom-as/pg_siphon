import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  truncate: :infinity

config :pg_siphon, :broadcaster,
  # Add valid module.
  log_channel: PgSiphon

config :pg_siphon, :proxy_server,
  from_port: 1337,
  to_host: ~c"localhost",
  to_port: 5432

config :pg_siphon, :export, export_dir: System.user_home() |> Path.join(".pg_siphon_management")

import_config "#{config_env()}.exs"
