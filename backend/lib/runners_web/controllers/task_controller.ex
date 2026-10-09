defmodule RunnersWeb.TaskController do
  use RunnersWeb, :controller

  alias Runners.Auth.Guardian
  alias Runners.Tasks
  alias Runners.Tasks.Status
  alias RunnersWeb.Realtime

  action_fallback RunnersWeb.FallbackController

  def index(conn, params) do
    user = current_user(conn)

    with {:ok, opts} <- list_opts(params) do
      tasks = Tasks.list_tasks(user, opts)
      render(conn, :index, tasks: tasks)
    end
  end

  def show(conn, %{"id" => id}) do
    user = current_user(conn)

    with {:ok, task} <- Tasks.fetch_task(id),
         :ok <- ensure_visible(task, user) do
      render(conn, :show, task: task)
    end
  end

  def create(conn, params) do
    with {:ok, task} <- Tasks.create_task(current_user(conn), params) do
      Realtime.broadcast_posted_task(task)

      conn
      |> put_status(:created)
      |> render(:show, task: task)
    end
  end

  def update(conn, %{"id" => id} = params) do
    attrs = Map.delete(params, "id")

    with {:ok, task} <- Tasks.fetch_task(id),
         {:ok, task} <- Tasks.update_task(task, current_user(conn), attrs) do
      Realtime.broadcast_task_updated(task)
      render(conn, :show, task: task)
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, task} <- Tasks.fetch_task(id),
         :ok <- Tasks.delete_task(task, current_user(conn)) do
      send_resp(conn, :no_content, "")
    end
  end

  def accept(conn, %{"id" => id}) do
    with {:ok, task} <- Tasks.accept_task(id, current_user(conn)) do
      Realtime.broadcast_task_updated(task)
      render(conn, :show, task: task)
    end
  end

  def update_status(conn, %{"id" => id, "status" => status}) do
    with {:ok, task} <- Tasks.fetch_task(id),
         {:ok, task} <- Tasks.advance_task(task, current_user(conn), status) do
      Realtime.broadcast_task_updated(task)
      render(conn, :show, task: task)
    end
  end

  def update_status(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RunnersWeb.ErrorJSON)
    |> render(:error, code: "VALIDATION_ERROR", message: "status is required")
  end

  def cancel(conn, %{"id" => id}) do
    with {:ok, task} <- Tasks.fetch_task(id),
         {:ok, task} <- Tasks.cancel_task(task, current_user(conn)) do
      Realtime.broadcast_task_updated(task)
      render(conn, :show, task: task)
    end
  end

  defp list_opts(params) do
    case params["status"] do
      nil ->
        {:ok, []}

      "" ->
        {:ok, []}

      status ->
        case Status.parse(status) do
          {:ok, parsed} -> {:ok, [status: parsed]}
          :error -> {:error, :invalid_status_filter}
        end
    end
  end

  defp ensure_visible(task, user) do
    if Tasks.visible?(task, user), do: :ok, else: {:error, :task_not_found}
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)
end
