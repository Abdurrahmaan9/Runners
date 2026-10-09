defmodule Runners.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RunnersWeb.Telemetry,
      Runners.Repo,
      {DNSCluster, query: Application.get_env(:runners, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Runners.PubSub},
      {Redix, {redis_url(), [name: Runners.Redis]}},
      RunnersWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Runners.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RunnersWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp redis_url do
    Application.get_env(:runners, :redis_url, "redis://localhost:6379/0")
  end
end
