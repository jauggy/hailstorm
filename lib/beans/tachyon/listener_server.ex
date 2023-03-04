defmodule Beans.ListenerServer do
  @moduledoc """
  A genserver for collecting messages sent to the websocket.

  Reading will return the state without emptying it
  Popping will return the state and clear it
  """

  use GenServer
  alias Beans.TachyonPbLib

  def new_listener() do
    {:ok, pid} = start_link()
    pid
  end

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  def read(pid) do
    GenServer.call(pid, :read)
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [])
  end

  # Internal
  # GenServer callbacks
  def handle_info(item, state) do
    msg = TachyonPbLib.server_decode_and_unwrap(item)

    {:noreply, [msg | state]}
  end

  def handle_call(:pop, _from, state) do
    {:reply, state, []}
  end

  def handle_call(:read, _from, state) do
    {:reply, state, state}
  end

  def init(_opts) do
    {:ok, []}
  end
end
