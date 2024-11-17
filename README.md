# PgSiphon

🚧 Under development, not fully functional yet (see current features) 🚧

PgSiphon is an (experimental) simple proxy utility that sits between your application and your Postgres server to provide activity metrics on all queries executed. 

This is useful for debugging, performance tuning, or auditing purposes, and should only be used in development modes.

As it also has the ability to record all activity, it can be used to generate datasets for database intrusion detection machine learning algorithms.

Simply configure your application to the proxy, perform and record normal usage, and repeat the same whilst performing a series of attacks. Records are able to be exported in CSV, and you can label each dataset as either 'normal' or 'attack' (0 or 1), and include the type of attack.

## Why? Can't I just use Postgres logs?

Sometimes, with modern ORMs and query builders, it can be difficult to see the actual queries that are being executed against your database. This can make it difficult to debug, tune, or audit your application's database activity.

Yes, you can just use Postgres logs. However, sometimes they do not tell the full story, and by sitting between the two servers, we can get a very accurate indiction of what is going on (including host/client behaviour).

### Current features:

1. Proxy server - complete
2. Recording infrastructure - complete
3. File export - complete
4. Management interface - in progress
5. Performance tuning - in progress
6. Dockerfile - to be completed.


## Performance

The proxy server can handle an extremely high number of requests per second. The bottleneck is currently the web logging infrastructure, specifically the web sockets to the management UI. This is being worked on, and is a problem with web sockets themselves, not the proxy server. Logging hundreds of queries per second over pub sub to a DOM is not a good idea, but its a fun problem to solve. If you are sending less than a hundred frames per second, you should be relatively fine.  Note that it will likely not crash, but it will slow down, and if this happens, the proxy server **will remain fully operational**.

In headless mode, logging to a file can handle hundreds of queries per second.

## Usage

You will need to configure your application to use the proxy server.

Unless otherwise changed, the proxy server will listen on `localhost:1337` and forward all queries to `localhost:5432`.

Note: You **must** edit postgresql.conf to disable SSL (ssl=off) for now as it is not supported.

You probably also want to edit pg_hba.conf to trust.

To start the proxy server, run:

```bash
mix compile

# this will run interactively, so you can change recording modes on the fly, perform file export etc.
iex -S mix 

# if you don't want to run interactively
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

## Management

This project contains the code for the proxy server and recording infrastructure. There is a seperate project (`PgSiphonManagement`) that provides a web interface for managing the proxy server, including file export and visualisations.

You can find that project [here](http://wwww.github.com/williamthom-as/pg_siphon_management).

### Incorporating library

If you wish to act on a message frame there is a Phoenix PubSub channel named :broadcaster (topic 'message_frames') which you can subscribe to.

Currently, there is only one queue named :new_message_frame. More will come in the future.

Further info can be found in the module `PgSiphon.Broadcaster`.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/pg_siphon>.

