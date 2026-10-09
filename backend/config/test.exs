import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :runners, Runners.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT") || "5432"),
  database: "runners_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :runners, RunnersWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Xy5tzL+OiyX+6AbBolLShl2I3EWKVimhhezJqEehXeSJ3Ug2wWm7JzOPuOsGFOWj",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Persist every GPS ping during tests so nearby queries see the latest point.
config :runners, :location_sync_interval_seconds, 0
config :runners, :redis_url, System.get_env("REDIS_URL", "redis://localhost:6379/1")

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
