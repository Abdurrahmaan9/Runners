defmodule Runners.Accounts do
  @moduledoc """
  Registration, lookup, and runner presence.
  """

  import Ecto.Query, warn: false

  alias Runners.Accounts.RunnerProfile
  alias Runners.Accounts.User
  alias Runners.Audit
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
          user = Repo.preload(user, :runner_profile)

          Audit.record!(
            user,
            "user.registered",
            %{"name" => user.full_name, "role" => Atom.to_string(user.role)},
            subject_type: "user",
            subject_id: user.id
          )

          user

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
      user && user.blocked && Bcrypt.verify_pass(password, user.password_hash) ->
        note_login(user, "user.login_blocked", normalized)
        {:error, :blocked}

      user && Bcrypt.verify_pass(password, user.password_hash) ->
        note_login(user, "user.logged_in", normalized)
        {:ok, user}

      user ->
        note_login(user, "user.login_failed", normalized)
        {:error, :invalid_credentials}

      true ->
        Bcrypt.no_user_verify()
        note_login(nil, "user.login_failed", normalized)
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

  def update_user(%User{} = user, attrs) do
    Repo.transaction(fn ->
      case user |> User.admin_update_changeset(attrs) |> Repo.update() do
        {:ok, user} ->
          ensure_runner_profile(user)
          user |> Repo.preload(:runner_profile, force: true)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def set_blocked(%User{role: :admin}, _blocked), do: {:error, :forbidden}

  def set_blocked(%User{} = user, blocked) when is_boolean(blocked) do
    Repo.transaction(fn ->
      case user |> Ecto.Changeset.change(blocked: blocked) |> Repo.update() do
        {:ok, user} ->
          if blocked, do: force_offline(user)
          user |> Repo.preload(:runner_profile, force: true)

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def set_blocked(_user, _blocked), do: {:error, :invalid_blocked_flag}

  def set_online_status(%User{role: :runner} = user, is_online) when is_boolean(is_online) do
    case profile_for(user) do
      nil ->
        {:error, :runner_profile_not_found}

      %RunnerProfile{} = profile ->
        case profile |> Ecto.Changeset.change(is_online: is_online) |> Repo.update() do
          {:ok, _updated} = ok ->
            action = if is_online, do: "runner.online", else: "runner.offline"

            Audit.record!(user, action, %{"name" => user.full_name},
              subject_type: "user",
              subject_id: user.id
            )

            ok

          error ->
            error
        end
    end
  end

  def set_online_status(%User{}, is_online) when is_boolean(is_online), do: {:error, :forbidden}
  def set_online_status(_user, _is_online), do: {:error, :invalid_online_flag}

  defp ensure_runner_profile(%User{role: :runner} = user) do
    if profile_for(user), do: :ok, else: maybe_create_runner_profile(user)
  end

  defp ensure_runner_profile(_user), do: :ok

  defp force_offline(%User{role: :runner} = user) do
    case profile_for(user) do
      nil ->
        :ok

      profile ->
        profile
        |> Ecto.Changeset.change(is_online: false)
        |> Repo.update!()
    end
  end

  defp force_offline(_user), do: :ok

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

  defp note_login(user, action, phone) do
    metadata = %{"phone" => phone}
    metadata = if user, do: Map.put(metadata, "name", user.full_name), else: metadata

    Audit.record!(user, action, metadata, subject_type: "user", subject_id: user && user.id)
  end
end
