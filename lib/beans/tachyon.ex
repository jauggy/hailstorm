defmodule Beans.Tachyon do
  require Logger

  @type sslsocket() :: {:sslsocket, any, any}

  @spec get_host() :: binary()
  def get_host(), do: Application.get_env(:beans, Beans)[:host]

  @spec get_port() :: non_neg_integer()
  def get_port(), do: Application.get_env(:beans, Beans)[:port]

  @spec get_password() :: String.t()
  def get_password(), do: Application.get_env(:beans, Beans)[:password]

  @spec new_connection(map()) :: {:ok, sslsocket(), map} | {:error, String.t()}
  def new_connection(params) do
    with :ok <- create_user(params),
      :ok <- update_user(params.email, Map.merge(%{verified: true}, params[:update] || %{})),
      socket <- get_socket(),
      {:ok, user} <- login(socket, params.email)
    do
      {:ok, socket, user}
    else
      failure -> failure
    end
  end

  @spec get_socket :: sslsocket()
  defp get_socket() do
    {:ok, socket} =
      :ssl.connect(
        Application.get_env(:beans, Beans)[:host_socket_url],
        Application.get_env(:beans, Beans)[:port],
        active: false,
        verify: :verify_none
      )

    socket
  end

  @spec create_user(map()) :: :ok | {:error, String.t()}
  defp create_user(params) do
    url = [
      Application.get_env(:beans, Beans)[:host_api_url],
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
      Application.get_env(:beans, Beans)[:host_api_url],
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

  @spec login(sslsocket(), Map.t()) :: {:ok, map()} | {:error, String.t()}
  defp login(socket, email) do
    with {:ok, token} <- get_token(socket, email),
        {:ok, user} <- login_socket(socket, token)
      do
        {:ok, user}
      else
        failure -> failure
    end
  end

  @spec get_token(sslsocket, String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp get_token(socket, email) do
    tachyon_send(socket, %{
      cmd: "c.auth.get_token",
      email: "#{email}@beans",
      password: get_password()
    })

    case tachyon_recv(socket) do
      [] -> {:error, "No reply when getting token"}
      [%{"token" => token}] -> {:ok, token}
      [%{"reason" => reason}] -> {:error, "Error getting token: #{reason}"}
    end
  end

  @spec login_socket(sslsocket(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp login_socket(socket, token) do
    data = %{
      cmd: "c.auth.login",
      token: token,
      lobby_name: "Beans",
      lobby_version: "1",
      lobby_hash: "BEANS"
    }
    tachyon_send(socket, data)

    case tachyon_recv(socket) do
      [] ->
        {:error, "No reply when performing authentication"}

      [%{"cmd" => "s.auth.login", "result" => "success"} = resp] ->
        {:ok, resp["user"]}
    end
  end


  @spec tachyon_send(sslsocket(), Map.t()) :: :ok
  def tachyon_send(socket = {:sslsocket, _, _}, data) do
    msg = encode(data) <> "\n"
    raw_send(socket, msg)
  end

  @spec raw_send(sslsocket(), String.t()) :: :ok
  def raw_send(socket = {:sslsocket, _, _}, msg) do
    :ok = :ssl.send(socket, msg)
  end

  def recv_raw(socket = {:sslsocket, _, _}) do
    case :ssl.recv(socket, 0, 500) do
      {:ok, reply} -> reply |> to_string
      {:error, :timeout} -> :timeout
      {:error, :closed} -> :closed
      {:error, :einval} -> :einval
    end
  end

  def tachyon_recv(socket) do
    case recv_raw(socket) do
      :timeout -> []
      :closed -> :closed
      :einval -> :closed

      resp ->
        resp
        |> String.split("\n")
        |> Enum.map(fn line ->
          case decode(line) do
            {:ok, msg} -> msg
            error -> error
          end
        end)
        |> Enum.filter(fn r -> r != nil end)
    end
  end

  def tachyon_recv_until(socket), do: tachyon_recv_until(socket, [])
  def tachyon_recv_until(socket = {:sslsocket, _, _}, acc) do
    case :ssl.recv(socket, 0, 500) do
      {:ok, reply} ->
        resp = reply
        |> to_string
        |> String.split("\n")
        |> Enum.map(fn line ->
          case decode(line) do
            {:ok, msg} -> msg
            error -> error
          end
        end)
        |> Enum.filter(fn r -> r != nil end)
        tachyon_recv_until(socket, acc ++ resp)

      {:error, :timeout} ->
        acc
    end
  end

  @spec encode(List.t() | Map.t()) :: String.t()
  def encode(data) do
    case Jason.encode(data) do
      {:ok, encoded_data} ->
        encoded_data
          |> :zlib.gzip()
          |> Base.encode64()
      {:error, err} ->
        Logger.error("Tachyon encode error: #{Kernel.inspect err}\ndata: #{Kernel.inspect data}")

        %{
          result: "s.system.server_protocol_error",
          error: "JSON encode"
        }
        ""
          |> Jason.encode!
          |> :zlib.gzip()
          |> Base.encode64()
    end
  end

  @spec decode(String.t() | :timeout) :: {:ok, List.t() | Map.t()} | {:error, :bad_json}
  def decode(:timeout), do: {:ok, nil}
  def decode(""), do: {:ok, nil}
  def decode(data) do
    with {:ok, decoded64} <- Base.decode64(data |> String.trim),
         {:ok, unzipped} <- unzip(decoded64),
         {:ok, object} <- Jason.decode(unzipped) do
      {:ok, object}
    else
      :error ->
        # Previously got an error with data 'OK cmd=TACHYON' which suggests
        # it was still in Spring mode
        Logger.warn("Base64 error, given '#{data}'")
        {:error, :base64_decode}
      {:error, :gzip_decompress} ->
        Logger.warn("Gzip error, given '#{data}'")
        {:error, :gzip_decompress}
      {:error, %Jason.DecodeError{}} -> {:error, :bad_json}
    end
  end

  @spec decode!(String.t() | :timeout) :: List.t() | Map.t()
  def decode!(data) do
    case decode(data) do
      {:ok, result} -> result
      {:error, reason} ->
        raise "Tachyon decode! error: #{reason}, data: #{data}"
    end
  end

  defp unzip(data) do
    try do
      result = :zlib.gunzip(data)
      {:ok, result}
    rescue
      _ ->
        {:error, :gzip_decompress}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Beans.Tachyon, only: [tachyon_send: 2, tachyon_recv: 1, tachyon_recv_until: 1, new_connection: 1]
      alias Beans.Tachyon
    end
  end
end
