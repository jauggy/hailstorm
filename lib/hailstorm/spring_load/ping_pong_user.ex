defmodule Hailstorm.SpringLoad.PingPongUser do
  @moduledoc """

  """
  use GenServer
  alias Hailstorm.SpringHelper

  @ping_interval 3_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  def handle_info(:ping, state) do
    msg_id = :random.uniform() * 100000 |> round()
    sent_at = System.system_time(:millisecond)
    SpringHelper.spring_send(state.socket, "##{msg_id} PING", false)

    messages = SpringHelper.spring_recv_until(state.socket)

    IO.puts ""
    IO.inspect messages
    IO.puts ""

    {:noreply, state}
  end

  defp login(name, email) do
    SpringHelper.new_raw_connection(name, email)
  end

  def init(args) do
    :timer.send_interval(@ping_interval, :ping)
    socket = login(args.name, args.email)

    {:ok, %{
      msg_id: nil,
      sent_at: nil,
      socket: socket
    }}
  end
end
