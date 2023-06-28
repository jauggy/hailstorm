defmodule Tachyon.Lobbies.JoinLobbyTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "join lobby happy path" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)
    # host_id = whoami(host) |> Map.get(:id)

    {:ok, client1} = new_connection()
    client1_id = whoami(client1)["id"]

    cmd = %{
      "command" => "lobby/join/request",
      "data" => %{
        "lobby_id" => lobby["id"]
      }
    }
    client1_messages = tachyon_send_and_receive(client1, cmd, fn
      %{"command" => "lobby/join/response"} -> true
      _ -> false
    end)

    assert Enum.count(client1_messages) == 1
    response = hd(client1_messages)
    assert response == %{
      "command" => "lobby/join/response",
      "data" => %{
        "result" => "waiting_on_host"
      },
      "status" => "success"
    }
    validate!(response)

    # Ensure we've had the request to join come through
    host_messages = tachyon_receive(host, fn
      %{"command" => "lobbyHost/joinRequest/response"} -> true
      _ -> false
    end)

    assert Enum.count(host_messages) == 1
    response = hd(host_messages)
    assert response == %{
      "command" => "lobbyHost/joinRequest/response",
      "data" => %{
        "userid" => client1_id,
        "lobby_id" => lobby["id"],
      },
      "status" => "success"
    }
    validate!(response)

    # Accept the user
    cmd = %{
      "command" => "lobbyHost/respondToJoinRequest/request",
      "data" => %{
        "userid" => client1_id,
        "response" => "accept"
      }
    }
    host_messages = tachyon_send_and_receive(host, cmd, fn
      %{"command" => "lobbyHost/respondToJoinRequest/response"} -> true
      _ -> false
    end)

    assert Enum.count(host_messages) == 1
    response = hd(host_messages)
    assert response == %{
      "command" => "lobbyHost/respondToJoinRequest/response",
      "data" => %{},
      "status" => "success"
    }
    # fixme: Enable validation
    # validate!(response)

    # The user should hear they've been added to the lobby
    client1_messages = tachyon_receive(client1, fn
      %{"command" => "lobby/joined/response"} -> true
      %{"command" => "user/UpdatedUserClient/response"} -> true
      %{"command" => "lobby/receivedJoinRequestResponse/response"} -> true
      _ -> false
    end)

    message_map = client1_messages
      |> Map.new(fn %{"command" => command} = m ->
        {command, m}
      end)

    assert Enum.count(client1_messages) == 3
    response = message_map["lobby/receivedJoinRequestResponse/response"]
    assert response == %{
      "command" => "lobby/receivedJoinRequestResponse/response",
      "data" => %{
        "lobby_id" => lobby["id"],
        "result" => "accept"
      },
      "status" => "success"
    }

    response = message_map["lobby/joined/response"]
    assert response["data"]["lobby_id"] == lobby["id"]

    response = message_map["user/UpdatedUserClient/response"]
    assert response["data"]["userClient"]["id"] == client1_id

    # What if a 2nd person joins?
    empty_messages([client1])
    {:ok, client2} = new_connection()
    client2_id = whoami(client2)["id"]
    _lobby_resp = join_lobby(client2, host, lobby["id"])

    client1_messages = tachyon_receive(client1, fn
      %{"command" => "lobby/addUserClient/response"} -> true
      _ -> false
    end)

    assert Enum.count(client1_messages) == 1
    response = hd(client1_messages)
    assert response["data"]["lobby_id"] == lobby["id"]
    assert response["data"]["UserClient"]["id"] == client2_id
    assert get_in(response, ["data", "UserClient", "status", "lobby_id"]) == lobby["id"]
  end

  test "user join - decline" do

  end
end
