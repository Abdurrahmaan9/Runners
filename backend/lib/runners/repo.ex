defmodule Runners.Repo do
  use Ecto.Repo,
    otp_app: :runners,
    adapter: Ecto.Adapters.Postgres
end
