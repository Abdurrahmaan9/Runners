defmodule RunnersWeb.Realtime do
  @moduledoc """
  Pushes task events to Phoenix channels after the database write commits.
  """

  alias Runners.Geospatial
  alias RunnersWeb.Endpoint
  alias RunnersWeb.TaskJSON

  require Logger

  def broadcast_posted_task(task) do
    case origin(task) do
      {lat, lng} ->
        radius = Application.get_env(:runners, :dispatch_radius_meters, 5_000)
        payload = %{task: TaskJSON.data(task)}

        task
        |> nearby_runners(lat, lng, radius)
        |> Enum.each(fn profile ->
          Endpoint.broadcast("task_dispatch:#{profile.user_id}", "task_posted", payload)
        end)

      nil ->
        :ok
    end
  end

  def broadcast_task_updated(task) do
    payload = %{task: TaskJSON.data(task)}
    Endpoint.broadcast("task_tracking:#{task.id}", "task_updated", payload)
    Endpoint.broadcast("task_dispatch:#{task.requester_id}", "task_updated", payload)

    if is_binary(task.runner_id) do
      Endpoint.broadcast("task_dispatch:#{task.runner_id}", "task_updated", payload)
    end

    :ok
  end

  defp nearby_runners(task, lat, lng, radius) do
    Geospatial.list_nearby_runners(lat, lng, radius)
  rescue
    exception ->
      Logger.error("nearby dispatch failed for task #{task.id}: #{Exception.message(exception)}")
      []
  end

  defp origin(%{pickup_location: %Geo.Point{coordinates: {lng, lat}}}), do: {lat, lng}
  defp origin(%{dropoff_location: %Geo.Point{coordinates: {lng, lat}}}), do: {lat, lng}
  defp origin(_task), do: nil
end
