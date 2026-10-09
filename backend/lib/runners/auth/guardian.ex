defmodule Runners.Auth.Guardian do
  @moduledoc """
  Issues and verifies JWT access tokens for API and channel connections.
  """

  use Guardian, otp_app: :runners

  alias Runners.Accounts

  def subject_for_token(%{id: id}, _claims) when is_binary(id), do: {:ok, id}
  def subject_for_token(_resource, _claims), do: {:error, :invalid_resource}

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims), do: {:error, :invalid_claims}
end
