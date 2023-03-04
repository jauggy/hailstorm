defmodule Beans.ListenerServer do
  @moduledoc """
  A genserver whose sole purpose is to listen to one or more pubusbs and record what they get sent
  """

  use GenServer
  alias Phoenix.PubSub
  alias Beans.TachyonPbLib

  def new_listener() do
    {:ok, pid} = start_link()
    pid
  end

  def pop(pid) do
    GenServer.call(pid, :pop)
  end

  def get(pid) do
    GenServer.call(pid, :get)
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

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def init(_opts) do
    {:ok, []}
  end
end
