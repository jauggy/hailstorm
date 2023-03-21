defmodule Hailstorm.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      concache_perm_sup(:tachyon_schemas),

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

  def load_schemas() do
    "priv/tachyon_schema.json"
      |> File.read!
      |> Jason.decode!
      |> Enum.each(fn json_def ->
        schema = ExJsonSchema.Schema.resolve(json_def)
        ConCache.put(:tachyon_schemas, json_def["$id"], schema)
      end)
  end
end
