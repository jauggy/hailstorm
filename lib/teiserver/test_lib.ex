defmodule Teiserver.Protocols.TeiserverTestLib
do
  alias Teiserver.Protocols.TachyonLib

  @moduledoc """
  This has functions copied from TeiServer repo
  """
    def _send_raw(socket = {:sslsocket, _, _}, msg) do
      :ok = :ssl.send(socket, msg)
      :timer.sleep(100)
    end

    def _send_raw(socket, msg) do
      :ok = :gen_tcp.send(socket, msg)
      :timer.sleep(100)
    end

    def tachyon_send(socket, data) do
      msg = TachyonLib.encode(data)
      _send_raw(socket, msg <> "\n")
    end

    def tachyon_recv(socket) do
      case _recv_raw(socket) do
        :timeout ->
          :timeout

        :closed ->
          :closed

        resp ->
          resp
          |> String.split("\n")
          |> Enum.map(fn line ->
            case TachyonLib.decode(line) do
              {:ok, msg} -> msg
              error -> error
            end
          end)
          |> Enum.filter(fn r -> r != nil end)
      end
    end

    def _recv_raw(socket = {:sslsocket, _, _}) do
      case :ssl.recv(socket, 0, 500) do
        {:ok, reply} -> reply |> to_string
        {:error, :timeout} -> :timeout
        {:error, :closed} -> :closed
      end
    end

    def _recv_raw(socket) do
      case :gen_tcp.recv(socket, 0, 500) do
        {:ok, reply} -> reply |> to_string
        {:error, :timeout} -> :timeout
        {:error, :closed} -> :closed
      end
    end
end
