defmodule Hailstorm.SpringLoad.PingPongUser do
  use GenServer
  alias Hailstorm.SpringHelper

  @ping_interval 3_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  def handle_info(:ping, state) do
    SpringHelper.spring_send(state.socket, "PING")

    {:noreply, state}
  end

  defp login(name, email) do
    SpringHelper.new_raw_connection(name, email)
  end

  def init(args) do
    :timer.send_interval(@ping_interval, :ping)
    socket = login(args.name, args.email)

    {:ok, %{
      socket: socket
    }}
  end
end
