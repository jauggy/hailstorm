defmodule Hailstorm.SpringLoad.PingPongUser do
  @moduledoc """

  """
  use GenServer
  alias Hailstorm.SpringHelper
  alias Hailstorm.Servers.MetricServer

  @ping_interval 3_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  def handle_info(:ping, state) do
    msg_id = :rand.uniform() * 100000 |> round()
    sent_at = System.system_time(:millisecond)
    SpringHelper.spring_send(state.socket, "##{msg_id} PING", false)

    messages = wait_for_pong(state, msg_id)
    received_at = System.system_time(:millisecond)

    time_taken = received_at - sent_at
    message_count = Enum.count(messages)

    MetricServer.report_measure("messages", message_count)
    MetricServer.report_measure("time_taken", time_taken)

    :timer.send_after(@ping_interval, :ping)

    {:noreply, state}
  end

  defp wait_for_pong(state, msg_id, messages \\ []) do
    new_messages = SpringHelper.spring_recv_until(state.socket)
      |> String.split("\n")

    pong = new_messages
      |> Enum.filter(fn msg ->
        String.contains?(msg, "##{msg_id} PONG")
      end)

    combined = messages ++ new_messages

    case pong do
      [] -> wait_for_pong(state, msg_id, combined)
      _ -> combined
    end
  end

  defp login(name, email) do
    {socket, _} = SpringHelper.new_raw_connection(name, email)
    socket
  end

  def init(args) do
    socket = login(args.name, args.email)
    send(self(), :ping)

    {:ok, %{
      msg_id: nil,
      sent_at: nil,
      socket: socket
    }}
  end
end
