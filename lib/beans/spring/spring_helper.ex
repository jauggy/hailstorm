defmodule Beans.SpringHelper do
  @moduledoc """

  """
  require Logger

  @type sslsocket() :: {:sslsocket, any, any}

  @spec get_host() :: binary()
  def get_host(), do: Application.get_env(:beans, Beans)[:host]

  @spec get_socket_url() :: non_neg_integer()
  def get_socket_url(), do: Application.get_env(:beans, Beans)[:host_socket_url]

  @spec get_port() :: non_neg_integer()
  def get_port(), do: Application.get_env(:beans, Beans)[:spring_ssl_port]

  @spec get_password() :: String.t()
  def get_password(), do: Application.get_env(:beans, Beans)[:password]

  defp cleanup_params(params) do
    email = Map.get(params, :email, params.name)
    Map.put(params, :email, email)
  end

  @spec new_connection(map()) :: {:ok, sslsocket(), map} | {:error, String.t()}
  def new_connection(params) do
    params = cleanup_params(params)

    with :ok <- create_user(params),
      :ok <- update_user(Map.get(params, :email, params.name), Map.merge(%{verified: true}, params[:update] || %{
        friends: [],
        friend_requests: [],
        ignored: [],
        avoided: []
      })),
      {:ok, socket} <- get_socket(),
      _welcome_message <- spring_recv(socket),
      :ok <- login(socket, params.email)
    do
      {:ok, socket}
    else
      failure -> failure
    end
  end

  @spec server_exists? :: boolean
  def server_exists?() do
    case get_socket() do
      {:ok, _socket} -> true
      {:error, :econnrefused} -> false
    end
  end

  @spec get_socket :: {:ok, sslsocket()} | {:error, any}
  defp get_socket() do
    :ssl.connect(
      get_socket_url(),
      get_port(),
      active: false,
      verify: :verify_none
    )
  end

  @spec create_user(map()) :: :ok | {:error, String.t()}
  defp create_user(params) do
    url = [
      Application.get_env(:beans, Beans)[:host_web_url],
      "teiserver/api/beans/create_user"
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
      Application.get_env(:beans, Beans)[:host_web_url],
      "teiserver/api/beans/ts_update_user"
    ] |> Enum.join("/")

    data = %{
      email: "#{email}@beans",
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

  @spec login(sslsocket(), Map.t()) :: :ok | {:error, String.t()}
  defp login(socket, email) do
    with {:ok, token} <- get_token(socket, email),
        :ok <- login_socket(socket, token)
      do
        :ok
      else
        failure -> failure
    end
  end

  @spec get_token(sslsocket, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_token(socket, email) do
    spring_send(socket, "c.user.get_token_by_email #{email}@beans\t#{get_password()}")

    case spring_recv(socket) do
      "s.user.user_token " <> token_resp ->
        [_email, token] = String.split(token_resp, "\t")
        {:ok, token}
      resp -> {:error, "Error getting token: #{inspect resp}"}
    end
  end

  @spec login_socket(sslsocket(), String.t()) :: :ok | {:error, String.t()}
  defp login_socket(socket, token) do
    spring_send(socket, "c.user.login #{token}\tBeans\tBEANS\ta b c")

    case spring_recv(socket) do
      "ACCEPTED " <> _username ->
        :ok

      resp ->
        {:error, "No reply when performing authentication: #{inspect resp}"}
    end
  end


  @spec spring_send(sslsocket(), String.t()) :: :ok
  def spring_send(socket = {:sslsocket, _, _}, msg) do
    msg = if String.ends_with?(msg, "\n"), do: msg, else: "#{msg}\n"
    :ok = :ssl.send(socket, msg)
    :timer.sleep(50)
  end

  def spring_send(socket, msg) do
    msg = if String.ends_with?(msg, "\n"), do: msg, else: "#{msg}\n"
    :ok = :gen_tcp.send(socket, msg)
    :timer.sleep(50)
  end

  def spring_recv(socket = {:sslsocket, _, _}) do
    case :ssl.recv(socket, 0, 500) do
      {:ok, reply} -> reply |> to_string |> String.trim()
      {:error, :timeout} -> :timeout
      {:error, :closed} -> :closed
      {:error, :einval} -> :einval
    end
  end

  def spring_recv(socket) do
    case :gen_tcp.recv(socket, 0, 500) do
      {:ok, reply} -> reply |> to_string |> String.trim()
      {:error, :timeout} -> :timeout
      {:error, :closed} -> :closed
    end
  end

  def spring_recv_until(socket), do: spring_recv_until(socket, "")
  def spring_recv_until(socket = {:sslsocket, _, _}, acc) do
    case :ssl.recv(socket, 0, 500) do
      {:ok, reply} ->
        spring_recv_until(socket, acc <> to_string(reply))

      {:error, :timeout} ->
        acc
    end
  end

  def spring_recv_until(socket, acc) do
    case :gen_tcp.recv(socket, 0, 500) do
      {:ok, reply} ->
        spring_recv_until(socket, acc <> to_string(reply))

      {:error, :timeout} ->
        acc
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Beans.SpringHelper, only: [
        spring_send: 2,
        spring_recv: 1,
        spring_recv_until: 1,
        new_connection: 1
      ]
      alias Beans.SpringHelper
      alias Beans.Spring.Commands
    end
  end
end
