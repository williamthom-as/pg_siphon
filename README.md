# PgSiphon

PgSiphon is an (experimental) simple proxy utility that sits between your application and your Postgres server to provide activity metrics on all queries executed. 

This is useful for debugging, performance tuning, or auditing purposes, and should only be used in development modes.

As it also has the ability to record all activity and export to a CSV.

**This project is just the proxy server, for easier install and use, the web app management project is now available [here](http://www.github.com/williamthom-as/pg_siphon_management).**

## Performance

The proxy server can handle a high number of requests per second. The current bottleneck is the web logging infrastructure, particularly the web sockets to the management UI. The proxy server will remain operational even if the UI slows/shuts down.

In headless mode, file logging can handle hundreds of queries per second efficiently.

## Usage

You will need to configure your application to use the proxy server.

By default, the proxy server will listen on `localhost:1337` and forward all data to `localhost:5432`.

Note: You **must** edit `postgresql.conf` to disable SSL (`ssl=off`) as it is not supported currently.

You may also want to edit `pg_hba.conf` to set the authentication method to `trust`.

To start the proxy server, run:

```bash
mix compile

# This will run interactively, allowing you to change recording modes on the fly, perform file exports, etc.
iex -S mix

# If you don't want to run interactively
mix run --no-halt
```

## Configuration

To configure the proxy server, you can edit the `config/config.exs` file.

```elixir
config :pg_siphon, :proxy_server,
  from_port: 1337,
  to_host: ~c"localhost",
  to_port: 5432
```

## Why? Can't I just use Postgres logs?

Sometimes, with modern ORMs and query builders, it can be difficult to see the actual queries that are being executed against your database. This can make it difficult to debug, tune, or audit your application's database activity.

Yes, you can just use Postgres logs. However, sometimes they do not tell the full story, and by sitting between the two servers, we can get a very accurate indiction of what is going on (including host/client behaviour).

## Management

This project contains the code for the proxy server and recording infrastructure. There is a seperate project (`PgSiphonManagement`) that provides a web interface for managing the proxy server, including file export and visualisations.

You can find that project [here](http://www.github.com/williamthom-as/pg_siphon_management).

### Incorporating library

If you wish to act on a message frame there is a Phoenix PubSub channel named :broadcaster (topic 'message_frames') which you can subscribe to.

Currently, there is only one queue named :new_message_frame. More will come in the future.

Further info can be found in the module `PgSiphon.Broadcaster`.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pg_siphon>.

