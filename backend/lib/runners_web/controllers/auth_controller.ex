defmodule RunnersWeb.AuthController do
  @moduledoc """
  Phone-number and password registration and login.

  A local number such as 971234567 is stored as +260971234567. Passwords are
  checked against a bcrypt hash.
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

  def login(conn, %{"phone_number" => phone_number, "password" => password})
      when is_binary(phone_number) and is_binary(password) do
    with {:ok, user} <- Accounts.authenticate_by_phone_and_password(phone_number, password),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      render(conn, :show, user: user, token: token)
    end
  end

  def login(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: RunnersWeb.ErrorJSON)
    |> render(:error,
      code: "VALIDATION_ERROR",
      message: "phone_number and password are required"
    )
  end

  def me(conn, _params) do
    conn
    |> put_view(json: RunnersWeb.UserJSON)
    |> render(:show, user: Guardian.Plug.current_resource(conn))
  end
end
