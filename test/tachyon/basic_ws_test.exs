defmodule Beans.Tests.PingTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Beans.TachyonHelper

  @ping_user_params %{
    email: "ping",
    name: "ping"
  }

  test "test" do
    {:ok, ws, ls} = new_connection(@ping_user_params)

    tachyon_send(ws, Tachyon.TokenRequest.new(
      email: "email",
      password: "password"
    ))

    messages = pop_messages(ls, 500)

    assert Enum.member?(messages, %Tachyon.TokenResponse{token: "token"})
  end
end
