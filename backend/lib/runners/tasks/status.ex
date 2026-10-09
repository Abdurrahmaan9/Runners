defmodule Runners.Tasks.Status do
  @moduledoc """
  Allowed task lifecycle moves.

  `posted -> assigned` happens through task acceptance.
  `cancelled` is reached through the cancel action.
  Runners advance the remaining states one step at a time.
  """

  @statuses [:posted, :assigned, :runner_arrived, :in_progress, :completed, :cancelled]

  @transitions %{
    posted: [:assigned, :cancelled],
    assigned: [:runner_arrived, :cancelled],
    runner_arrived: [:in_progress, :cancelled],
    in_progress: [:completed, :cancelled],
    completed: [],
    cancelled: []
  }

  @runner_advances [:runner_arrived, :in_progress, :completed]

  def statuses, do: @statuses
  def runner_advances, do: @runner_advances

  def valid_transition?(from, to) when is_atom(from) and is_atom(to) do
    to in Map.get(@transitions, from, [])
  end

  def valid_transition?(_, _), do: false

  def parse(status) when is_atom(status) do
    if status in @statuses, do: {:ok, status}, else: :error
  end

  def parse(status) when is_binary(status) do
    case Enum.find(@statuses, &(Atom.to_string(&1) == status)) do
      nil -> :error
      parsed -> {:ok, parsed}
    end
  end

  def parse(_status), do: :error
end
