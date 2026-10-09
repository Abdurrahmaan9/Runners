defmodule Runners.Tasks do
  @moduledoc """
  Task creation, listing, and lifecycle transitions.
  """

  import Ecto.Query, warn: false

  alias Runners.Accounts.User
  alias Runners.Geospatial.Point
  alias Runners.Repo
  alias Runners.Tasks.Status
  alias Runners.Tasks.Task

  def list_tasks(%User{} = user, opts \\ []) do
    user
    |> task_scope(opts)
    |> maybe_filter_status(opts[:status], user)
    |> order_by([task], desc: task.inserted_at)
    |> Repo.all()
    |> Repo.preload([:requester, :runner])
  end

  def fetch_task(id) do
    with {:ok, uuid} <- Ecto.UUID.cast(id),
         %Task{} = task <- Repo.get(Task, uuid) do
      {:ok, Repo.preload(task, [:requester, :runner])}
    else
      _ -> {:error, :task_not_found}
    end
  end

  def create_task(%User{} = requester, attrs) do
    with {:ok, attrs} <- put_locations(attrs, ["pickup_location", "dropoff_location"]) do
      %Task{}
      |> Task.changeset(attrs)
      |> Ecto.Changeset.put_change(:requester_id, requester.id)
      |> Ecto.Changeset.put_change(:status, :posted)
      |> Repo.insert()
      |> preload_parties()
    end
  end

  def update_task(%Task{} = task, %User{} = user, attrs) do
    cond do
      task.requester_id != user.id ->
        {:error, :forbidden}

      task.status != :posted ->
        {:error, :invalid_transition}

      true ->
        with {:ok, attrs} <- put_locations(attrs, ["pickup_location", "dropoff_location"]) do
          task
          |> Task.changeset(attrs)
          |> Repo.update()
          |> preload_parties()
        end
    end
  end

  def delete_task(%Task{} = task, %User{} = user) do
    cond do
      task.requester_id != user.id ->
        {:error, :forbidden}

      task.status != :posted ->
        {:error, :invalid_transition}

      true ->
        case Repo.delete(task) do
          {:ok, _task} -> :ok
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  @doc """
  First online-style claim wins. A conditional update locks `posted` tasks.
  """
  def accept_task(task_id, %User{role: :runner} = runner) do
    with {:ok, uuid} <- Ecto.UUID.cast(task_id) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      query =
        from task in Task,
          where:
            task.id == ^uuid and task.status == :posted and is_nil(task.runner_id) and
              task.requester_id != ^runner.id

      case Repo.update_all(query, set: [status: :assigned, runner_id: runner.id, updated_at: now]) do
        {1, _} ->
          fetch_task(uuid)

        {0, _} ->
          accept_failure(uuid)
      end
    else
      :error -> {:error, :task_not_found}
    end
  end

  def accept_task(_task_id, %User{}), do: {:error, :forbidden}

  def advance_task(%Task{} = task, %User{} = user, new_status) do
    with {:ok, new_status} <- parse_status(new_status),
         :ok <- ensure_assigned_runner(task, user),
         :ok <- ensure_runner_advance(new_status),
         :ok <- ensure_transition(task.status, new_status) do
      task
      |> Ecto.Changeset.change(status: new_status)
      |> Repo.update()
      |> preload_parties()
    end
  end

  def cancel_task(%Task{} = task, %User{} = user) do
    cond do
      not can_cancel?(task, user) ->
        {:error, :forbidden}

      not Status.valid_transition?(task.status, :cancelled) ->
        {:error, :invalid_transition}

      true ->
        task
        |> Ecto.Changeset.change(status: :cancelled)
        |> Repo.update()
        |> preload_parties()
    end
  end

  def visible?(%Task{}, %User{role: :admin}), do: true
  def visible?(%Task{requester_id: id}, %User{id: id}), do: true
  def visible?(%Task{runner_id: id}, %User{id: id}) when not is_nil(id), do: true
  def visible?(%Task{status: :posted}, %User{role: :runner}), do: true
  def visible?(_task, _user), do: false

  defp task_scope(%User{role: :admin}, _opts), do: Task

  defp task_scope(%User{role: :requester, id: id}, _opts) do
    from task in Task, where: task.requester_id == ^id
  end

  defp task_scope(%User{role: :runner, id: id}, opts) do
    if opts[:status] == :posted do
      from task in Task,
        where: task.status == :posted and task.requester_id != ^id
    else
      from task in Task,
        where: task.runner_id == ^id or task.requester_id == ^id
    end
  end

  defp maybe_filter_status(query, nil, _user), do: query
  defp maybe_filter_status(query, :posted, %User{role: :runner}), do: query

  defp maybe_filter_status(query, status, _user) when is_atom(status) do
    from task in query, where: task.status == ^status
  end

  defp accept_failure(uuid) do
    case Repo.get(Task, uuid) do
      nil -> {:error, :task_not_found}
      %Task{status: :posted} -> {:error, :conflict}
      %Task{} -> {:error, :invalid_transition}
    end
  end

  defp parse_status(status) do
    case Status.parse(status) do
      {:ok, parsed} -> {:ok, parsed}
      :error -> {:error, :invalid_transition}
    end
  end

  defp ensure_assigned_runner(%Task{runner_id: runner_id}, %User{id: runner_id, role: :runner}),
    do: :ok

  defp ensure_assigned_runner(_task, _user), do: {:error, :forbidden}

  defp ensure_runner_advance(status) when status in [:runner_arrived, :in_progress, :completed],
    do: :ok

  defp ensure_runner_advance(_status), do: {:error, :invalid_transition}

  defp ensure_transition(from, to) do
    if Status.valid_transition?(from, to), do: :ok, else: {:error, :invalid_transition}
  end

  defp can_cancel?(%Task{}, %User{role: :admin}), do: true
  defp can_cancel?(%Task{requester_id: id}, %User{id: id}), do: true

  defp can_cancel?(%Task{runner_id: id}, %User{id: id, role: :runner}) when not is_nil(id),
    do: true

  defp can_cancel?(_task, _user), do: false

  defp put_locations(attrs, keys) do
    attrs = stringify_keys(attrs)

    Enum.reduce_while(keys, {:ok, attrs}, fn key, {:ok, attrs} ->
      if Map.has_key?(attrs, key) do
        case Point.parse(Map.get(attrs, key)) do
          {:ok, point} -> {:cont, {:ok, Map.put(attrs, key, point)}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      else
        {:cont, {:ok, attrs}}
      end
    end)
  end

  defp stringify_keys(attrs) when is_map(attrs) do
    Map.new(attrs, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp preload_parties({:ok, task}), do: {:ok, Repo.preload(task, [:requester, :runner])}
  defp preload_parties(other), do: other
end
