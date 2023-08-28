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
    # {ws, ls} = state.agent
    # IO.puts ""
    # IO.inspect {Process.alive?(ws), Process.alive?(ls)}
    # IO.puts ""
    ping(state.agent, state.tick_num)

    {:noreply, %{state | tick_num: state.tick_num + 1}}
  end

  def handle_info(%{"command" => "system/ping/" <> _}, state), do: {:noreply, state}
  def handle_info(%{"command" => "account/whoAmI/" <> _}, state), do: {:noreply, state}

  def handle_info(%{"command" => "user/UpdatedUserClient/" <> _}, state), do: {:noreply, state}

  def handle_info(%{"command" => "lobbyChat/said/" <> _}, state), do: {:noreply, state}
  def handle_info(%{"command" => "lobby/addUserClient/" <> _}, state), do: {:noreply, state}

  def handle_info(%{"command" => "lobbyHost/respondToJoinRequest/" <> _}, state), do: {:noreply, state}

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

  def handle_info(%{"command" => "lobbyHost/joinRequest/response", "data" => data}, state) do
    cmd = %{
      "command" => "lobbyHost/respondToJoinRequest/request",
      "data" => %{
        "userid" => data["userid"],
        "response" => "accept"
      }
    }
    tachyon_send(state.agent, cmd)

    {:noreply, state}
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
       state: :connected,
       tick_num: 1
     }}
  end
end
