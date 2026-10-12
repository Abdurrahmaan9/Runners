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

  test "a requester cannot read admin stats", %{conn: conn} do
    requester = register_user!(%{role: "requester"})

    conn = conn |> login(requester) |> get(~p"/api/admin/stats")

    assert json_response(conn, 403)["error"]["code"] == "FORBIDDEN"
  end
end
