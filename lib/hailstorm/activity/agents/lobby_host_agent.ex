defmodule Hailstorm.Activity.LobbyHostAgent do
  @moduledoc false
  alias Hailstorm.Activity.ActivityLib
  use GenServer
  use Hailstorm.TachyonHelper

  @valid_data %{
    "name" => "Example lobby name",
    "type" => "normal",
    "nattype" => "none",
    "port" => 1234,
    "game_hash" => "spring",
    "map_hash" => "1912665715",
    "engine_name" => "recoil",
    "engine_version" => "105.1.1-1821-gaca6f20 BAR105",
    "map_name" => "Tempest_V3",
    "game_name" => "Beyond All Reason test-23688-fba20cd",
    "locked" => false
  }

  @spec start_agent(String.t()) :: {pid(), pid()}
  def start_agent(name) do
    email = name
      |> String.replace(" ", "_")

    ActivityLib.make_new_agent(name, email)
  end

  def handle_info(:begin, state) do
    send(self(), :tick)
    {:noreply, state}
  end

  def handle_info(:tick, %{state: :connected} = state) do
    cmd = %{
      "command" => "lobbyHost/create/request",
      "data" => Map.merge(@valid_data, %{
        "name" => "HS #{state.name}"
      })
    }
    tachyon_send(state.agent, cmd)

    {:noreply, state}
  end

  def handle_info(:tick, state) do
    {ws, ls} = state.agent
    IO.puts ""
    IO.inspect {Process.alive?(ws), Process.alive?(ls)}
    IO.puts ""

    {:noreply, state}
  end

  def handle_info(%{"command" => "lobbyHost/create/response"} = msg, state) do
    new_state = cond do
      msg["status"] == "success" and msg["data"]["id"] > 0 ->
        %{state |
          lobby_id: msg["data"]["id"],
          state: :hosting
        }
      true ->
        IO.puts ""
        IO.inspect msg
        IO.puts ""
        raise "Error creating lobby: #{inspect msg}"

        %{state |
          state: :connected
        }
    end
    {:noreply, new_state}
  end

  def handle_info(%{"command" => _} = msg, state) do
    IO.puts ""
    IO.inspect msg
    IO.puts ""
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
    :timer.send_interval(3_000, :tick)

    Registry.register(
      Hailstorm.AgentRegistry,
      "LobbyHostAgent-#{name}",
      "LobbyHostAgent-#{name}"
    )

    {:ok,
     %{
       id: "LobbyHostAgent-#{name}",
       name: name,
       userid: userid,
       lobby_id: nil,
       agent: agent,
       state: :connected
     }}
  end
end
