defmodule Hailstorm.Spring.Commands do
  @moduledoc """

  """
  import Hailstorm.SpringHelper, only: [
    spring_send: 2,
    spring_recv: 1,
    spring_recv_until: 1,
    split_commands: 1
  ]
  alias Hailstorm.SpringHelper

  @spec send_dm(SpringHelper.sslsocket, String.t(), String.t()) :: :ok
  def send_dm(socket, target, message) do
    spring_send(socket, "SAYPRIVATE #{target} #{message}")
  end

  @spec add_friend(SpringHelper.sslsocket, String.t()) :: :ok
  def add_friend(socket, name) do
    spring_send(socket, "FRIENDREQUEST userName=#{name}")
  end

  @spec accept_friend(SpringHelper.sslsocket, String.t()) :: :ok
  def accept_friend(socket, name) do
    spring_send(socket, "ACCEPTFRIENDREQUEST userName=#{name}")
  end

  @spec decline_friend(SpringHelper.sslsocket, String.t()) :: :ok
  def decline_friend(socket, name) do
    spring_send(socket, "DECLINEFRIENDREQUEST userName=#{name}")
  end

  @spec remove_friend(SpringHelper.sslsocket, String.t()) :: :ok
  def remove_friend(socket, name) do
    spring_send(socket, "UNFRIEND userName=#{name}")
  end

  @spec get_friend_names(SpringHelper.sslsocket) :: [String.t()]
  def get_friend_names(socket) do
    spring_recv_until(socket)

    spring_send(socket, "FRIENDLIST")

    spring_recv(socket)
      |> String.replace("FRIENDLISTBEGIN", "")
      |> String.replace("FRIENDLISTEND", "")
      |> String.trim()
      |> String.split("\n")
      |> Enum.reject(fn r -> r == "" end)
      |> Enum.map(fn line ->
        "FRIENDLIST userName=" <> name = line
        String.trim(name)
      end)
  end

  @spec get_friend_request_names(SpringHelper.sslsocket) :: [String.t()]
  def get_friend_request_names(socket) do
    spring_recv_until(socket)

    spring_send(socket, "FRIENDREQUESTLIST")

    spring_recv_until(socket)
      |> String.replace("FRIENDREQUESTLISTBEGIN", "")
      |> String.replace("FRIENDREQUESTLISTEND", "")
      |> String.trim()
      |> String.split("\n")
      |> Enum.reject(fn r -> r == "" end)
      |> Enum.map(fn line ->
        "FRIENDREQUESTLIST userName=" <> name = line
        String.trim(name)
      end)
  end

  def send_lobby_message(socket, message) do
    spring_send(socket, "SAYBATTLE #{message}")
  end

  @spec open_lobby(SpringHelper.sslsocket, String.t()) :: non_neg_integer()
  @spec open_lobby(SpringHelper.sslsocket, String.t(), list()) :: non_neg_integer()
  def open_lobby(socket, username, opts \\ []) do
    name = opts[:name] || "#{username} lobby"
    map_name = "map-name-v1"

    msg = "OPENBATTLE 0 0 empty 52200 16 -1540855590 0 1565299817 spring\t104.0.1-1784-gf6173b4 BAR\t#{map_name}\t#{name}\tBeyond All Reason test-15658-85bf66d"
    spring_send(socket, msg)

    messages = socket
      |> spring_recv_until
      |> split_commands

    {_cmd, args} = messages
      |> Enum.filter(fn {cmd, args} ->
        cmd == "BATTLEOPENED"
        or Enum.at(args, 3) == "bad_command_host_hailstorm"
        or Enum.at(args, 13) == "consul-command-test-bad-commands"
      end)
      |> hd

    lobby_id = args
      |> hd
      |> String.to_integer

    lobby_id
  end

  @spec join_lobby(SpringHelper.sslsocket, String.t(), SpringHelper.sslsocket, non_neg_integer()) :: true
  def join_lobby(user_socket, username, host_socket, lobby_id) do
    spring_send(user_socket, "JOINBATTLE #{lobby_id} empty script_password")
    spring_send(host_socket, "JOINBATTLEACCEPT #{username}")

    joined_battle_line = user_socket
      |> spring_recv_until
      |> split_commands
      |> Map.new
      |> Map.get("JOINEDBATTLE")

    lobby_id_str = to_string(lobby_id)

    case joined_battle_line do
      [^lobby_id_str, ^username, "script_password"] ->
        true
      v ->
        raise "Battle join failed: #{inspect v}"
    end
  end
end
