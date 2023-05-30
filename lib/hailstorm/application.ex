defmodule Hailstorm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: Hailstorm.PubSub},

      concache_perm_sup(:tachyon_schemas),

      {DynamicSupervisor, strategy: :one_for_one, name: Hailstorm.MonitorSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: Hailstorm.SpringSupervisor},
      {DynamicSupervisor, strategy: :one_for_one, name: Hailstorm.TachyonSupervisor},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hailstorm.Supervisor]
    start_result = Supervisor.start_link(children, opts)

    load_schemas()

    start_result
  end

  defp concache_perm_sup(name) do
    Supervisor.child_spec(
      {
        ConCache,
        [
          name: name,
          ttl_check_interval: false
        ]
      },
      id: {ConCache, name}
    )
  end

  @spec load_schemas :: list
  def load_schemas() do
    "priv/schema_v1/*/*/*.json"
      |> Path.wildcard
      |> Enum.map(fn file_path ->
        contents = file_path
          |> File.read!()
          |> Jason.decode!()

        command = file_path
          |> Path.split()
          |> Enum.reverse
          |> Enum.take(3)
          |> Enum.reverse
          |> Enum.join("/")
          |> String.replace(".json", "")

        schema = JsonXema.new(contents)

        ConCache.put(:tachyon_schemas, command, schema)
        command
      end)
  end
end
