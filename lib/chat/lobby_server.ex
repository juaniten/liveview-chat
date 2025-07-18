defmodule Chat.LobbyServer do
  use GenServer

  # Public API

  def start_link(_init_arg), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def subscribe(), do: GenServer.cast(Chat.LobbyServer, {:subscribe, self()})

  def create_room(name), do: GenServer.call(__MODULE__, {:create_room, name})

  # Server callbacks

  @impl GenServer
  def init(_init_arg) do
    state = %{
      rooms: [],
      subscribers: MapSet.new()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:subscribe, pid}, state) do
    Process.monitor(pid)
    notify_rooms_update(state.rooms, [pid])
    {:noreply, %{state | subscribers: MapSet.put(state.subscribers, pid)}}
  end

  @impl GenServer
  def handle_cast({:unsubscribe, pid}, state),
    do: {:noreply, %{state | subscribers: MapSet.delete(state.subscribers, pid)}}

  @impl GenServer
  def handle_call({:create_room, name}, _from, state) do
    case Chat.RoomSupervisor.start_room(name) do
      {:ok, _pid} ->
        rooms = [name | state.rooms]
        notify_rooms_update(rooms, state.subscribers)
        {:reply, :ok, %{state | rooms: rooms}}

      {:error, {:already_started, _pid}} ->
        {:reply, {:error, :already_exists}, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_subscribers = MapSet.delete(state.subscribers, pid)
    {:noreply, %{state | subscribers: new_subscribers}}
  end

  defp notify_rooms_update(rooms, subscribers) do
    Enum.each(subscribers, fn pid ->
      send(pid, {:rooms_updated, rooms})
    end)
  end
end
