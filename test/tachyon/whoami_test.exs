defmodule Hailstorm.Tests.WhoamiTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  @whoami_user_params %{
    name: "whoami"
  }

  test "test" do
    {:ok, ws, ls} = new_connection(@whoami_user_params)

    tachyon_send(ws, %{
      "command" => "account/who_am_i/request",
      "data" => %{}
    })

    messages = pop_messages(ls, 500)
      |> Enum.filter(fn
        %{"command" => "account/who_am_i/response"} -> true
        _ -> false
      end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["name"] == "whoami_hailstorm"
    validate!(response)
  end
end
