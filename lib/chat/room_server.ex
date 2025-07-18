defmodule Chat.RoomServer do
  use GenServer

  # Public API

  def start_link(room_id), do: GenServer.start_link(__MODULE__, %{}, name: via(room_id))

  defp via(room_id), do: {:via, Registry, {Chat.RoomRegistry, room_id}}

  def subscribe({room_id, user_id}) do
    case Registry.lookup(Chat.RoomRegistry, room_id) do
      [{pid, _value}] -> GenServer.cast(pid, {:subscribe, self(), user_id})
      [] -> {:error, :room_not_found}
    end
  end

  def unsubscribe(room_id), do: GenServer.cast(via(room_id), {:unsubscribe, self()})

  def create_message(room_id, user_id, message),
    do: GenServer.cast(via(room_id), {:create_message, {user_id, message}})

  # Server callbacks

  @impl GenServer
  def init(_init_arg), do: {:ok, %{messages: [], subscribers: %{}}}

  @impl GenServer
  def handle_cast({:subscribe, pid, user_id}, state) do
    Process.monitor(pid)
    new_state = %{state | subscribers: Map.merge(state.subscribers, %{pid => user_id})}
    notify_users_update(new_state)
    send(pid, {:messages_updated, new_state.messages})

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:unsubscribe, pid}, state) do
    new_state = %{state | subscribers: MapSet.delete(state.subscribers, pid)}
    notify_users_update(new_state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_cast({:create_message, {user_id, message}}, state) do
    new_messages = state.messages ++ [{user_id, message}]
    notify_messages_update(new_messages, Map.keys(state.subscribers))
    {:noreply, %{state | messages: new_messages}}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    new_subscribers = Map.delete(state.subscribers, pid)
    new_state = put_in(state.subscribers, new_subscribers)
    notify_users_update(new_state)
    {:noreply, new_state}
  end

  # Notifications

  defp notify_users_update(state) do
    subscribers = state.subscribers |> Map.keys()

    Enum.each(subscribers, fn pid ->
      send(pid, {:users_updated, get_users(state)})
    end)
  end

  defp notify_messages_update(messages, subscribers) do
    Enum.each(subscribers, fn pid ->
      send(pid, {:messages_updated, messages})
    end)
  end

  defp notify_chat(from_user_id, subscribers, to_user_id) do
    subscribers
    |> Enum.filter(fn {_pid, user_id} -> user_id == to_user_id end)
    |> Map.keys()
    |> Enum.each(fn pid -> send(pid, {:notification, from_user_id}) end)
  end

  defp get_users(state), do: state.subscribers |> Map.values() |> Enum.uniq()
end
