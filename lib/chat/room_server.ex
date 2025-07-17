defmodule Chat.RoomServer do
  use GenServer

  # Public API

  def start_link(room_id), do: GenServer.start_link(__MODULE__, %{}, name: via(room_id))

  defp via(room_id), do: {:via, Registry, {Chat.RoomRegistry, room_id}}

  def subscribe({room_id, user_id}),
    do: GenServer.call(via(room_id), {:subscribe, self(), user_id})

  def unsubscribe(room_id), do: GenServer.cast(via(room_id), {:unsubscribe, self()})

  def create_message(room_id, user_id, message),
    do: GenServer.cast(via(room_id), {:create_message, {user_id, message}})

  # Server callbacks

  @impl GenServer
  def init(_init_arg) do
    {:ok, %{messages: [], subscribers: %{}}}
  end

  @impl GenServer
  def handle_call({:subscribe, pid, user_id}, _from, state) do
    Process.monitor(pid)
    new_state = %{state | subscribers: Map.merge(state.subscribers, %{pid => user_id})}
    IO.inspect(new_state, label: "STATE AFTER SUBSCRIPTION")
    notify_users_update(state)
    {:reply, {:ok, {get_users(new_state), new_state.messages}}, new_state}
  end

  @impl GenServer
  def handle_cast({:create_message, {user_id, message}}, state) do
    new_messages = [{user_id, message} | state.messages]
    notify_messages_update(new_messages, Map.keys(state.subscribers))
    {:noreply, %{state | messages: new_messages}}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # IO.inspect(reason, label: "PROCESS DOWN, REASON")
    # IO.inspect(pid, label: "PID")
    # IO.inspect(state, label: "STATE")
    new_subscribers = Map.delete(state.subscribers, pid)
    new_state = put_in(state.subscribers, new_subscribers)
    IO.inspect(new_state, label: "NEW STATE")
    notify_users_update(new_state)
    {:noreply, new_state}
  end

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

  defp get_users(state), do: state.subscribers |> Map.values() |> Enum.uniq()
end
