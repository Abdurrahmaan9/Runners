defmodule RunnersWeb.AuthJSON do
  @moduledoc false

  alias RunnersWeb.UserJSON

  def show(%{user: user, token: token}) do
    %{
      data: %{
        token: token,
        user: UserJSON.data(user)
      }
    }
  end
end
