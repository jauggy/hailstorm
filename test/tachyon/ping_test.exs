defmodule Beans.Tests.PingTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Beans.Tachyon

  alias Beans.TachyonWsServer, as: Ws
  alias Beans.TachyonPbLib

  # @ping_user_params %{
  #   email: "ping",
  #   name: "ping"
  # }

  test "test" do
    {:ok, ws} = Ws.start_link("ws://localhost:4000/tachyon/websocket", %{})

    type = :token_request
    object = Tachyon.TokenRequest.new(
      email: "email",
      password: "password"
    )

    attrs = []
    binary = TachyonPbLib.client_wrap_and_encode({type, object}, attrs)

    WebSockex.send_frame(ws, {:binary, binary})

  #   good = <<162, 6, 17, 10, 5, 101, 109, 97, 105, 108, 18, 8, 112, 97, 115, 115, 119, 111,
  # 114, 100>>

  #   bad = <<162, 6, 14, 10, 5, 101, 109, 97, 105, 108, 18, 5, 119, 114, 111, 110, 103>>


    :timer.sleep(200)
  end

  # @spec perform :: :ok | {:failure, String.t()}
  # def perform() do
  #   # Get the socket (and the user though we don't reference it)
  #   {:ok, socket, _user} = new_connection(@ping_user_params)

  #   # New sent our ping out
  #   tachyon_send(socket, %{
  #     cmd: "c.system.ping"
  #   })

  #   # Get the response back from the server
  #   # we could use the assert function but
  #   # we want to be helpful and say what's gone wrong if something has!
  #   case tachyon_recv(socket) do
  #     [] -> {:error, "No reply to ping command"}
  #     [%{"cmd" => "s.system.pong", "time" => _}] -> :ok
  #     _ -> {:error, "Unexpected response to ping command"}
  #   end
  # end
end
