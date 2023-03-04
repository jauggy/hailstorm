defmodule Hailstorm.TachyonHelper do
  require Logger
  alias Hailstorm.TachyonWsServer, as: Ws
  alias Hailstorm.ListenerServer
  alias Hailstorm.TachyonPbLib

  @type sslsocket() :: {:sslsocket, any, any}

  @spec get_host() :: binary()
  def get_host(), do: Application.get_env(:hailstorm, Hailstorm)[:host]

  @spec get_websocket_url() :: non_neg_integer()
  def get_websocket_url(), do: Application.get_env(:hailstorm, Hailstorm)[:websocket_url]

  @spec get_password() :: String.t()
  def get_password(), do: Application.get_env(:hailstorm, Hailstorm)[:password]

  @spec new_connection(map()) :: {:ok, pid(), pid()} | {:error, String.t()}
  def new_connection(params) do
    with :ok <- create_user(params),
      :ok <- update_user(params.email, Map.merge(%{verified: true}, params[:update] || %{
        friends: [],
        friend_requests: [],
        ignored: [],
        avoided: []
      })),
      listener <- ListenerServer.new_listener(),
      {:ok, ws} <- get_socket(listener)
      # :ok <- login(ws, params.email)
    do
      {:ok, ws, listener}
    else
      failure -> failure
    end
  end

  @spec get_socket(pid()) :: {:ok, sslsocket()} | {:error, any}
  defp get_socket(listener) do
    Ws.start_link(get_websocket_url(), listener)
  end

  @spec create_user(map()) :: :ok | {:error, String.t()}
  defp create_user(params) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/create_user"
    ] |> Enum.join("/")

    data = params
      |> Map.put("password", get_password())
      |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, resp} ->
        resp.body |> Jason.decode!
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error creating user #{params.email} at '#{result["stage"]}' because #{result["reason"]}"}
      %{"userid" => _userid} ->
        :ok
    end
  end

  @spec update_user(String.t(), map()) :: :ok | {:error, String.t()}
  defp update_user(email, params) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/ts_update_user"
    ] |> Enum.join("/")

    data = %{
      email: "#{email}@hailstorm",
      attrs: params
    } |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, resp} ->
        resp.body |> Jason.decode!
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error updating user #{email} at '#{result["stage"]}' because #{result["reason"]}"}
      %{"result" => "success"} ->
        :ok
    end
  end

  # @spec login(sslsocket(), Map.t()) :: :ok | {:error, String.t()}
  # defp login(socket, email) do
  #   with {:ok, token} <- get_token(socket, email),
  #       :ok <- login_socket(socket, token)
  #     do
  #       :ok
  #     else
  #       failure -> failure
  #   end
  # end

  # @spec get_token(sslsocket, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  # defp get_token(socket, email) do
  #   tachyon_send(socket, "c.user.get_token_by_email #{email}@hailstorm\t#{get_password()}")

  #   case tachyon_recv(socket) do
  #     "s.user.user_token " <> token_resp ->
  #       [_email, token] = String.split(token_resp, "\t")
  #       {:ok, token}
  #     resp -> {:error, "Error getting token: #{inspect resp}"}
  #   end
  # end

  @spec tachyon_send(pid(), map) :: :ok
  @spec tachyon_send(pid(), map, list) :: :ok
  def tachyon_send(ws, object, metadata \\ []) do
    type = TachyonPbLib.get_atom(object.__struct__)
    binary = TachyonPbLib.client_wrap_and_encode({type, object}, metadata)
    WebSockex.send_frame(ws, {:binary, binary})
  end

  @spec read_messages(pid) :: list
  def read_messages(ls), do: read_messages(ls, 500)

  @spec read_messages(pid, non_neg_integer()) :: list
  def read_messages(ls, timeout) do
    do_read_messages(ls, timeout, System.system_time(:millisecond))
  end

  @spec do_read_messages(pid, non_neg_integer(), non_neg_integer()) :: list
  defp do_read_messages(ls, timeout, start_time) do
    case ListenerServer.read(ls) do
      [] ->
        time_taken = System.system_time(:millisecond) - start_time
        if time_taken > timeout do
          []
        else
          :timer.sleep(50)
          do_read_messages(ls, timeout, start_time)
        end

      result ->
        result |> strip_metadata_from_messages
    end
  end

  @spec pop_messages(pid) :: list
  def pop_messages(ls), do: pop_messages(ls, 500)

  @spec pop_messages(pid, non_neg_integer()) :: list
  def pop_messages(ls, timeout) do
    do_pop_messages(ls, timeout, System.system_time(:millisecond))
  end

  @spec do_pop_messages(pid, non_neg_integer(), non_neg_integer()) :: list
  defp do_pop_messages(ls, timeout, start_time) do
    case ListenerServer.pop(ls) do
      [] ->
        time_taken = System.system_time(:millisecond) - start_time
        if time_taken > timeout do
          []
        else
          :timer.sleep(50)
          do_pop_messages(ls, timeout, start_time)
        end

      result ->
        result |> strip_metadata_from_messages
    end
  end

  @spec strip_metadata_from_messages(list) :: list
  def strip_metadata_from_messages(messages) do
    messages
      |> Enum.map(fn {{_type, object}, _metadata} ->
        # Map.drop(object, [:__unknown_fields__])
        object
      end)
  end

  defmacro __using__(_opts) do
    quote do
      import Hailstorm.TachyonHelper, only: [
        tachyon_send: 2,
        read_messages: 1,
        read_messages: 2,
        pop_messages: 1,
        pop_messages: 2,
        new_connection: 1
      ]
      alias Hailstorm.TachyonHelper
      alias Tachyon
    end
  end
end
