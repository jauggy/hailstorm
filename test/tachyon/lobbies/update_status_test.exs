defmodule Tachyon.Lobbies.UpdateStatusTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "update status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client1} = new_connection()
    _lobby_resp = join_lobby(client1, host, lobby["id"])
    client1_id = whoami(client1)["id"]

    {:ok, client2} = new_connection()
    _lobby_resp = join_lobby(client2, host, lobby["id"])
    client2_id = whoami(client2)["id"]

    empty_messages([host, client1, client2])

    {:ok, lobby_state} = WebHelper.get_server_state("lobby", lobby["id"])
    assert Enum.sort(lobby_state["members"]) == [client1_id, client2_id]

    # Lets ensure the client is as we expect, in the lobby but not a player
    client1_state = whoami(client1)
    assert client1_state["status"]["lobby_id"] == lobby["id"]
    assert client1_state["status"]["is_player"] == false

    # Now we update our status
    cmd = %{
      "command" => "lobby/updateStatus/request",
      "data" => %{
        "is_player" => true
      }
    }
    client1_messages = tachyon_send_and_receive(client1, cmd, fn
      %{"command" => "lobby/updateStatus/response"} -> true
      _ -> false
    end)

    assert Enum.count(client1_messages) == 1
    response = hd(client1_messages)
    assert response == %{
      "command" => "lobby/updateStatus/response",
      "data" => %{

      },
      "status" => "success"
    }
    validate!(response)
  end
end
