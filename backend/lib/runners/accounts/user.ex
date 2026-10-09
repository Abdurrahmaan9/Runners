defmodule Runners.Accounts.User do
  @moduledoc """
  A person on the platform. Phone numbers are stored in E.164 with the
  Zambian prefix +260. Passwords are stored only as a bcrypt hash.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @roles [:requester, :runner, :admin]
  @public_roles [:requester, :runner]
  @phone_format ~r/^\+[1-9]\d{7,14}$/

  schema "users" do
    field :phone_number, :string
    field :full_name, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    field :role, Ecto.Enum, values: @roles
    field :is_verified, :boolean, default: false

    has_one :runner_profile, Runners.Accounts.RunnerProfile

    timestamps(type: :utc_datetime)
  end

  def roles, do: @roles
  def public_roles, do: @public_roles

  @doc """
  Stores a Zambian number as E.164.

  `971234567`, `0971234567`, and `+260 97 123 4567` all become `+260971234567`.
  A leading trunk zero is dropped before the +260 prefix is applied.
  """
  def normalize_phone(phone) when is_binary(phone) do
    compact =
      phone
      |> String.trim()
      |> String.replace(~r/[\s-]/, "")

    local =
      cond do
        String.starts_with?(compact, "+260") ->
          String.replace_prefix(compact, "+260", "")

        String.starts_with?(compact, "260") and String.length(compact) > 11 ->
          String.replace_prefix(compact, "260", "")

        true ->
          compact
      end

    "+260" <> String.trim_leading(local, "0")
  end

  def normalize_phone(phone), do: phone

  @doc """
  Public registration. Admin accounts are not created through this changeset.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:phone_number, :full_name, :role, :password])
    |> validate_required([:phone_number, :full_name, :role, :password])
    |> shared_validations()
    |> validate_inclusion(:role, @public_roles, message: "must be requester or runner")
  end

  @doc """
  Internal changeset used by seeds and admin tooling. Allows the admin role.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:phone_number, :full_name, :role, :is_verified, :password])
    |> validate_required([:phone_number, :full_name, :role, :password])
    |> shared_validations()
    |> validate_inclusion(:role, @roles)
  end

  defp shared_validations(changeset) do
    changeset
    |> update_change(:phone_number, &normalize_phone/1)
    |> update_change(:full_name, &trim/1)
    |> validate_format(:phone_number, @phone_format,
      message: "must be a Zambian number, for example 971234567"
    )
    |> validate_length(:full_name, min: 2, max: 120)
    |> validate_length(:password, min: 8, max: 72)
    |> unique_constraint(:phone_number, message: "is already registered")
    |> hash_password()
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end

  defp trim(nil), do: nil
  defp trim(value) when is_binary(value), do: String.trim(value)
end
