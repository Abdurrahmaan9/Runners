defmodule RunnersWeb.RejectBlockedUser do
  @moduledoc false

  import Plug.Conn

  alias Runners.Auth.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.Plug.current_resource(conn) do
      %{blocked: true} ->
        body =
          Jason.encode!(%{
            error: %{
              code: "FORBIDDEN",
              message: "This account is blocked"
            }
          })

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:forbidden, body)
        |> halt()

      _user ->
        conn
    end
  end
end
