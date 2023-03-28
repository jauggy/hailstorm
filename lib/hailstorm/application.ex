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
    "priv/tachyon_schema.json"
      |> File.read!
      |> Jason.decode!
      |> Map.get("properties")
      |> Enum.map(fn {_section_key, section} ->
        section
        |> Map.get("properties")
        |> Enum.map(fn {_cmd_name, cmd} ->
          [
            cmd["properties"]["request"],
            cmd["properties"]["response"]
          ]
        end)
      end)
      |> List.flatten
      |> Enum.reject(&(&1 == nil))
      |> Enum.map(fn json_def ->
        schema = JsonXema.new(json_def)
        command = get_in(json_def, ~w(properties command const))

        ConCache.put(:tachyon_schemas, command, schema)
        json_def["$id"]
      end)
  end
end
