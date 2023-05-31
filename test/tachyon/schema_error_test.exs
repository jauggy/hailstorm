defmodule Hailstorm.Tachyon.SchemaErrorTest do
  @moduledoc """
  Tests various ways of mis-using a good connection and ensures
  we fail correctly
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "test bad commands" do
    {:ok, client} = new_connection(%{name: "error"})

    # Command in wrong key
    cmd = %{
      "cmd" => "no command present",
      "data" => %{}
    }
    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "system/error/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    resp = hd(messages)

    assert resp == %{
      "command" => "system/error/response",
      "reason" => "No command supplied",
      "status" => "failure"
    }


    # Now a dodgy command in general
    cmd = %{
      "command" => "bad command name",
      "data" => %{}
    }
    assert_raise(RuntimeError, fn ->
      tachyon_send_and_receive(client, cmd)
    end)

    # Force an error
    exit_message = tachyon_send_and_receive(client, %{
      "command" => "force_error",
      "data" => %{}
    })
    |> Enum.reverse()
    |> hd

    assert exit_message == {:ws_terminate, {:remote, 1011, ""}}
    refute Process.alive?(elem(client, 0))

    # TODO: Fix validation of messages on server, until then this won't work
    # # Make a new connection
    # # This should fail because we're sending back an bad response, it will kill the socket
    # {:ok, client} = new_connection(%{name: "error"})

    # exit_message = tachyon_send_and_receive(client, %{
    #   "command" => "force_error",
    #   "data" => %{"command" => "account/whoAmI/response"}
    # })
    # |> Enum.reverse()
    # |> hd

    # assert exit_message == {:ws_terminate, {:remote, 1011, ""}}
    # refute Process.alive?(elem(client, 0))
  end

  test "test disconnect command" do
    {:ok, client} = new_connection(%{name: "error"})

    # Force an error
    cmd = %{
      "command" => "disconnect"
    }

    messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "disconnect"} -> true
      _ -> false
    end)

    # We don't always get a response when disconnecting, we need to handle both
    if Enum.count(messages) == 1 do
      resp = hd(messages)
      assert resp == %{"command" => "disconnect", "data" => %{"result" => "disconnected"}, "status" => "success"}
    else
      assert Enum.empty?(messages)
    end

    refute Process.alive?(elem(client, 0))
  end

  test "test validate! function" do
    good_data = %{
      "command" => "account/whoAmI/response",
      "status" => "success",
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
      "command" => "account/whoAmI/response",
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
