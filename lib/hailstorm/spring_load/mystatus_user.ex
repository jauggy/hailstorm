defmodule Hailstorm.SpringLoad.MystatusUser do
  use GenServer
  alias Hailstorm.SpringHelper

  @ping_interval 3_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  def handle_info(:status, %{last_status: last_status} = state) do
    new_status = case last_status do
      "127" ->
        SpringHelper.spring_send(state.socket, "MYSTATUS 0")
        "0"

      _ ->
        SpringHelper.spring_send(state.socket, "MYSTATUS 127")
        "127"
    end

    {:noreply, %{state | last_status: new_status}}
  end

  defp login(name, email) do
    SpringHelper.new_raw_connection(name, email)
  end

  def init(args) do
    :timer.send_interval(@ping_interval, :status)
    socket = login(args.name, args.email)

    {:ok, %{
      socket: socket,
      last_status: nil
    }}
  end
end
