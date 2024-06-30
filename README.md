# PgSiphon

🚧 Under development, not fully functional yet 🚧

PgSiphon is a simple proxy utility that sits between your application and your Postgres server to provide activity metrics on all queries executed. 

This is useful for debugging, performance tuning, or auditing purposes, and should only be used in development modes.

## Why?

Sometimes, with modern ORMs and query builders, it can be difficult to see the actual queries that are being executed against your database. This can make it difficult to debug, tune, or audit your application's database activity.

By sitting between the two servers, we can get a very accurate indiction of what is going on.

## Usage

You will need to configure your application to use the proxy server.

Unless otherwise changed, the proxy server will listen on `localhost:5000` and forward all queries to `localhost:5432`.

To start the proxy server, run:

```bash
mix run -e 'PgSiphon.start_proxy()'
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `pg_siphon` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:pg_siphon, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pg_siphon>.

