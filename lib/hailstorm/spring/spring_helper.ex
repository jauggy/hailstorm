defmodule Hailstorm.SpringHelper do
  @moduledoc """

  """
  require Logger

  @type sslsocket() :: {:sslsocket, any, any}

  @spec get_host() :: binary()
  def get_host(), do: Application.get_env(:hailstorm, Hailstorm)[:host]

  @spec get_socket_url() :: non_neg_integer()
  def get_socket_url(), do: Application.get_env(:hailstorm, Hailstorm)[:host_socket_url]

  @spec get_port() :: non_neg_integer()
  def get_port(), do: Application.get_env(:hailstorm, Hailstorm)[:spring_ssl_port]

  @spec get_password() :: String.t()
  def get_password(), do: Application.get_env(:hailstorm, Hailstorm)[:password]

  defp cleanup_params(params) do
    email = Map.get(params, :email, params.name) <> "@hailstorm_spring"
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
      spring_recv_until(socket)
      socket
    else
      failure -> {:error, failure}
    end
  end

  @spec new_raw_connection(String.t(), String.t()) :: {{:ok, sslsocket(), map}, list} | {:error, String.t()}
  def new_raw_connection(name, email) do
    {:ok, socket} = get_socket()
    spring_recv_until(socket)

    # Send registration
    spring_send(socket, "REGISTER #{name} password #{email}")
    r = spring_recv_until(socket)

    case r do
      "REGISTRATIONDENIED Username already taken\n" -> :ok
      "REGISTRATIONACCEPTED\n" -> :ok
    end

    # Now login
    cmd = "LOGIN #{name} password 0 * Hailstorm\t1993717506 0d04a635e200f308\tb sp\n"

    spring_send(socket, cmd)
    response = socket
      |> spring_recv_until(2500)
      |> split_commands

    commands = response
      |> Map.new

    if Map.has_key?(commands, "LOGININFOEND") do
      {socket, response}
    else
      raise "Unable to login - #{inspect response}"
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
      email: "#{email}",
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
    spring_send(socket, "c.user.get_token_by_email #{email}\t#{get_password()}")

    case spring_recv(socket) do
      "s.user.user_token " <> token_resp ->
        [_email, token] = String.split(token_resp, "\t")
        {:ok, token}
      resp -> {:error, "Error getting token: #{inspect resp}"}
    end
  end

  @spec login_socket(sslsocket(), String.t()) :: :ok | {:error, String.t()}
  defp login_socket(socket, token) do
    spring_send(socket, "c.user.login #{token}\tHailstorm\tBEANS\ta b c")

    case spring_recv(socket) do
      "ACCEPTED " <> _username ->
        :ok

      "QUEUED" <> _ ->
        login_queue(socket)

      resp ->
        {:error, "No reply when performing authentication: #{inspect resp}"}
    end
  end

  @spec login_socket(sslsocket(), String.t()) :: :ok | {:error, String.t()}
  defp login_queue(socket) do
    :timer.sleep(500)
    spring_send(socket, "c.auth.login_queue_heartbeat")

    case spring_recv(socket) do
      "ACCEPTED " <> _username ->
        :ok

      "QUEUED" <> _ ->
        login_queue(socket)

      resp ->
        {:error, "No reply when performing authentication: #{inspect resp}"}
    end
  end

  @spec spring_send(sslsocket(), String.t() | [String.t()]) :: :ok
  def spring_send(socket, msgs), do: spring_send(socket, msgs, true)

  @spec spring_send(sslsocket(), String.t() | [String.t()], boolean) :: :ok
  def spring_send(socket = {:sslsocket, _, _}, msgs, do_sleep) when is_list(msgs) do
    msgs
      |> Enum.each(fn msg ->
        msg = if String.ends_with?(msg, "\n"), do: msg, else: "#{msg}\n"
        :ok = :ssl.send(socket, msg)
      end)

    if do_sleep do
      :timer.sleep(100)
    end
  end

  @spec spring_send(sslsocket(), String.t()) :: :ok
  def spring_send(socket = {:sslsocket, _, _}, msg, do_sleep) do
    msg = if String.ends_with?(msg, "\n"), do: msg, else: "#{msg}\n"
    :ok = :ssl.send(socket, msg)

    if do_sleep do
      :timer.sleep(100)
    end
  end

  def spring_send(socket, msg, do_sleep) do
    msg = if String.ends_with?(msg, "\n"), do: msg, else: "#{msg}\n"
    :ok = :gen_tcp.send(socket, msg)

    if do_sleep do
      :timer.sleep(100)
    end
  end

  def spring_recv(socket = {:sslsocket, _, _}) do
    case :ssl.recv(socket, 0, 1500) do
      {:ok, reply} -> reply |> to_string |> String.trim()
      {:error, :timeout} -> :timeout
      {:error, :closed} -> :closed
      {:error, :einval} -> :einval
    end
  end

  def spring_recv(socket) do
    case :gen_tcp.recv(socket, 0, 1500) do
      {:ok, reply} -> reply |> to_string |> String.trim()
      {:error, :timeout} -> :timeout
      {:error, :closed} -> :closed
    end
  end

  def spring_recv_until(socket, timeout \\ 1500), do: do_spring_recv_until(socket, "", timeout)

  defp do_spring_recv_until(socket = {:sslsocket, _, _}, acc, timeout) do
    case :ssl.recv(socket, 0, timeout) do
      {:ok, reply} ->
        do_spring_recv_until(socket, acc <> to_string(reply), timeout)

      {:error, :timeout} ->
        acc
    end
  end

  defp do_spring_recv_until(socket, acc, timeout) do
    case :gen_tcp.recv(socket, 0, timeout) do
      {:ok, reply} ->
        do_spring_recv_until(socket, acc <> to_string(reply), timeout)

      {:error, :timeout} ->
        acc
    end
  end

  @spec split_commands(String.t()) :: [{String.t(), [String.t()]}]
  def split_commands(string) do
    string
    |> String.split("\n")
    |> Enum.reject(fn s -> s == "" end)
    |> Enum.map(fn line ->
      [spaces | tabbed] = String.split(line, "\t")
      [cmd | spaced] = String.split(spaces, " ")

      {cmd, spaced ++ tabbed}
    end)
  end

  defmacro __using__(_opts) do
    quote do
      import Hailstorm.SpringHelper, only: [
        spring_send: 2,
        spring_recv: 1,
        spring_recv_until: 1,
        new_connection: 1,
        split_commands: 1
      ]
      alias Hailstorm.SpringHelper
      alias Hailstorm.Spring.Commands
    end
  end
end
