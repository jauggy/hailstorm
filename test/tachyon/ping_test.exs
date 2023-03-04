defmodule Beans.Tests.PingTest do
  @moduledoc """
  Tests the Ping command
  """
  use ExUnit.Case, async: true
  use Beans.Tachyon

  alias Beans.TachyonWsServer, as: Ws
  alias Beans.TachyonPbLib
  alias Beans.ListenerServer, as: Ls

  # @ping_user_params %{
  #   email: "ping",
  #   name: "ping"
  # }

  test "test" do
    listener = Ls.new_listener()
    {:ok, ws} = Ws.start_link("ws://localhost:4000/tachyon/websocket", listener)

    type = :token_request
    object = Tachyon.TokenRequest.new(
      email: "email",
      password: "password"
    )

    attrs = []
    binary = TachyonPbLib.client_wrap_and_encode({type, object}, attrs)

    WebSockex.send_frame(ws, {:binary, binary})
    :timer.sleep(100)

    messages = Ls.get(listener)

    # IO.puts ""
    # IO.inspect messages
    # IO.puts ""

    assert Enum.member?(messages, {{:token_response,
    %Tachyon.TokenResponse{token: "token", __unknown_fields__: []}}, %{id: 0}})

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
