defmodule Beans.Tests.Ping do
  @moduledoc """
  Tests the Ping command
  """
  import Beans.Tachyon, only: [tachyon_send: 2, tachyon_recv: 1, new_connection: 1]

  @ping_user_params %{
    email: "ping",
    name: "ping",
  }

  @spec perform :: nil | :ok
  def perform() do
    Beans.register_module(__MODULE__)

    result = with {:ok, socket, _user} <- new_connection(@ping_user_params),
        :ok <- test_ping(socket)
      do
        :ok
      else
        {:error, reason} ->
          {:failure, reason}
    end

    Beans.save_result(__MODULE__, result)
  end

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
