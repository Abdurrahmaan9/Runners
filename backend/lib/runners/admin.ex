defmodule Runners.Admin do
  @moduledoc """
  System counts for the admin dashboard.

  "Today" is the calendar day in Lusaka, which stays UTC+2 all year.
  """

  import Ecto.Query, warn: false

  alias Runners.Accounts.RunnerProfile
  alias Runners.Accounts.User
  alias Runners.Repo
  alias Runners.Tasks.Task

  @lusaka_offset_seconds 2 * 60 * 60

  def stats(%User{role: :admin}) do
    {:ok,
     %{
       errands_posted_today: count_posted_today(),
       runners: count_role(:runner),
       active_runners: count_active_runners(),
       requesters: count_role(:requester),
       errands_open: count_status(:posted),
       errands_active: count_active_errands(),
       errands_completed: count_status(:completed)
     }}
  end

  def stats(%User{}), do: {:error, :forbidden}

  # Lusaka city box. Row 1 is the south edge; column 1 is the west edge.
  @south -15.55
  @north -15.25
  @west 28.15
  @east 28.45
  @rows 6
  @cols 8

  def heatmap(%User{role: :admin}) do
    cells =
      heatmap_cells()
      |> Enum.map(fn %{row: row, col: col, count: count} ->
        %{row: as_int(row), col: as_int(col), count: as_int(count)}
      end)

    {:ok, %{rows: @rows, cols: @cols, cells: cells}}
  end

  def heatmap(%User{}), do: {:error, :forbidden}

  @errand_scopes ["today", "open", "underway", "completed"]
  @people_roles ["runner", "requester"]

  def list_errands(%User{role: :admin}, scope) when scope in @errand_scopes do
    tasks =
      scope
      |> errand_query()
      |> order_by([task], desc: task.inserted_at)
      |> Repo.all()
      |> Repo.preload([:requester, :runner])

    {:ok, tasks}
  end

  def list_errands(%User{role: :admin}, _scope), do: {:error, :invalid_admin_scope}
  def list_errands(%User{}, _scope), do: {:error, :forbidden}

  def list_people(%User{role: :admin}, role) when role in @people_roles do
    role_atom = String.to_existing_atom(role)

    users =
      User
      |> where([user], user.role == ^role_atom)
      |> order_by([user], asc: user.full_name)
      |> Repo.all()
      |> Repo.preload(:runner_profile)

    {:ok, users}
  end

  def list_people(%User{role: :admin}, _role), do: {:error, :invalid_admin_role}
  def list_people(%User{}, _role), do: {:error, :forbidden}

  defp count_posted_today do
    Repo.one(from task in errand_query("today"), select: count(task.id))
  end

  defp count_role(role) do
    Repo.one(from user in User, where: user.role == ^role, select: count(user.id))
  end

  defp count_active_runners do
    Repo.one(
      from profile in RunnerProfile,
        join: user in assoc(profile, :user),
        where: profile.is_online == true and user.role == :runner,
        select: count(profile.id)
    )
  end

  defp count_status(:posted),
    do: Repo.one(from task in errand_query("open"), select: count(task.id))

  defp count_status(:completed),
    do: Repo.one(from task in errand_query("completed"), select: count(task.id))

  defp count_active_errands do
    Repo.one(from task in errand_query("underway"), select: count(task.id))
  end

  defp errand_query("today") do
    start = start_of_lusaka_day_utc()
    from task in Task, where: task.inserted_at >= ^start
  end

  defp errand_query("open") do
    from task in Task, where: task.status == :posted
  end

  defp errand_query("underway") do
    from task in Task, where: task.status in [:assigned, :runner_arrived, :in_progress]
  end

  defp errand_query("completed") do
    from task in Task, where: task.status == :completed
  end

  defp heatmap_cells do
    points =
      from task in Task,
        where: task.status != :cancelled and not is_nil(task.dropoff_location),
        select: %{
          row:
            fragment(
              "width_bucket(ST_Y(CAST(? AS geometry)), ?, ?, ?)",
              task.dropoff_location,
              ^@south,
              ^@north,
              ^@rows
            ),
          col:
            fragment(
              "width_bucket(ST_X(CAST(? AS geometry)), ?, ?, ?)",
              task.dropoff_location,
              ^@west,
              ^@east,
              ^@cols
            )
        }

    Repo.all(
      from point in subquery(points),
        where: point.row >= 1 and point.row <= ^@rows,
        where: point.col >= 1 and point.col <= ^@cols,
        group_by: [point.row, point.col],
        select: %{row: point.row, col: point.col, count: count()}
    )
  end

  defp as_int(value) when is_integer(value), do: value
  defp as_int(value), do: value |> to_string() |> String.to_integer()

  defp start_of_lusaka_day_utc do
    lusaka_now = DateTime.add(DateTime.utc_now(), @lusaka_offset_seconds, :second)
    date = DateTime.to_date(lusaka_now)

    date
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> DateTime.add(-@lusaka_offset_seconds, :second)
  end
end
