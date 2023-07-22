defmodule Hailstorm.ListenerServer do
  @moduledoc """
  A genserver for collecting messages sent to the websocket.

  Reading will return the state without emptying it
  Popping will return the state and clear it
  """

  use GenServer

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
  def handle_info({:set_forward, forward_pid}, state) do
    {:noreply, %{state | forward_pid: forward_pid}}
  end

  def handle_info({sys_message, reason}, %{forward_pid: nil} = state) do
    {:noreply, %{state | messages: [{sys_message, reason} | state.messages]}}
  end

  def handle_info(raw_json, %{forward_pid: nil} = state) do
    object = Jason.decode!(raw_json)

    {:noreply, %{state | messages: [object | state.messages]}}
  end

  # And now handle when we have a forwarding pid
  def handle_info({sys_message, reason}, %{forward_pid: p} = state) do
    send(p, {sys_message, reason})
    {:noreply, state}
  end

  def handle_info(raw_json, %{forward_pid: p} = state) do
    object = Jason.decode!(raw_json)
    send(p, object)
    {:noreply, state}
  end

  def handle_call(:pop, _from, state) do
    {:reply, state.messages, %{state | messages: []}}
  end

  def handle_call(:read, _from, state) do
    {:reply, state.messages, state}
  end

  def init(_opts) do
    {:ok, %{
      forward_pid: nil,
      messages: []
    }}
  end
end
