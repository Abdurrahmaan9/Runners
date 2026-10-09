defmodule RunnersWeb.AuthControllerTest do
  use RunnersWeb.ConnCase, async: true

  test "register and login issue a bearer token", %{conn: conn} do
    params = %{
      "phone_number" => "+260971000099",
      "full_name" => "Amina Banda",
      "role" => "requester"
    }

    conn = post(conn, ~p"/api/auth/register", params)
    assert %{"data" => %{"token" => token, "user" => %{"id" => id}}} = json_response(conn, 201)

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)
      |> get(~p"/api/auth/me")

    assert %{"data" => %{"id" => ^id, "role" => "requester"}} = json_response(conn, 200)

    conn = post(build_conn(), ~p"/api/auth/login", %{"phone_number" => "+260971000099"})
    assert %{"data" => %{"token" => _token}} = json_response(conn, 200)
  end

  test "login without an account returns the standard error envelope", %{conn: conn} do
    conn = post(conn, ~p"/api/auth/login", %{"phone_number" => "+260970000001"})

    assert json_response(conn, 401) == %{
             "error" => %{
               "code" => "UNAUTHORIZED",
               "message" => "No account exists for this phone number"
             }
           }
  end

  test "protected routes require a token", %{conn: conn} do
    conn = get(conn, ~p"/api/tasks")

    assert %{"error" => %{"code" => "UNAUTHORIZED"}} = json_response(conn, 401)
  end
end
