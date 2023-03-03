defmodule Beans.TachyonWsServer do
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, blank_state())
  end

  def handle_frame({type, msg}, state) do
    # IO.puts "Received Message - Type: #{inspect type} -- Message: #{inspect msg}"
    {:ok, %{state | messages: [msg | state.messages]}}
  end

  def handle_cast({:send, {type, msg} = frame}, state) do
    IO.puts "Sending #{type} frame with payload: #{msg}"
    {:reply, frame, state}
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, state.messages, state}
  end

  def handle_call(:pop_messages, _from, state) do
    {:reply, state.messages, %{state | messages: []}}
  end

  defp blank_state() do
    %{
      messages: []
    }
  end
end
