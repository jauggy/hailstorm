defmodule Beans.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Beans.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: Beans.DynamicSupervisor},

      {Beans.Collector.CollectorServer, []},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Beans.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
