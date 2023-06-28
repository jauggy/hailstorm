defmodule Hailstorm.TachyonHelper do
  require Logger
  alias Hailstorm.TachyonWsServer, as: Ws
  alias Hailstorm.ListenerServer

  @type sslsocket() :: {:sslsocket, any, any}

  @spec get_host() :: binary()
  def get_host(), do: Application.get_env(:hailstorm, Hailstorm)[:host]

  @spec get_websocket_url(String.t()) :: non_neg_integer()
  def get_websocket_url(token_value) do
    query = URI.encode_query(%{
      "token" => token_value,
      "application_hash" => "HailstormHash",
      "application_version" => "1.0.0",
      "application_name" => "Hailstorm"
    })
    Application.get_env(:hailstorm, Hailstorm)[:websocket_url] <> "?#{query}"
  end

  @spec get_password() :: String.t()
  def get_password(), do: Application.get_env(:hailstorm, Hailstorm)[:password]

  def cleanup_params(params) do
    params = params || %{}
    name = Map.get(params, :name, ExULID.ULID.generate()) |> to_string
    email = Map.get(params, :email, name) <> "@hailstorm_tachyon"

    Map.merge(params, %{
      name: name,
      email: email
    })
  end

  @spec new_connection(map()) :: {:ok, pid(), pid()} | {:error, String.t()}
  def new_connection(params \\ %{}) do
    params = cleanup_params(params)

    with :ok <- create_user(params),
      :ok <- update_user(params.email, Map.merge(%{verified: true}, params[:update] || %{
        friends: [],
        friend_requests: [],
        ignored: [],
        avoided: []
      })),
      {:ok, token} <- get_token(params),
      listener <- ListenerServer.new_listener(),
      {:ok, ws} <- get_socket(token, listener)
    do
      {:ok, {ws, listener}}
    else
      failure -> failure
    end
  end

  @spec get_socket(String.t(), pid()) :: {:ok, sslsocket()} | {:error, any}
  defp get_socket(token, listener) do
    Ws.start_link(get_websocket_url(token), listener)
  end

  @spec create_user(map()) :: :ok | {:error, String.t()}
  def create_user(params) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/create_user"
    ] |> Enum.join("/")

    unverified = Map.get(params, "unverified", false)

    roles = if unverified do
      params["roles"] || []
    else
      ["Verified" | params["roles"] || []] |> Enum.uniq
    end

    data = params
      |> Map.merge(%{
        password: get_password(),
        roles: roles
      })
      |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 201} = resp} ->
        resp.body |> Jason.decode!
      {_, resp} ->
        %{"result" => "failure", "reason" => "bad request (code: #{resp.status_code})"}
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error creating user #{params.email} because #{result["reason"]}"}
      %{"userid" => _userid} ->
        :ok
    end
  end

  @spec get_token(map()) :: {:ok, String.t()} | {:error, String.t()}
  def get_token(params) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/request_token"
    ] |> Enum.join("/")

    unverified = Map.get(params, "unverified", false)

    roles = if unverified do
      params["roles"] || []
    else
      ["Verified" | params["roles"] || []] |> Enum.uniq
    end

    data = params
      |> Map.merge(%{
        "password" => get_password(),
        "roles" => roles
      })
      |> Jason.encode!

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, resp} ->
        resp.body |> Jason.decode!
      {:error, _resp} ->
        %{"result" => "failure", "reason" => "bad request"}
    end

    case result do
      %{"result" => "failure", "reason" => reason} ->
        {:error, "Error requesting user token for '#{params.email}', because #{reason}"}
      %{"result" => "success", "token_value" => token_value} ->
        {:ok, token_value}
    end
  end

  @spec update_user(String.t(), map()) :: :ok | {:error, String.t()}
  def update_user(email, params) do
    url = [
      Application.get_env(:hailstorm, Hailstorm)[:host_web_url],
      "teiserver/api/hailstorm/ts_update_user"
    ] |> Enum.join("/")

    data = Jason.encode!(%{
      email: email,
      attrs: params
    })

    result = case HTTPoison.post(url, data, [{"Content-Type", "application/json"}]) do
      {:ok, resp} ->
        resp.body |> Jason.decode!
      {:error, _resp} ->
        %{"result" => "failure", "reason" => "bad request"}
    end

    case result do
      %{"result" => "failure"} ->
        {:error, "Error updating user #{email} at '#{result["stage"]}' because #{result["reason"]}"}
      %{"result" => "success"} ->
        :ok
    end
  end

  @spec tachyon_send_and_receive({pid, pid}, map) :: any
  def tachyon_send_and_receive(client, data) do
    tachyon_send_and_receive(client, data, fn _ -> true end, [])
  end

  @spec tachyon_send_and_receive({pid, pid}, map, function, list) :: any
  def tachyon_send_and_receive({ws, _ls} = client, data, filter_func, opts \\ []) do
    json = Jason.encode!(data)
    WebSockex.send_frame(ws, {:text, json})

    pop_messages(client, opts[:timeout] || 500)
      |> Enum.map(fn
        %{
          "command" => "system/error/response",
          "status" => "failure",
        } = m ->
          raise "Got error message: #{m["reason"]}"
        m ->
          m
      end)
      |> Enum.filter(filter_func)
  end

  @spec tachyon_receive({pid, pid}) :: any
  def tachyon_receive({_ws, _ls} = client) do
    tachyon_receive(client, (fn _ -> true end), [])
  end

  @spec tachyon_receive({pid, pid}, function, list) :: any
  def tachyon_receive({_ws, _ls} = client, filter_func, opts \\ []) do
    pop_messages(client, opts[:timeout] || 500)
      |> Enum.map(fn
        %{
          "command" => "system/error/response",
          "status" => "failure",
          "reason" => "No command of '" <> _
        } = m ->
          raise "Got error message: #{m["reason"]}"
        m ->
          m
      end)
      |> Enum.filter(filter_func)
  end

  def empty_messages(listeners) do
    listeners
    |> Enum.each(fn {_, ls} ->
      ListenerServer.pop(ls)
    end)
  end

  @spec tachyon_send({pid, pid}, map) :: :ok
  @spec tachyon_send({pid, pid}, map, list) :: :ok
  def tachyon_send({ws, _}, data, _metadata \\ []) do
    json = Jason.encode!(data)
    WebSockex.send_frame(ws, {:text, json})
  end

  @spec read_messages({pid, pid}) :: list
  def read_messages(client), do: read_messages(client, 500)

  @spec read_messages({pid, pid}, non_neg_integer()) :: list
  def read_messages({_ws, ls}, timeout) do
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
        result
    end
  end

  @spec pop_messages({pid, pid}) :: list
  def pop_messages(client), do: pop_messages(client, 500)

  @spec pop_messages({pid, pid}, non_neg_integer()) :: list
  def pop_messages({_ws, ls}, timeout) do
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
        result
    end
  end

  @spec validate!(map) :: :ok
  def validate!(%{"command" => command} = object) do
    # IO.puts "Object: "
    # IO.puts Jason.encode!(object, pretty: true)
    # IO.inspect command, label: "Command "
    # IO.inspect get_schema(command), label: "Schema "
    # IO.puts ""

    schema = get_schema(command)
    JsonXema.validate!(schema, object)
  end

  defp get_schema(command) do
    ConCache.get(:tachyon_schemas, command)
  end

  # Now for command shortcuts
  @spec whoami({pid, pid}) :: map()
  def whoami(client) do
    cmd_data = %{
      "command" => "account/whoAmI/request",
      "data" => %{}
    }

    messages = tachyon_send_and_receive(client, cmd_data, fn
      %{"command" => "account/whoAmI/response"} -> true
      _ -> false
    end)

    messages
      |> hd()
      |> Map.get("data")
  end

  @spec create_lobby({pid, pid}) :: map
  def create_lobby(client) do
    create_lobby(client, %{"name" => ExULID.ULID.generate()})
  end

  @spec create_lobby({pid, pid}, map) :: map
  def create_lobby(client, data) do
    lobby_data = Map.merge(%{
      "name" => ExULID.ULID.generate(),
      "type" => "normal",
      "nattype" => "none",
      "port" => 1234,
      "game_hash" => "hash-here",
      "map_hash" => "hash-here",
      "engine_name" => "",
      "engine_version" => "",
      "map_name" => "Best map ever",
      "game_name" => "bar-123",
      "locked" => false
    }, data)

    cmd_data = %{
      "command" => "lobbyHost/create/request",
      "data" => lobby_data
    }

    tachyon_send_and_receive(client, cmd_data, fn
      %{"command" => "lobbyHost/create/response"} -> true
      _ -> false
    end)
    |> hd
    |> Map.get("data")
  end

  @spec join_lobby({pid, pid}, {pid, pid}, non_neg_integer()) :: map
  def join_lobby(client, host, lobby_id) do
    client_id = whoami(client)["id"]

    # Join request
    cmd = %{
      "command" => "lobby/join/request",
      "data" => %{
        "lobby_id" => lobby_id
      }
    }
    client_messages = tachyon_send_and_receive(client, cmd, fn
      %{"command" => "lobby/join/response"} -> true
      _ -> false
    end)

    response = hd(client_messages)
    if response["data"]["result"] != "waiting_on_host" do
      raise "Tried joining lobby but did not get back waiting_on_host response"
    end

    # Host accept
    cmd = %{
      "command" => "lobbyHost/respondToJoinRequest/request",
      "data" => %{
        "userid" => client_id,
        "response" => "accept"
      }
    }
    tachyon_send_and_receive(host, cmd, fn
      _ -> false
    end)

    # And now the client should be a member
    client_messages = tachyon_receive(client, fn
      %{"command" => "lobby/joined/response"} -> true
      %{"command" => "user/UpdatedUserClient/response"} -> true
      %{"command" => "lobby/receivedJoinRequestResponse/response"} -> true
      _ -> false
    end)

    message_map = client_messages
      |> Map.new(fn %{"command" => command} = m ->
        {command, m}
      end)

    # The JoinRequest response should be here
    response = message_map["lobby/receivedJoinRequestResponse/response"]
    if response["data"]["result"] != "accept" do
      raise "Tried joining lobby but did not get host accept response"
    end

    # We should also be told we've joined a lobby
    response = message_map["lobby/joined/response"]
    if response["data"]["lobby_id"] != lobby_id do
      raise "Tried joining lobby but got wrong lobby (expected: #{lobby_id}, got: #{response["data"]["lobby_id"]})"
    end

    # And our client is now updated
    response = message_map["user/UpdatedUserClient/response"]
    if response["data"]["userClient"]["id"] != client_id do
      raise "Tried joining lobby but did not get a user client update"
    end

    # Empty host messages
    tachyon_receive(host)

    response["data"]["userClient"]
  end

  defmacro __using__(_opts) do
    quote do
      import Hailstorm.TachyonHelper, only: [
        tachyon_send: 2,
        tachyon_send_and_receive: 2,
        tachyon_send_and_receive: 3,
        tachyon_send_and_receive: 4,
        tachyon_receive: 1,
        tachyon_receive: 2,
        tachyon_receive: 3,
        read_messages: 1,
        read_messages: 2,
        pop_messages: 1,
        pop_messages: 2,
        new_connection: 0,
        new_connection: 1,
        validate!: 1,
        empty_messages: 1,

        # Commands
        whoami: 1,
        create_lobby: 1,
        create_lobby: 2,
        join_lobby: 3
      ]
      alias Hailstorm.TachyonHelper
      alias Tachyon
    end
  end
end
