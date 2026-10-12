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

  defp count_posted_today do
    start = start_of_lusaka_day_utc()

    Repo.one(from task in Task, where: task.inserted_at >= ^start, select: count(task.id))
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

  defp count_status(status) do
    Repo.one(from task in Task, where: task.status == ^status, select: count(task.id))
  end

  defp count_active_errands do
    Repo.one(
      from task in Task,
        where: task.status in [:assigned, :runner_arrived, :in_progress],
        select: count(task.id)
    )
  end

  defp start_of_lusaka_day_utc do
    lusaka_now = DateTime.add(DateTime.utc_now(), @lusaka_offset_seconds, :second)
    date = DateTime.to_date(lusaka_now)

    date
    |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    |> DateTime.add(-@lusaka_offset_seconds, :second)
  end
end
