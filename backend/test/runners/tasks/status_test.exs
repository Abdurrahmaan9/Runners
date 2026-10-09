defmodule Runners.Tasks.StatusTest do
  use ExUnit.Case, async: true

  alias Runners.Tasks.Status

  test "allows the runner progress path one step at a time" do
    assert Status.valid_transition?(:posted, :assigned)
    assert Status.valid_transition?(:assigned, :runner_arrived)
    assert Status.valid_transition?(:runner_arrived, :in_progress)
    assert Status.valid_transition?(:in_progress, :completed)
  end

  test "rejects skipped and terminal transitions" do
    refute Status.valid_transition?(:posted, :in_progress)
    refute Status.valid_transition?(:completed, :cancelled)
    refute Status.valid_transition?(:cancelled, :posted)
  end

  test "parses known status strings" do
    assert Status.parse("runner_arrived") == {:ok, :runner_arrived}
    assert Status.parse("nope") == :error
  end
end
