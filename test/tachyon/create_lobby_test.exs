defmodule Hailstorm.Tests.CreateLobbyTest do
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
  }

  @create_lobby_user_params %{
    name: "create_lobby"
  }

  test "create lobby tests" do
    {:ok, ws, ls} = new_connection(@create_lobby_user_params)

    # No name
    tachyon_send(ws, %{
      "command" => "lobby_host/create/request",
      "data" => Map.put(@valid_data, "name", "")
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "system/error/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response["data"]["reason"] == "No lobby name supplied"

    # Generate error - Bad type
    tachyon_send(ws, %{
      "command" => "lobby_host/create/request",
      "data" => Map.put(@valid_data, "type", "bad-type")
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "system/error/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response["data"]["reason"] == "Invalid type 'bad-type'"

    # Generate error - Bad nattype
    tachyon_send(ws, %{
      "command" => "lobby_host/create/request",
      "data" => Map.put(@valid_data, "nattype", "bad-type")
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "system/error/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)
    assert response["data"]["reason"] == "Invalid nattype 'bad-type'"

    # Now do it properly
    tachyon_send(ws, %{
      "command" => "lobby_host/create/request",
      "data" => @valid_data
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "lobby_host/create/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["founder_name"] == "create_lobby_hailstorm"
    # validate!(response)

    # Ensure the lobby is there if we list lobbies
    tachyon_send(ws, %{
      "command" => "lobby/list_lobbies/request",
      "data" => %{}
    })
    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "lobby/list_lobbies/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    _lobbies = response["data"]["lobbies"]
  end
end
