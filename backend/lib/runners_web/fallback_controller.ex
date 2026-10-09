defmodule RunnersWeb.FallbackController do
  @moduledoc false

  use RunnersWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RunnersWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :task_not_found}) do
    render_error(conn, :not_found, "NOT_FOUND", "Task does not exist")
  end

  def call(conn, {:error, :runner_profile_not_found}) do
    render_error(conn, :not_found, "NOT_FOUND", "Runner profile does not exist")
  end

  def call(conn, {:error, :not_found}) do
    render_error(conn, :not_found, "NOT_FOUND", "Resource does not exist")
  end

  def call(conn, {:error, :invalid_credentials}) do
    render_error(conn, :unauthorized, "UNAUTHORIZED", "No account exists for this phone number")
  end

  def call(conn, {:error, :forbidden}) do
    render_error(conn, :forbidden, "FORBIDDEN", "You are not allowed to perform this action")
  end

  def call(conn, {:error, :conflict}) do
    render_error(conn, :conflict, "CONFLICT", "Task was already accepted")
  end

  def call(conn, {:error, :invalid_transition}) do
    render_error(conn, :conflict, "INVALID_TRANSITION", "Task cannot move to that status")
  end

  def call(conn, {:error, :invalid_status_filter}) do
    render_error(
      conn,
      :unprocessable_entity,
      "VALIDATION_ERROR",
      "status is not a valid task status"
    )
  end

  def call(conn, {:error, :invalid_coordinates}) do
    render_error(
      conn,
      :unprocessable_entity,
      "VALIDATION_ERROR",
      "Coordinates are out of bounds or missing"
    )
  end

  def call(conn, {:error, :invalid_radius}) do
    render_error(
      conn,
      :unprocessable_entity,
      "VALIDATION_ERROR",
      "radius_in_meters must be a whole number between 1 and 50000"
    )
  end

  def call(conn, {:error, :runner_offline}) do
    render_error(conn, :conflict, "CONFLICT", "Runner must be online to publish location")
  end

  def call(conn, {:error, :invalid_online_flag}) do
    render_error(
      conn,
      :unprocessable_entity,
      "VALIDATION_ERROR",
      "is_online must be true or false"
    )
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> put_view(json: RunnersWeb.ErrorJSON)
    |> render(:error, code: code, message: message)
  end
end
