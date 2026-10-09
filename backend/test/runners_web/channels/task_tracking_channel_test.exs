defmodule RunnersWeb.TaskTrackingChannelTest do
  use Runners.DataCase, async: false

  @endpoint RunnersWeb.Endpoint

  import Phoenix.ChannelTest

  alias Runners.Accounts
  alias Runners.Auth.Guardian
  alias Runners.Tasks
  alias RunnersWeb.UserSocket

  test "the requester receives location pings while the task is in progress" do
    requester = register_user!(%{role: "requester"})
    runner = register_user!(%{role: "runner"})
    {:ok, _} = Accounts.set_online_status(runner, true)

    task = create_task!(requester)
    {:ok, task} = Tasks.accept_task(task.id, runner)
    {:ok, task} = Tasks.advance_task(task, runner, "runner_arrived")
    {:ok, task} = Tasks.advance_task(task, runner, "in_progress")

    {:ok, runner_token, _} = Guardian.encode_and_sign(runner)
    {:ok, requester_token, _} = Guardian.encode_and_sign(requester)

    {:ok, runner_socket} = connect(UserSocket, %{"token" => runner_token})
    {:ok, _, runner_socket} = subscribe_and_join(runner_socket, "task_tracking:#{task.id}")

    {:ok, requester_socket} = connect(UserSocket, %{"token" => requester_token})
    {:ok, _, _requester_socket} = subscribe_and_join(requester_socket, "task_tracking:#{task.id}")

    ref = push(runner_socket, "location", %{"lat" => -15.39, "lng" => 28.32})
    assert_reply ref, :ok, %{lat: lat, lng: lng}
    assert_in_delta lat, -15.39, 0.0001
    assert_in_delta lng, 28.32, 0.0001
    assert_push "runner_location", %{task_id: task_id, runner_id: runner_id}
    assert task_id == task.id
    assert runner_id == runner.id
  end

  test "a runner cannot join another runner's dispatch channel" do
    runner = register_user!(%{role: "runner"})
    other = register_user!(%{role: "runner"})
    {:ok, token, _} = Guardian.encode_and_sign(runner)

    {:ok, socket} = connect(UserSocket, %{"token" => token})

    assert {:error, %{code: "FORBIDDEN"}} =
             subscribe_and_join(socket, "task_dispatch:#{other.id}")
  end
end
