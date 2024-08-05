# Quick and dirty script to run to execute queries against proxy.

Mix.install([:postgrex])

{:ok, pid} = Postgrex.start_link(
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "test_db",
  port: 1337
)

{:ok, result} = Postgrex.query(pid, "SELECT * FROM names;", [])

Enum.each(result.rows, fn [table_name] ->
  IO.puts(table_name)
end)

# Insert name into names table
{:ok, _} = Postgrex.query(pid, "INSERT INTO names (first_name) VALUES ($1);", ["Johnny"])
