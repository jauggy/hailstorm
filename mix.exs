defmodule Hailstorm.MixProject do
  use Mix.Project

  def project do
    [
      app: :hailstorm,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:protobuf, "~> 0.11.0"},
      {:google_protos, "~> 0.1"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
