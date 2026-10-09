defmodule RunnersWeb.HealthController do
  use RunnersWeb, :controller

  def show(conn, _params) do
    json(conn, %{data: %{status: "ok"}})
  end
end
