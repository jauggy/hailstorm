defmodule Hailstorm.TachyonWsServer do
  use WebSockex

  def start_link(url, listener_pid) do
    WebSockex.start_link(url, __MODULE__, blank_state(listener_pid))
  end

  def handle_frame({_type, msg}, state) do
    send(state.listener_pid, msg)
    {:ok, state}
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end

  def terminate(reason, state) do
    send(state.listener_pid, {:ws_terminate, reason})
    exit(:normal)
  end

  defp blank_state(listener_pid) do
    %{
      listener_pid: listener_pid
    }
  end
end
