defmodule Hailstorm.Lobbies.CreateLobbyTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  @valid_data %{
    "name" => "Example lobby name",
    "type" => "normal",
    "nattype" => "none",
    "port" => 1234,
    "game_hash" => "hash-here",
    "map_hash" => "hash-here",
    "engine_name" => "",
    "engine_version" => "",
    "map_name" => "Best map ever",
    "game_name" => "bar-123",
    "locked" => false
  }

  @create_lobby_user_params %{
    name: "create_lobby"
  }

  test "create lobby tests" do
    {:ok, client} = new_connection(@create_lobby_user_params)
    userid = whoami(client) |> Map.get("id")

    # No name
    cmd = %{
      "command" => "lobbyHost/create/request",
      "data" => Map.put(@valid_data, "name", "")
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobbyHost/create/request"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response == %{
      "command" => "lobbyHost/create/request",
      "reason" => "No lobby name supplied",
      "status" => "failure"
    }


    # Generate error - Bad type
    cmd = %{
      "command" => "lobbyHost/create/request",
      "data" => Map.put(@valid_data, "type", "bad-type")
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobbyHost/create/request"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response == %{
      "command" => "lobbyHost/create/request",
      "reason" => "Invalid type 'bad-type'",
      "status" => "failure"
    }

    # Generate error - Bad nattype
    cmd = %{
      "command" => "lobbyHost/create/request",
      "data" => Map.put(@valid_data, "nattype", "bad-type")
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobbyHost/create/request"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response == %{
      "command" => "lobbyHost/create/request",
      "reason" => "Invalid nattype 'bad-type'",
      "status" => "failure"
    }

    # Now do it properly
    cmd = %{
      "command" => "lobbyHost/create/request",
      "data" => @valid_data
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobbyHost/create/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["founder_name"] == "create_lobby_hailstorm"
    assert response["data"]["founder_id"] == userid
    validate!(response)

    # Ensure the lobby is there if we list lobbies
    cmd = %{
      "command" => "lobby/list_lobbies/request",
      "data" => %{}
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobby/list_lobbies/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    lobbies = response["data"]["lobbies"]
    assert Enum.count(lobbies) == 1

    lobby = hd(lobbies)
    assert lobby["founder_id"] == userid
  end
end
