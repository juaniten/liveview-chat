defmodule ChatWeb.RoomController do
  use ChatWeb, :controller
  import Phoenix.LiveView.Controller

  alias Chat.RoomServer

  def show(conn, %{"room_id" => room_id}) do
    if RoomServer.exists?(room_id) do
      # Render LiveView for the room
      live_render(conn, ChatWeb.Room,
        session: %{"room_id" => room_id, "username" => get_session(conn, :username)}
      )
    else
      conn
      |> put_flash(:error, "Room #{room_id} does not exist")
      |> redirect(to: "/lobby")
    end
  end
end
