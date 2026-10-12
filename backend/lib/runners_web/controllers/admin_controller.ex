defmodule RunnersWeb.AdminController do
  use RunnersWeb, :controller

  alias Runners.Admin
  alias Runners.Auth.Guardian

  action_fallback RunnersWeb.FallbackController

  def stats(conn, _params) do
    with {:ok, stats} <- Admin.stats(Guardian.Plug.current_resource(conn)) do
      json(conn, %{data: stats})
    end
  end
end
