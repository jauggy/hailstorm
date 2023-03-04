defmodule Hailstorm.TachyonPbLib do
  @moduledoc """

  """

  @module_from_atom %{
    empty: Tachyon.Empty,
    failure: Tachyon.Failure,

    token_response: Tachyon.TokenResponse,

    token_request: Tachyon.TokenRequest,
  }

  @atom_from_module @module_from_atom
    |> Map.new(fn {k, v} -> {v, k} end)

  @spec get_module(atom) :: module()
  def get_module(atom) do
    @module_from_atom[atom]
  end

  @spec get_atom(module()) :: atom
  def get_atom(module) do
    @atom_from_module[module]
  end

  # Client message wrap functions
  @spec client_wrap({atom, map}, map()) :: Tachyon.ClientMessage.t()
  def client_wrap({type, object}, attrs) do
    Tachyon.ClientMessage.new(
      id: attrs[:id],
      object: {type, object}
    )
  end

  @spec client_encode(Tachyon.ClientMessage.t()) :: binary()
  def client_encode(data) do
    Tachyon.ClientMessage.encode(data)
  end

  @spec client_wrap_and_encode({atom, map}, list()) :: binary()
  def client_wrap_and_encode({type, object}, attrs) do
    client_wrap({type, object}, attrs)
    |> client_encode
  end

  # Server unwrap functions
  @spec server_unwrap(Tachyon.ServerMessage.t()) :: {{atom, map()}, map}
  def server_unwrap(%{object: {type, object}} = data) do
    metadata = Map.drop(data, [:__struct__, :__unknown_fields__, :object])

    {{type, object}, metadata}
  end

  @spec server_decode(binary()) :: Tachyon.ServerMessage.t()
  def server_decode(data) do
    Tachyon.ServerMessage.decode(data)
  end

  @spec server_decode_and_unwrap(binary()) :: {{atom, map()}, map}
  def server_decode_and_unwrap(data) do
    Tachyon.ServerMessage.decode(data)
    |> server_unwrap
  end
end
