defmodule Hailstorm.Activity.InOutAgent do
  @moduledoc false
  alias Hailstorm.Activity.ActivityLib
  use GenServer
  use Hailstorm.TachyonHelper

  @spec start_agent(String.t()) :: {pid(), pid()}
  def start_agent(name) do
    email = name
      |> String.replace(" ", "_")

    ActivityLib.make_new_agent(name, email)
  end

  def handle_info(:begin, state) do
    :timer.send_interval(5_000, :tick)
    {:noreply, state}
  end

  def handle_info(:tick, %{state: :connected} = state) do
    tachyon_send(state.agent, %{
      "cmd" => "disconnect"
    })

    {:noreply, %{state | state: :disconnected}}
  end

  def handle_info(:tick, %{state: :disconnected} = state) do
    {agent, _} = start_agent(state.name)
    {:noreply, %{state | agent: agent, state: :connected}}
  end

  def handle_info(%{"command" => _}, state) do
    {:noreply, state}
  end

  @spec start_link(List.t()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data], [])
  end

  @spec init(Map.t()) :: {:ok, Map.t()}
  def init(opts) do
    name = opts[:name]
    {agent, userid} = start_agent(name)

    send(self(), :begin)

    Registry.register(
      Hailstorm.AgentRegistry,
      "InOutAgent-#{name}",
      "InOutAgent-#{name}"
    )

    {:ok,
     %{
       id: "InOutAgent-#{name}",
       name: name,
       agent: agent,
       userid: userid,
       state: :connected
     }}
  end
end
