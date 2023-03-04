defmodule Beans.Spring.Commands do
  @moduledoc """

  """
  import Beans.SpringHelper, only: [
    spring_send: 2,
    spring_recv: 1,
    spring_recv_until: 1
  ]

  @spec send_dm(Beans.SpringHelper.sslsocket, String.t(), String.t()) :: :ok
  def send_dm(socket, target, message) do
    spring_send(socket, "SAYPRIVATE #{target} #{message}")
  end

  @spec add_friend(Beans.SpringHelper.sslsocket, String.t()) :: :ok
  def add_friend(socket, name) do
    spring_send(socket, "FRIENDREQUEST userName=#{name}")
  end

  @spec accept_friend(Beans.SpringHelper.sslsocket, String.t()) :: :ok
  def accept_friend(socket, name) do
    spring_send(socket, "ACCEPTFRIENDREQUEST userName=#{name}")
  end

  @spec decline_friend(Beans.SpringHelper.sslsocket, String.t()) :: :ok
  def decline_friend(socket, name) do
    spring_send(socket, "DECLINEFRIENDREQUEST userName=#{name}")
  end

  @spec remove_friend(Beans.SpringHelper.sslsocket, String.t()) :: :ok
  def remove_friend(socket, name) do
    spring_send(socket, "UNFRIEND userName=#{name}")
  end

  @spec get_friend_names(Beans.SpringHelper.sslsocket) :: [String.t()]
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

  @spec get_friend_request_names(Beans.SpringHelper.sslsocket) :: [String.t()]
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
end
