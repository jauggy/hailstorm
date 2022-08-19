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
    with {:ok, socket, _user} <- new_connection(@ping_user_params),
        :ok <- test_ping(socket)
      do
        :ok
      else
        {:error, reason} -> {:failure, reason}
    end
  end

  @spec test_ping(Tachyon.sslsocket) :: :ok | {:error, String.t()}
  defp test_ping(socket) do
    tachyon_send(socket, %{
      cmd: "c.system.ping"
    })

    case tachyon_recv(socket) do
      [] -> {:error, "No reply to ping command"}
      [%{"cmd" => "s.system.pong", "time" => _}] -> :ok
      _ -> {:error, "Unexpected response to ping command"}
    end
  end
end
