defmodule Chat.Room do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  defp via_tuple(name), do: {:via, Registry, {Chat.RoomRegistry, name}}

  @impl GenServer
  def init(name) do
    {:ok, %{name: name, messages: []}}
  end
end
