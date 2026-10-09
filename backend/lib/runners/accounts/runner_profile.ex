defmodule Runners.Accounts.RunnerProfile do
  @moduledoc """
  Online presence and last known location for a runner.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "runner_profiles" do
    field :is_online, :boolean, default: false
    field :current_location, Geo.PostGIS.Geometry
    field :last_location_update, :utc_datetime

    belongs_to :user, Runners.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:user_id, :is_online, :current_location, :last_location_update])
    |> validate_required([:user_id])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
  end
end
