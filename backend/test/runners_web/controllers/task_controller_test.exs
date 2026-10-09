defmodule RunnersWeb.TaskControllerTest do
  use RunnersWeb.ConnCase, async: true

  test "requester creates a task and a runner accepts it", %{conn: conn} do
    requester = register_user!(%{role: "requester"})
    runner = register_user!(%{role: "runner"})

    conn = conn |> login(requester) |> post(~p"/api/tasks", task_attrs())
    assert %{"data" => %{"id" => id, "status" => "posted"}} = json_response(conn, 201)

    conn = build_conn() |> login(runner) |> post(~p"/api/tasks/#{id}/accept")

    assert %{"data" => %{"status" => "assigned", "runner_id" => runner_id}} =
             json_response(conn, 200)

    assert runner_id == runner.id

    conn =
      build_conn()
      |> login(runner)
      |> post(~p"/api/tasks/#{id}/status", %{"status" => "runner_arrived"})

    assert %{"data" => %{"status" => "runner_arrived"}} = json_response(conn, 200)
  end

  test "a missing task returns the standard not found envelope", %{conn: conn} do
    requester = register_user!()
    missing_id = Ecto.UUID.generate()

    conn = conn |> login(requester) |> get(~p"/api/tasks/#{missing_id}")

    assert json_response(conn, 404) == %{
             "error" => %{"code" => "NOT_FOUND", "message" => "Task does not exist"}
           }
  end

  test "invalid payloads return field details", %{conn: conn} do
    requester = register_user!()

    conn = conn |> login(requester) |> post(~p"/api/tasks", %{"title" => "no"})

    assert %{
             "error" => %{
               "code" => "VALIDATION_ERROR",
               "message" => "Request payload is invalid",
               "details" => details
             }
           } = json_response(conn, 422)

    assert details["description"]
    assert details["dropoff_location"]
  end
end
