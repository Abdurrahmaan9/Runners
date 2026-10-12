defmodule RunnersWeb.AdminController do
  use RunnersWeb, :controller

  alias Runners.Admin
  alias Runners.Auth.Guardian
  alias RunnersWeb.UserJSON

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

  def heatmap(conn, _params) do
    with {:ok, map} <- Admin.heatmap(current_user(conn)) do
      json(conn, %{data: map})
    end
  end

  def people(conn, params) do
    with {:ok, users} <- Admin.list_people(current_user(conn), params["role"]) do
      conn
      |> put_view(json: UserJSON)
      |> render(:index, users: users)
    end
  end

  def create_person(conn, params) do
    with {:ok, user} <- Admin.create_person(current_user(conn), params) do
      conn
      |> put_status(:created)
      |> put_view(json: UserJSON)
      |> render(:show, user: user)
    end
  end

  def show_person(conn, %{"id" => id}) do
    with {:ok, user} <- Admin.get_person(current_user(conn), id) do
      conn
      |> put_view(json: UserJSON)
      |> render(:show, user: user)
    end
  end

  def update_person(conn, %{"id" => id} = params) do
    attrs =
      params
      |> Map.delete("id")
      |> drop_blank_password()

    with {:ok, user} <- Admin.update_person(current_user(conn), id, attrs) do
      conn
      |> put_view(json: UserJSON)
      |> render(:show, user: user)
    end
  end

  def block_person(conn, %{"id" => id}) do
    with {:ok, user} <- Admin.set_person_blocked(current_user(conn), id, true) do
      conn
      |> put_view(json: UserJSON)
      |> render(:show, user: user)
    end
  end

  def unblock_person(conn, %{"id" => id}) do
    with {:ok, user} <- Admin.set_person_blocked(current_user(conn), id, false) do
      conn
      |> put_view(json: UserJSON)
      |> render(:show, user: user)
    end
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)

  defp drop_blank_password(%{"password" => password} = attrs) when password in [nil, ""] do
    Map.delete(attrs, "password")
  end

  defp drop_blank_password(attrs), do: attrs
end
