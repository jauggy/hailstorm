defmodule Tachyon.LobbyCommands.BalanceCommandsTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  # status s y n follow joinq leaveq splitlobby afks roll players password? explain newlobby jazlobby tournament

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)
    host_id = whoami(host)["id"]

    {:ok, balance_state} = WebHelper.get_server_state("balance", lobby["id"])
    assert balance_state["hashes"] == %{}

    {:ok, client1} = new_connection()
    _lobby_resp = join_lobby(client1, host, lobby["id"])
    # client1_id = whoami(client1)["id"]

    {:ok, client2} = new_connection()
    _lobby_resp = join_lobby(client2, host, lobby["id"])
    # client2_id = whoami(client2)["id"]

    {:ok, client3} = new_connection()
    _lobby_resp = join_lobby(client3, host, lobby["id"])
    # client2_id = whoami(client3)["id"]

    {:ok, client4} = new_connection()
    _lobby_resp = join_lobby(client4, host, lobby["id"])
    # client2_id = whoami(client4)["id"]

    empty_messages([host, client1, client2, client3, client4])

    cmd = %{
      "command" => "lobbyChat/say/request",
      "data" => %{
        "message" => "$makebalance"
      }
    }
    host_messages = tachyon_send_and_receive(host, cmd, fn
      %{"command" => "lobbyChat/said/response"} -> true
      _ -> false
    end)

    assert Enum.count(host_messages) == 1
    response = hd(host_messages)
    assert response == %{
      "command" => "lobbyChat/said/response",
      "data" => %{
        "lobby_id" => lobby["id"],
        "message" => "$makebalance",
        "userid" => host_id
      },
      "status" => "success"
    }
    validate!(response)

    {:ok, balance_state} = WebHelper.get_server_state("balance", lobby["id"])
    current_balance = balance_state["current_balance"]
    assert current_balance["team_players"] == %{"1" => [], "2" => []}
    assert current_balance["team_sizes"] == %{"1" => 0, "2" => 0}
  end
end
