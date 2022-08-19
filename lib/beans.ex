defmodule Beans do
  @moduledoc """
  Documentation for `Beans`.
  """

  @spec register_module(module()) :: :ok | nil
  def register_module(module) do
    cast_server(:collector, {:register, module})
  end

  @spec save_result(module(), :ok | {:failure, String.t()}) :: :ok | nil
  def save_result(module, result) do
    Beans.cast_server(:collector, {:complete, module, result})
  end

  @spec get_server_pid(any) :: pid() | nil
  def get_server_pid(id) do
    case Registry.lookup(Beans.Registry, id) do
      [{pid, _}] ->
        pid
      _ ->
        nil
    end
  end

  @spec cast_server(T.id(), any) :: any
  def cast_server(nil, _), do: :ok
  def cast_server(id, msg) do
    case get_server_pid(id) do
      nil -> nil
      pid -> GenServer.cast(pid, msg)
    end
  end

  @spec send_server(T.id(), any) :: any
  def send_server(nil, _), do: :ok
  def send_server(id, msg) do
    case get_server_pid(id) do
      nil -> nil
      pid -> send(pid, msg)
    end
  end

  @spec call_server(any, any) :: any
  def call_server(id, msg) do
    case get_server_pid(id) do
      nil -> nil
      pid -> GenServer.call(pid, msg)
    end
  end

  @spec list_tests() :: []
  def list_tests do
    with {:ok, mlist} <- :application.get_key(:beans, :modules) do
      mlist
        |> Enum.filter(& &1 |> Module.split |> Enum.take(2) == ~w(Beans Tests))
    end
  end
end
