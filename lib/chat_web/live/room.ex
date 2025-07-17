defmodule ChatWeb.Room do
  use ChatWeb, :live_view

  alias Chat.RoomServer

  def mount(params, session, socket) do
    # IO.puts("MOUNT ROOM----------------------")
    # IO.inspect(params, label: "params")
    # IO.inspect(socket, label: "socket")
    # IO.puts("----------------------")
    room_id = params["room_id"]
    user_id = session["username"]
    # if connected?(socket)
    {:ok, {users, messages}} = RoomServer.subscribe({room_id, user_id})

    {:ok,
     assign(socket,
       room_id: room_id,
       users: users,
       messages: messages,
       user_id: user_id
     )}
  end

  def handle_event("send_message", %{"message" => ""}, socket),
    do: {:noreply, socket}

  def handle_event("send_message", %{"message" => message}, socket) do
    :ok = RoomServer.create_message(socket.assigns.room_id, socket.assigns.user_id, message)
    {:noreply, clear_flash(socket)}
  end

  def handle_info({:users_updated, users}, socket), do: {:noreply, assign(socket, users: users)}

  def handle_info({:messages_updated, messages}, socket),
    do: {:noreply, assign(socket, messages: messages)}
end
