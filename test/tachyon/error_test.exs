defmodule Hailstorm.Tests.ErrorTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "test bad commands" do
    {:ok, ws, ls} = new_connection(%{name: "error"})

    # Command in wrong key
    tachyon_send(ws, %{
      "cmd" => "no command present",
      "data" => %{}
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "error"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    resp = hd(messages)

    assert resp["data"] == %{"reason" => "No command supplied"}

    # Now a dodgy command in general
    tachyon_send(ws, %{
      "command" => "bad command name",
      "data" => %{}
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "error"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    resp = hd(messages)

    assert resp["data"] == %{"reason" => "No command of 'bad command name'"}

    # Force an error
    tachyon_send(ws, %{
      "command" => "force_error",
      "data" => %{}
    })

    exit_message = pop_messages(ls, 500)
      |> Enum.reverse()
      |> hd

    assert exit_message == {:ws_terminate, {:remote, 1011, ""}}
    refute Process.alive?(ws)

    # Make a new connection
    {:ok, ws, ls} = new_connection(%{name: "error"})

    tachyon_send(ws, %{
      "command" => "force_error",
      "data" => %{"command" => "account/who_am_i/response"}
    })

    exit_message = pop_messages(ls, 500)
      |> Enum.reverse()
      |> hd

    assert exit_message == {:ws_terminate, {:remote, 1011, ""}}
    refute Process.alive?(ws)
  end

  test "test disconnect command" do
    {:ok, ws, ls} = new_connection(%{name: "error"})

    # Force an error
    tachyon_send(ws, %{
      "command" => "disconnect"
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "disconnect"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    resp = hd(messages)
    assert resp == %{"command" => "disconnect", "data" => %{"result" => "disconnected"}}

    refute Process.alive?(ws)
  end

  test "test validate! function" do
    good_data = %{
      "command" => "account/who_am_i/response",
      "data" => %{
        "battle_status" => %{
          "away" => false,
          "bonus" => 0,
          "clan_tag" => nil,
          "faction" => "???",
          "in_game" => false,
          "is_player" => false,
          "lobby_id" => nil,
          "muted" => false,
          "party_id" => nil,
          "player_number" => 0,
          "ready" => false,
          "sync" => %{"engine" => 0, "game" => 0, "map" => 0},
          "team_colour" => "0"
        },
        "clan_id" => nil,
        "friend_requests" => [],
        "friends" => [],
        "icons" => %{},
        "id" => 60168,
        "ignores" => [],
        "is_bot" => false,
        "name" => "whoami_hailstorm",
        "permissions" => [],
        "roles" => []
      }
    }

    assert validate!(good_data)

    bad_data = %{
      "command" => "account/who_am_i/response",
      "data" => %{
        "clan_id" => nil,
        "friend_requests" => [],
        "friends" => [],
        "is_bot" => false,
        "name" => "whoami_hailstorm",
        "permissions" => nil,
        "roles" => []
      }
    }
    assert_raise JsonXema.ValidationError, fn -> validate!(bad_data) end
  end
end
