defmodule Chat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChatWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Chat.Finch},
      # Start a worker by calling: Chat.Worker.start_link(arg)
      # {Chat.Worker, arg},
      # Start to serve requests, typically the last entry

      {Registry, keys: :unique, name: Chat.RoomRegistry},
      Chat.RoomSupervisor,
      Chat.LobbyServer,
      # {DynamicSupervisor, name: Chat.Lobbyerver, strategy: :one_for_one},
      ChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
