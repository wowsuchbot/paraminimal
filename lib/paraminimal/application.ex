defmodule Paraminimal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ParaminimalWeb.Telemetry,
      Paraminimal.Repo,
      {DNSCluster, query: Application.get_env(:paraminimal, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Paraminimal.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Paraminimal.Finch},
      # Start a worker by calling: Paraminimal.Worker.start_link(arg)
      # {Paraminimal.Worker, arg},
      # Start to serve requests, typically the last entry
      ParaminimalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Paraminimal.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ParaminimalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
