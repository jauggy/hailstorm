defmodule Hailstorm.Tests.PingTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  @ping_user_params %{
    name: "ping"
  }

  test "test" do
    {:ok, ws, ls} = new_connection(@ping_user_params)

    tachyon_send(ws, Tachyon.MyselfRequest.new())

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %Tachyon.MyselfResponse{} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    resp = hd(messages)

    assert resp.user.name == "ping_hailstorm"
  end
end
