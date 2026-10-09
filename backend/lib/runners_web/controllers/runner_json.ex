defmodule RunnersWeb.RunnerJSON do
  @moduledoc false

  alias Runners.Accounts.RunnerProfile
  alias Runners.Geospatial.Point
  alias RunnersWeb.UserJSON

  def index(%{runners: runners}) do
    %{data: Enum.map(runners, &nearby/1)}
  end

  def status(%{runner_profile: profile}) do
    %{data: UserJSON.profile(profile)}
  end

  def location(%{lat: lat, lng: lng, persisted: persisted}) do
    %{data: %{lat: lat, lng: lng, persisted: persisted}}
  end

  defp nearby(%RunnerProfile{} = profile) do
    %{
      id: profile.id,
      user_id: profile.user_id,
      full_name: profile.user.full_name,
      is_online: profile.is_online,
      current_location: Point.to_map(profile.current_location),
      last_location_update: profile.last_location_update
    }
  end
end
