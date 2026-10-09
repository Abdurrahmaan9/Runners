defmodule Runners.Accounts do
  @moduledoc """
  Registration, lookup, and runner presence.
  """

  import Ecto.Query, warn: false

  alias Runners.Accounts.RunnerProfile
  alias Runners.Accounts.User
  alias Runners.Repo

  @doc """
  Registers a requester or runner.

  Pass `allow_admin: true` only from trusted seeds or admin tools. The public
  registration endpoint does not set that option.
  """
  def register_user(attrs, opts \\ []) do
    changeset_fun =
      if Keyword.get(opts, :allow_admin, false) do
        &User.changeset/2
      else
        &User.registration_changeset/2
      end

    Repo.transaction(fn ->
      case %User{} |> changeset_fun.(attrs) |> Repo.insert() do
        {:ok, user} ->
          maybe_create_runner_profile(user)
          Repo.preload(user, :runner_profile)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Checks a phone number and password. The phone may be a local number; it is
  stored and compared as +260…
  """
  def authenticate_by_phone_and_password(phone, password)
      when is_binary(phone) and is_binary(password) do
    normalized = User.normalize_phone(phone)
    user = User |> Repo.get_by(phone_number: normalized) |> preload_profile()

    cond do
      user && Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  def authenticate_by_phone_and_password(_phone, _password), do: {:error, :invalid_credentials}

  def get_user(id) do
    case Ecto.UUID.cast(id) do
      {:ok, uuid} ->
        User
        |> Repo.get(uuid)
        |> preload_profile()

      :error ->
        nil
    end
  end

  def get_user!(id) do
    User
    |> Repo.get!(id)
    |> Repo.preload(:runner_profile)
  end

  def get_user_by_phone(phone) when is_binary(phone) do
    User
    |> Repo.get_by(phone_number: User.normalize_phone(phone))
    |> preload_profile()
  end

  def set_online_status(%User{role: :runner} = user, is_online) when is_boolean(is_online) do
    case profile_for(user) do
      nil ->
        {:error, :runner_profile_not_found}

      %RunnerProfile{} = profile ->
        profile
        |> Ecto.Changeset.change(is_online: is_online)
        |> Repo.update()
    end
  end

  def set_online_status(%User{}, is_online) when is_boolean(is_online), do: {:error, :forbidden}
  def set_online_status(_user, _is_online), do: {:error, :invalid_online_flag}

  defp maybe_create_runner_profile(%User{role: :runner} = user) do
    %RunnerProfile{}
    |> RunnerProfile.changeset(%{user_id: user.id})
    |> Repo.insert!()
  end

  defp maybe_create_runner_profile(_user), do: :ok

  defp profile_for(%User{} = user) do
    Repo.get_by(RunnerProfile, user_id: user.id)
  end

  defp preload_profile(nil), do: nil
  defp preload_profile(user), do: Repo.preload(user, :runner_profile)
end
