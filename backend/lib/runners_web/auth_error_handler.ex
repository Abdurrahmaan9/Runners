defmodule RunnersWeb.AuthErrorHandler do
  @moduledoc false

  @behaviour Guardian.Plug.ErrorHandler

  import Plug.Conn

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason}, _opts) do
    body =
      Jason.encode!(%{
        error: %{
          code: "UNAUTHORIZED",
          message: message(type)
        }
      })

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(:unauthorized, body)
  end

  defp message(:unauthenticated), do: "Authentication required"
  defp message(:invalid_token), do: "Authentication token is invalid"
  defp message(:already_authenticated), do: "Already authenticated"
  defp message(:no_resource_found), do: "Authentication token is invalid"
  defp message(_type), do: "Authentication failed"
end
