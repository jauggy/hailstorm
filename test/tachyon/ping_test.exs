defmodule Beans.Tests.Ping do
  @moduledoc """
  Tests the Ping command
  """
  use Beans.Tachyon

  @ping_user_params %{
    email: "ping",
    name: "ping"
  }

  @spec perform :: :ok | {:failure, String.t()}
  def perform() do
    # Get the socket (and the user though we don't reference it)
    {:ok, socket, _user} = new_connection(@ping_user_params)

    # New sent our ping out
    tachyon_send(socket, %{
      cmd: "c.system.ping"
    })

    # Get the response back from the server
    # we could use the assert function but
    # we want to be helpful and say what's gone wrong if something has!
    case tachyon_recv(socket) do
      [] -> {:error, "No reply to ping command"}
      [%{"cmd" => "s.system.pong", "time" => _}] -> :ok
      _ -> {:error, "Unexpected response to ping command"}
    end
  end
end
