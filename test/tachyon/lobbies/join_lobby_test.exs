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

    {:ok, client} = new_connection()
    client_id = whoami(client)["id"]

    cmd = %{
      "command" => "lobby/join/request",
      "data" => %{
        "lobby_id" => lobby["id"]
      }
    }
    client_messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobby/join/response"} -> true
      _ -> false
    end)

    assert Enum.count(client_messages) == 1
    response = hd(client_messages)
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
        "userid" => client_id,
        "lobby_id" => lobby["id"],
      },
      "status" => "success"
    }
    validate!(response)

    # Accept the user
    cmd = %{
      "command" => "lobbyHost/respondToJoinRequest/request",
      "data" => %{
        "userid" => client_id,
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
    client_messages = tachyon_receive(client, fn
      %{"command" => "lobby/receivedJoinRequestResponse/response"} -> true
      _ -> true
    end)

    assert Enum.count(client_messages) == 1
    response = hd(client_messages)
    assert response == %{
      "command" => "lobby/receivedJoinRequestResponse/response",
      "data" => %{
        "lobby_id" => lobby["id"],
        "result" => "accept"
      },
      "status" => "success"
    }
  end

  test "user join - decline" do

  end
end
