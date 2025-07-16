defmodule ChatWeb.Lobby do
  use ChatWeb, :live_view

  defp start_or_get_room(room_id) do
    case Registry.lookup(Clock.RoomRegistry, room_id) do
      [{pid, _}] ->
        {:ok, pid}

      [] ->
        DynamicSupervisor.start_child(
          ChatWeb.RoomSupervisor,
          {ChatWeb.Room, room_id}
        )
    end
  end
end
