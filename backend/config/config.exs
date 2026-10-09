# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :runners,
  ecto_repos: [Runners.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true],
  redis_url: "redis://localhost:6379/0",
  dispatch_radius_meters: 5_000,
  location_sync_interval_seconds: 30

config :runners, Runners.Repo, types: Runners.PostgresTypes

config :runners, Runners.Auth.Guardian,
  issuer: "runners",
  secret_key: "dev-only-change-before-any-real-deployment-runners-phase-1",
  ttl: {7, :days}

config :geo_postgis, json_library: Jason

# Configure the endpoint
config :runners, RunnersWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: RunnersWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Runners.PubSub,
  live_view: [signing_salt: "sDQrqgAT"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
