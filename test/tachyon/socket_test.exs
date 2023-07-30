defmodule Tachyon.SocketTest do
  @moduledoc """
  Tests around the Tachyon socket itself
  """
  use ExUnit.Case, async: true
  use Hailstorm.TachyonHelper

  test "long running connection" do
    # There was a bug where clients would timeout because the ClientServer process would die
    # if this test errors in generating a whoami it might be that.
    {:ok, conn} = new_connection()
    whoami(conn)

    :timer.sleep(1_000)
    whoami(conn)

    :timer.sleep(15_000)
    whoami(conn)
  end
end
