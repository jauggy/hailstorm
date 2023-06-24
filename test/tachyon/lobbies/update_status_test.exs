defmodule Tachyon.Lobbies.UpdateStatusTest do
  @moduledoc """
  Tests consul commands
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "update status" do
    {:ok, host} = new_connection()
    lobby = create_lobby(host)

    {:ok, client} = new_connection()
    join_lobby(client, host, lobby["id"])
  end
end
