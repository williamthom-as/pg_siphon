defmodule PgSiphon.MixProject do
  use Mix.Project

  def project do
    [
      app: :pg_siphon,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {PgSiphon, []},
      extra_applications: [:logger, :postgrex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, ">= 0.18.0"},
      {:phoenix_pubsub, "~> 2.1"},
      {:csv, "~> 3.2"}
    ]
  end
end
