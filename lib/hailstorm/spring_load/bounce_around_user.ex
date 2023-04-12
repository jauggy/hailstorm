defmodule Hailstorm.SpringLoad.BouncearoundUser do
  use GenServer
  alias Hailstorm.SpringHelper

  @stuff_interval 3_000

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts[:data])
  end

  def handle_info(:do_stuff, %{status: :logged_out} = state) do
    {socket, commands} = login(state.name, state.email)

    lobby_ids = commands
      |> Enum.filter(fn {cmd, _args} -> cmd == "BATTLEOPENED" end)
      |> Enum.map(fn {_, [id_str | _]} ->
        String.to_integer(id_str)
      end)

    {:noreply, %{state | socket: socket, status: :logged_in, lobby_ids: lobby_ids}}
  end

  def handle_info(:do_stuff, %{status: :logged_in} = state) do
    chosen_id = Enum.random(state.lobby_ids)
    SpringHelper.spring_send(state.socket, "JOINBATTLE #{chosen_id} empty password")

    {:noreply, %{state | status: :in_lobby, lobby_id: chosen_id}}
  end

  def handle_info(:do_stuff, %{status: :in_lobby} = state) do
    r = :rand.uniform()

    cond do
      r < 0.05 ->
        SpringHelper.spring_send(state.socket, "EXIT")
        {:noreply, %{state | status: :logged_out, socket: nil, lobby_ids: []}}

      r < 0.3 ->
        SpringHelper.spring_send(state.socket, "LEAVEBATTLE")
        {:noreply, %{state | status: :logged_in, lobby_id: nil}}

      r < 0.5 ->
        chosen_id = Enum.random(state.lobby_ids)
        SpringHelper.spring_send(state.socket, "JOINBATTLE #{chosen_id} empty password")
        {:noreply, %{state | status: :in_lobby, lobby_id: chosen_id}}

      true ->
        SpringHelper.spring_send(state.socket, "SAYBATTLE test message #{:rand.uniform()}")
        {:noreply, state}
    end
  end

  defp login(name, email) do
    SpringHelper.new_raw_connection(name, email)
  end

  def init(args) do
    :timer.send_interval(@stuff_interval, :do_stuff)

    {:ok, %{
      name: args.name,
      email: args.email,
      socket: nil,
      lobby_ids: [],
      lobby_id: nil,
      status: :logged_out
    }}
  end
end
