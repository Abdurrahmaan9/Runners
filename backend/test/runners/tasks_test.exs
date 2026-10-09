defmodule Runners.TasksTest do
  use Runners.DataCase, async: true

  alias Runners.Tasks

  test "create_task stores posted work for a requester" do
    requester = register_user!(%{role: "requester"})
    runner = register_user!(%{role: "runner"})

    task = create_task!(requester)

    assert task.status == :posted
    assert task.requester_id == requester.id
    assert task.runner_id == nil
    assert %{lat: -15.43, lng: 28.35} == Runners.Geospatial.Point.to_map(task.dropoff_location)

    assert {:ok, own} = Tasks.create_task(runner, task_attrs(%{"title" => "Runner errand"}))
    assert own.requester_id == runner.id
    assert own.status == :posted

    posted = Tasks.list_tasks(runner, status: :posted)
    assert Enum.any?(posted, &(&1.id == task.id))
    refute Enum.any?(posted, &(&1.id == own.id))
    assert Enum.any?(Tasks.list_tasks(runner), &(&1.id == own.id))
  end

  test "accept_task locks the task for the first runner" do
    requester = register_user!()
    first = register_user!(%{role: "runner"})
    second = register_user!(%{role: "runner"})
    task = create_task!(requester)

    assert {:ok, accepted} = Tasks.accept_task(task.id, first)
    assert accepted.status == :assigned
    assert accepted.runner_id == first.id

    assert Tasks.accept_task(task.id, second) == {:error, :invalid_transition}
  end

  test "advance_task follows the lifecycle and cancel stops it" do
    requester = register_user!()
    runner = register_user!(%{role: "runner"})
    task = create_task!(requester)
    {:ok, task} = Tasks.accept_task(task.id, runner)

    assert {:error, :invalid_transition} = Tasks.advance_task(task, runner, "in_progress")
    assert {:ok, task} = Tasks.advance_task(task, runner, "runner_arrived")
    assert {:ok, task} = Tasks.advance_task(task, runner, "in_progress")
    assert {:ok, task} = Tasks.advance_task(task, runner, "completed")
    assert Tasks.cancel_task(task, requester) == {:error, :invalid_transition}
  end

  test "only the requester can edit or delete a posted task" do
    requester = register_user!()
    other = register_user!()
    task = create_task!(requester)

    assert {:ok, updated} =
             Tasks.update_task(task, requester, %{"title" => "Pick up medicine"})

    assert updated.title == "Pick up medicine"
    assert Tasks.update_task(task, other, %{"title" => "Nope"}) == {:error, :forbidden}
    assert :ok = Tasks.delete_task(updated, requester)
    assert Tasks.fetch_task(task.id) == {:error, :task_not_found}
  end

  test "rejects out of bounds coordinates" do
    requester = register_user!()

    assert {:error, :invalid_coordinates} =
             Tasks.create_task(
               requester,
               task_attrs(%{"dropoff_location" => %{"lat" => 120, "lng" => 28}})
             )
  end
end
