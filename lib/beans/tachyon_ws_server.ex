defmodule Beans.TachyonWsServer do
  use WebSockex

  def start_link(url, listener_pid) do
    WebSockex.start_link(url, __MODULE__, blank_state(listener_pid))
  end

  def handle_frame({_type, msg}, state) do
    # IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    # IO.puts "Received Message - Message: #{inspect msg}"
    send(state.listener_pid, msg)
    {:ok, state}
  end

  def handle_cast({:send, {_type, _msg} = frame}, state) do
    # IO.puts "Sending #{type} frame with payload: #{msg}"
    {:reply, frame, state}
  end

  defp blank_state(listener_pid) do
    %{
      listener_pid: listener_pid
    }
  end
end
