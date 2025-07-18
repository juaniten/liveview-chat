defmodule ChatWeb.Room do
  use ChatWeb, :live_view

  alias Chat.RoomServer

  def mount(params, session, socket) do
    room_id = params["room_id"]
    user_id = session["username"]
    RoomServer.subscribe({room_id, user_id})

    {:ok,
     assign(socket,
       page_title: "Room #{room_id}",
       room_id: room_id,
       notifications: [],
       users: [],
       messages: [],
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

  def handle_info({:notification, from_user_id}, socket) do
    {:noreply, assign(socket, notifications: socket.assigns.notifications ++ [from_user_id])}
  end
end
