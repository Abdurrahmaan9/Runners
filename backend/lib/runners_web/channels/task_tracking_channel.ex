defmodule RunnersWeb.TaskTrackingChannel do
  @moduledoc """
  Topic `task_tracking:<task_id>`.

  While a task is `in_progress`, the assigned runner pushes `location` events.
  The requester, who is joined to the same topic, receives `runner_location`.
  """

  use RunnersWeb, :channel

  alias Runners.Geospatial
  alias Runners.Tasks
  alias Runners.Tasks.Task

  @impl true
  def join("task_tracking:" <> task_id, _payload, socket) do
    user = socket.assigns.current_user

    case Tasks.fetch_task(task_id) do
      {:ok, task} ->
        if participant?(task, user) do
          {:ok, assign(socket, :task_id, task.id)}
        else
          {:error, %{code: "FORBIDDEN", message: "You are not a participant on this task"}}
        end

      {:error, :task_not_found} ->
        {:error, %{code: "NOT_FOUND", message: "Task does not exist"}}
    end
  end

  @impl true
  def handle_in("location", payload, socket) when is_map(payload) do
    user = socket.assigns.current_user

    with {:ok, task} <- Tasks.fetch_task(socket.assigns.task_id),
         :ok <- ensure_streaming_runner(task, user),
         {:ok, %{lat: lat, lng: lng}} <-
           Geospatial.record_location(user, payload["lat"], payload["lng"]) do
      broadcast_from!(socket, "runner_location", %{
        task_id: task.id,
        runner_id: user.id,
        lat: lat,
        lng: lng
      })

      {:reply, {:ok, %{lat: lat, lng: lng}}, socket}
    else
      {:error, :task_not_found} ->
        reply_error(socket, "NOT_FOUND", "Task does not exist")

      {:error, :forbidden} ->
        reply_error(socket, "FORBIDDEN", "Only the assigned runner can stream location")

      {:error, :invalid_status} ->
        reply_error(
          socket,
          "INVALID_TRANSITION",
          "Location streaming is only available while the task is in progress"
        )

      {:error, :runner_offline} ->
        reply_error(socket, "CONFLICT", "Runner must be online to publish location")

      _error ->
        reply_error(socket, "VALIDATION_ERROR", "lat and lng must be valid coordinates")
    end
  end

  defp participant?(%Task{requester_id: id}, %{id: id}), do: true
  defp participant?(%Task{runner_id: id}, %{id: id}) when not is_nil(id), do: true
  defp participant?(_task, %{role: :admin}), do: true
  defp participant?(_task, _user), do: false

  defp ensure_streaming_runner(%Task{status: :in_progress, runner_id: id}, %{id: id}), do: :ok

  defp ensure_streaming_runner(%Task{runner_id: id}, %{id: id}), do: {:error, :invalid_status}

  defp ensure_streaming_runner(_task, _user), do: {:error, :forbidden}

  defp reply_error(socket, code, message) do
    {:reply, {:error, %{code: code, message: message}}, socket}
  end
end
