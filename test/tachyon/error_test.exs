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
end
