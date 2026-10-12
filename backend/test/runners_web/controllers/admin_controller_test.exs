defmodule RunnersWeb.AdminControllerTest do
  use RunnersWeb.ConnCase, async: true

  alias Runners.Accounts

  test "an admin sees today's errands, people, and active runners", %{conn: conn} do
    admin = register_user!(%{role: "admin"})
    register_user!(%{role: "requester"})
    online = register_user!(%{role: "runner"})
    register_user!(%{role: "runner"})
    requester = register_user!(%{role: "requester"})
    {:ok, _} = Accounts.set_online_status(online, true)
    create_task!(requester)

    conn = conn |> login(admin) |> get(~p"/api/admin/stats")

    assert %{
             "data" => %{
               "errands_posted_today" => 1,
               "runners" => 2,
               "active_runners" => 1,
               "requesters" => 2,
               "errands_open" => 1,
               "errands_active" => 0,
               "errands_completed" => 0
             }
           } = json_response(conn, 200)
  end

  test "an admin opens the lists behind the dashboard counts", %{conn: conn} do
    admin = register_user!(%{role: "admin", full_name: "Platform Admin"})
    register_user!(%{role: "requester", full_name: "Amina"})
    online = register_user!(%{role: "runner", full_name: "Joseph"})
    {:ok, _} = Accounts.set_online_status(online, true)
    requester = register_user!(%{role: "requester", full_name: "Mulenga"})
    task = create_task!(requester)

    conn = conn |> login(admin) |> get(~p"/api/admin/errands?scope=today")
    assert %{"data" => [%{"id" => id}]} = json_response(conn, 200)
    assert id == task.id

    conn = build_conn() |> login(admin) |> get(~p"/api/admin/people?role=runner")

    assert %{
             "data" => [
               %{"full_name" => "Joseph", "role" => "runner", "runner_profile" => profile}
             ]
           } = json_response(conn, 200)

    assert profile["is_online"] == true
  end

  test "unknown dashboard filters are rejected", %{conn: conn} do
    admin = register_user!(%{role: "admin"})

    conn = conn |> login(admin) |> get(~p"/api/admin/errands?scope=nope")

    assert json_response(conn, 422)["error"]["code"] == "VALIDATION_ERROR"
  end

  test "an admin sees where errands are dropped off", %{conn: conn} do
    admin = register_user!(%{role: "admin"})
    requester = register_user!(%{role: "requester"})
    create_task!(requester)

    conn = conn |> login(admin) |> get(~p"/api/admin/heatmap")

    assert %{
             "data" => %{
               "rows" => 6,
               "cols" => 8,
               "cells" => [%{"row" => 3, "col" => 6, "count" => 1}]
             }
           } = json_response(conn, 200)
  end

  test "an admin can add, update, view, and block a person", %{conn: conn} do
    admin = register_user!(%{role: "admin"})

    conn =
      conn
      |> login(admin)
      |> post(~p"/api/admin/people", %{
        "phone_number" => "971555010",
        "password" => "password123",
        "full_name" => "New Runner",
        "role" => "runner"
      })

    assert %{
             "data" => %{
               "id" => id,
               "full_name" => "New Runner",
               "role" => "runner",
               "blocked" => false,
               "runner_profile" => %{"is_online" => false}
             }
           } = json_response(conn, 201)

    conn =
      build_conn()
      |> login(admin)
      |> patch(~p"/api/admin/people/#{id}", %{
        "full_name" => "Updated Runner",
        "phone_number" => "971555010",
        "role" => "runner",
        "password" => ""
      })

    assert %{"data" => %{"full_name" => "Updated Runner"}} = json_response(conn, 200)

    conn = build_conn() |> login(admin) |> post(~p"/api/admin/people/#{id}/block")
    assert %{"data" => %{"blocked" => true}} = json_response(conn, 200)

    assert Accounts.authenticate_by_phone_and_password("971555010", "password123") ==
             {:error, :blocked}

    conn = build_conn() |> login(admin) |> get(~p"/api/admin/people/#{id}")

    assert %{"data" => %{"phone_number" => "+260971555010", "blocked" => true}} =
             json_response(conn, 200)

    conn = build_conn() |> login(admin) |> post(~p"/api/admin/people/#{id}/unblock")
    assert %{"data" => %{"blocked" => false}} = json_response(conn, 200)
  end

  test "a requester cannot add people", %{conn: conn} do
    requester = register_user!(%{role: "requester"})

    conn =
      conn
      |> login(requester)
      |> post(~p"/api/admin/people", %{
        "phone_number" => "971555011",
        "password" => "password123",
        "full_name" => "Nope",
        "role" => "requester"
      })

    assert json_response(conn, 403)["error"]["code"] == "FORBIDDEN"
  end

  test "a requester cannot read admin stats", %{conn: conn} do
    requester = register_user!(%{role: "requester"})

    conn = conn |> login(requester) |> get(~p"/api/admin/stats")

    assert json_response(conn, 403)["error"]["code"] == "FORBIDDEN"
  end
end
