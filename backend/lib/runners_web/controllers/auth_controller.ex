defmodule RunnersWeb.AuthController do
  @moduledoc """
  Phone-number registration and login.

  This is a mock flow for Phase 1. Presenting a registered phone number returns
  a JWT. It does not send a one-time password and must be replaced before any
  real deployment.
  """

  use RunnersWeb, :controller

  alias Runners.Accounts
  alias Runners.Auth.Guardian

  action_fallback RunnersWeb.FallbackController

  def register(conn, params) do
    with {:ok, user} <- Accounts.register_user(params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> render(:show, user: user, token: token)
    end
  end

  def login(conn, %{"phone_number" => phone_number}) do
    with {:ok, user} <- Accounts.authenticate_by_phone(phone_number),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      render(conn, :show, user: user, token: token)
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RunnersWeb.ErrorJSON)
    |> render(:error, code: "VALIDATION_ERROR", message: "phone_number is required")
  end

  def me(conn, _params) do
    conn
    |> put_view(json: RunnersWeb.UserJSON)
    |> render(:show, user: Guardian.Plug.current_resource(conn))
  end
end
