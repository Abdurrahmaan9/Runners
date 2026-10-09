defmodule RunnersWeb.TaskJSON do
  @moduledoc false

  alias Runners.Accounts.User
  alias Runners.Geospatial.Point
  alias Runners.Tasks.Task

  def index(%{tasks: tasks}) do
    %{data: Enum.map(tasks, &data/1)}
  end

  def show(%{task: task}) do
    %{data: data(task)}
  end

  def data(%Task{} = task) do
    %{
      id: task.id,
      requester_id: task.requester_id,
      runner_id: task.runner_id,
      requester: party(task.requester),
      runner: party(task.runner),
      title: task.title,
      description: task.description,
      task_type: task.task_type,
      status: task.status,
      pickup_address: task.pickup_address,
      pickup_location: Point.to_map(task.pickup_location),
      dropoff_address: task.dropoff_address,
      dropoff_location: Point.to_map(task.dropoff_location),
      estimated_cost: format_cost(task.estimated_cost),
      inserted_at: task.inserted_at,
      updated_at: task.updated_at
    }
  end

  defp party(%User{} = user) do
    %{id: user.id, full_name: user.full_name}
  end

  defp party(%Ecto.Association.NotLoaded{}), do: nil
  defp party(nil), do: nil

  defp format_cost(nil), do: nil
  defp format_cost(%Decimal{} = cost), do: Decimal.to_string(cost, :normal)
end
