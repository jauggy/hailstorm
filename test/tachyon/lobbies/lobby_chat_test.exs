defmodule Tachyon.Communication.LobbyChatTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client1} = new_connection()
    _lobby_resp = join_lobby(client1, host, lobby["id"])
    client1_id = whoami(client1)["id"]

    {:ok, client2} = new_connection()
    _lobby_resp = join_lobby(client2, host, lobby["id"])
    # client2_id = whoami(client2)["id"]

    empty_messages([host, client1, client2])

    cmd = %{
      "command" => "lobbyChat/say/request",
      "data" => %{
        "message" => "Test message"
      }
    }
    client1_messages = tachyon_send_and_receive(client1, cmd, fn
      %{"command" => "lobbyChat/say/response"} -> true
      %{"command" => "lobbyChat/said/response"} -> true
      _ -> false
    end)

    message_map = client1_messages
      |> Map.new(fn %{"command" => command} = m ->
        {command, m}
      end)

    assert Enum.count(client1_messages) == 2
    response = message_map["lobbyChat/say/response"]
    assert response == %{
      "command" => "lobbyChat/say/response",
      "data" => %{},
      "status" => "success"
    }
    validate!(response)

    response = message_map["lobbyChat/said/response"]
    assert response == %{
      "command" => "lobbyChat/said/response",
      "data" => %{
        "userid" => client1_id,
        "lobby_id" => lobby["id"],
        "message" => "Test message"
      },
      "status" => "success"
    }
    validate!(response)

    # Assert client2 saw it
    client2_messages = tachyon_receive(client2, fn
      %{"command" => "lobbyChat/said/response"} -> true
      _ -> true
    end)

    assert Enum.count(client2_messages) == 1
    response = hd(client2_messages)
    assert response == %{
      "command" => "lobbyChat/said/response",
      "data" => %{
        "userid" => client1_id,
        "lobby_id" => lobby["id"],
        "message" => "Test message"
      },
      "status" => "success"
    }
    validate!(response)

    # Assert the host saw the chat message
    host_messages = tachyon_receive(host, fn
      %{"command" => "lobbyChat/said/response"} -> true
      _ -> true
    end)

    assert Enum.count(host_messages) == 1
    response = hd(host_messages)
    assert response == %{
      "command" => "lobbyChat/said/response",
      "data" => %{
        "userid" => client1_id,
        "lobby_id" => lobby["id"],
        "message" => "Test message"
      },
      "status" => "success"
    }
    validate!(response)
  end
end
