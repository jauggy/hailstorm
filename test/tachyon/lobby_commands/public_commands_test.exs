defmodule Tachyon.LobbyCommands.PublicCommandsTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  # status s y n follow joinq leaveq splitlobby afks roll players password? explain newlobby jazlobby tournament

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client1} = new_connection()
    _lobby_resp = join_lobby(client1, host, lobby["id"])
    # client1_id = whoami(client1)["id"]

    {:ok, client2} = new_connection()
    _lobby_resp = join_lobby(client2, host, lobby["id"])
    # client2_id = whoami(client2)["id"]

    empty_messages([host, client1, client2])

    cmd = %{
      "command" => "lobbyChat/say/request",
      "data" => %{
        "message" => "$status"
      }
    }
    client1_messages = tachyon_send_and_receive(client1, cmd, fn
      %{"command" => "communication/receivedDirectMessage/response"} -> true
      _ -> false
    end)

    assert Enum.count(client1_messages) == 1
    response = hd(client1_messages)
    assert response == %{
      "command" => "communication/receivedDirectMessage/response",
      "data" => %{
        "content" => "--------------------------- Lobby status ---------------------------\nStatus for battle ##{lobby["id"]}\nLocks: \nGatekeeper: default\nJoin queue:  (size: 0)\nCurrently 0 players\nTeam size and count are: 8 and 2\nBalance algorithm is: loser_picks\nNobody is bossed\nMaximum allowed number of players is 16 (Host = 16, Coordinator = 16)",
        "sender_id" => 1
      },
      "status" => "success"
    }
    validate!(response)
  end
end
