defmodule Hailstorm.Account.WhoamiTest do
  @moduledoc """
  Tests the whoami request
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  @whoami_user_params %{
    name: "whoami"
  }

  test "test" do
    {:ok, client} = new_connection(@whoami_user_params)
    cmd_data = %{
      "command" => "account/who_am_i/request",
      "data" => %{}
    }

    messages = tachyon_send_and_receive(client, cmd_data, fn
      %{"command" => "account/who_am_i/response"} -> true
      _ -> false
    end)

    assert Enum.count(messages) == 1
    response = hd(messages)

    assert response["data"]["name"] == "whoami_hailstorm"
    validate!(response)
  end
end
