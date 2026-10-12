defmodule RunnersWeb.AdminController do
  use RunnersWeb, :controller

  alias Runners.Admin
  alias Runners.Auth.Guardian

  action_fallback RunnersWeb.FallbackController

  def stats(conn, _params) do
    with {:ok, stats} <- Admin.stats(current_user(conn)) do
      json(conn, %{data: stats})
    end
  end

  def errands(conn, params) do
    with {:ok, tasks} <- Admin.list_errands(current_user(conn), params["scope"]) do
      conn
      |> put_view(json: RunnersWeb.TaskJSON)
      |> render(:index, tasks: tasks)
    end
  end

  def people(conn, params) do
    with {:ok, users} <- Admin.list_people(current_user(conn), params["role"]) do
      conn
      |> put_view(json: RunnersWeb.UserJSON)
      |> render(:index, users: users)
    end
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)
end
