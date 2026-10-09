defmodule Runners.Tasks.Task do
  @moduledoc """
  An errand posted by a requester and optionally claimed by a runner.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Runners.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @task_types [:store_pickup, :delivery, :home_chore]
  @max_cost Decimal.new("10000000")

  schema "tasks" do
    field :title, :string
    field :description, :string
    field :task_type, Ecto.Enum, values: @task_types
    field :status, Ecto.Enum, values: Runners.Tasks.Status.statuses(), default: :posted
    field :pickup_address, :string
    field :pickup_location, Geo.PostGIS.Geometry
    field :dropoff_address, :string
    field :dropoff_location, Geo.PostGIS.Geometry
    field :estimated_cost, :decimal

    belongs_to :requester, User
    belongs_to :runner, User

    timestamps(type: :utc_datetime)
  end

  def task_types, do: @task_types

  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :task_type,
      :pickup_address,
      :pickup_location,
      :dropoff_address,
      :dropoff_location,
      :estimated_cost
    ])
    |> validate_required([
      :title,
      :description,
      :task_type,
      :pickup_address,
      :dropoff_address,
      :dropoff_location,
      :estimated_cost
    ])
    |> update_change(:title, &trim/1)
    |> update_change(:description, &trim/1)
    |> update_change(:pickup_address, &trim/1)
    |> update_change(:dropoff_address, &trim/1)
    |> validate_length(:title, min: 3, max: 140)
    |> validate_length(:description, min: 1, max: 5_000)
    |> validate_length(:pickup_address, min: 3, max: 300)
    |> validate_length(:dropoff_address, min: 3, max: 300)
    |> validate_number(:estimated_cost,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: @max_cost
    )
    |> foreign_key_constraint(:requester_id)
    |> foreign_key_constraint(:runner_id)
  end

  defp trim(nil), do: nil
  defp trim(value) when is_binary(value), do: String.trim(value)
end
