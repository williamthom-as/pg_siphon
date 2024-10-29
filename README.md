# PgSiphon

🚧 Under development, not fully functional yet 🚧

PgSiphon is an (experimental) simple proxy utility that sits between your application and your Postgres server to provide activity metrics on all queries executed. 

This is useful for debugging, performance tuning, or auditing purposes, and should only be used in development modes.

## Why?

Sometimes, with modern ORMs and query builders, it can be difficult to see the actual queries that are being executed against your database. This can make it difficult to debug, tune, or audit your application's database activity.

By sitting between the two servers, we can get a very accurate indiction of what is going on.

## Usage

You will need to configure your application to use the proxy server.

Unless otherwise changed, the proxy server will listen on `localhost:1337` and forward all queries to `localhost:5432`.

To start the proxy server, run:

```bash
mix run -e 'PgSiphon.ServicesSupervisor.start_link()'
```

### Incorporating library

If you wish to act on a message frame there is a Phoenix PubSub channel named :broadcaster (topic 'message_frames') which you can subscribe to.

Currently, there is only one queue named :new_message_frame. More will come in the future.

Further info can be found in the module `PgSiphon.Broadcaster`.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pg_siphon>.

