defmodule RunnersWeb.UserJSON do
  @moduledoc false

  alias Runners.Accounts.RunnerProfile
  alias Runners.Accounts.User
  alias Runners.Geospatial.Point

  def show(%{user: user}) do
    %{data: data(user)}
  end

  def data(%User{} = user) do
    %{
      id: user.id,
      phone_number: user.phone_number,
      full_name: user.full_name,
      role: user.role,
      is_verified: user.is_verified,
      runner_profile: profile(user.runner_profile)
    }
  end

  def profile(%RunnerProfile{} = profile) do
    %{
      id: profile.id,
      is_online: profile.is_online,
      current_location: Point.to_map(profile.current_location),
      last_location_update: profile.last_location_update
    }
  end

  def profile(%Ecto.Association.NotLoaded{}), do: nil
  def profile(nil), do: nil
end
