defmodule ChatWeb.Lobby do
  use ChatWeb, :live_view

  def mount(_params, session, socket) do
    Chat.LobbyServer.subscribe()
    {:ok, assign(socket, page_title: "Lobby", rooms: [], username: session["username"])}
  end

  def handle_event("create_room", %{"room" => ""}, socket),
    do: {:noreply, put_flash(socket, :error, "Room name cannot be empty")}

  def handle_event("create_room", %{"room" => name}, socket) do
    case Chat.LobbyServer.create_room(name) do
      :ok ->
        {:noreply, clear_flash(socket)}

      {:error, :already_exists} ->
        {:noreply, put_flash(socket, :error, "That room already exists")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Room creation failed")}
    end
  end

  def handle_info({:rooms_updated, rooms}, socket), do: {:noreply, assign(socket, rooms: rooms)}
end
