defmodule Hailstorm.MixProject do
  use Mix.Project

  def project do
    [
      app: :hailstorm,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      preferred_cli_env: [balance_test: :test]
    ]
  end

  # Define here tests that only target specific files
  # Can run like: mix balance_test
  # To add more you might also have to update preferred_cli_env in project above
  defp aliases do
    [
      balance_test: "test test/spring/balance/balance_test.exs"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Hailstorm.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ranch, "~> 1.8"},
      {:timex, "~> 3.7.5"},
      {:con_cache, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:elixir_uuid, "~> 1.2"},
      {:jason, "~> 1.2"},
      {:parallel, "~> 0.0"},
      {:logger_file_backend, "~> 0.0.10"},
      {:httpoison, "~> 1.8"},

      {:websockex, "~> 0.4.3"},
      {:json_xema, "~> 0.3"},
      {:ex_ulid, "~> 0.1.0"},

      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
