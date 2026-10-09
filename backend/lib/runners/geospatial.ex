defmodule Runners.Geospatial do
  @moduledoc """
  Nearby-runner search and high-frequency location ingestion.

  GPS pings are written to Redis on every call. `runner_profiles.current_location`
  is updated on the first ping and again after the configured sync interval so
  PostGIS matching does not write on every 10 second update.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias Runners.Accounts.RunnerProfile
  alias Runners.Accounts.User
  alias Runners.Geospatial.Point
  alias Runners.Repo

  require Logger

  @redis_ttl_seconds 120

  @doc """
  Lists online runners within `radius_in_meters` of a WGS84 coordinate.

  `ST_DWithin` is evaluated on `geography`, so the radius is in meters.
  """
  def list_nearby_runners(lat, lng, radius_in_meters)
      when is_number(lat) and is_number(lng) and is_number(radius_in_meters) do
    unless Point.valid?(lat, lng) do
      raise ArgumentError, "coordinates are out of bounds"
    end

    unless radius_in_meters > 0 do
      raise ArgumentError, "radius_in_meters must be greater than zero"
    end

    point = %Geo.Point{coordinates: {lng * 1.0, lat * 1.0}, srid: 4326}

    RunnerProfile
    |> join(:inner, [profile], user in assoc(profile, :user))
    |> where([profile, _user], profile.is_online == true)
    |> where([profile, _user], not is_nil(profile.current_location))
    |> where([_profile, user], user.role == :runner)
    |> where(
      [profile, _user],
      st_dwithin_in_meters(profile.current_location, ^point, ^radius_in_meters)
    )
    |> preload([_profile, user], user: user)
    |> Repo.all()
  end

  @doc """
  Stores a runner GPS ping.

  Returns `{:ok, %{profile: profile, persisted: persisted, lat: lat, lng: lng}}`
  when the ping is accepted. `persisted` is true when this ping was also written
  to PostGIS.
  """
  def record_location(%User{role: :runner} = user, lat, lng) do
    with {:ok, point} <- Point.parse(%{lat: lat, lng: lng}),
         %RunnerProfile{} = profile <- profile_for(user),
         :ok <- ensure_online(profile),
         :ok <- cache_ping(user.id, point) do
      {lng, lat} = point.coordinates

      if sync_due?(profile) do
        case persist_location(profile, point) do
          {:ok, profile} ->
            {:ok, %{profile: profile, persisted: true, lat: lat, lng: lng}}

          {:error, reason} ->
            {:error, reason}
        end
      else
        {:ok, %{profile: profile, persisted: false, lat: lat, lng: lng}}
      end
    else
      nil -> {:error, :runner_profile_not_found}
      {:error, :runner_offline} -> {:error, :runner_offline}
      {:error, :invalid_coordinates} -> {:error, :invalid_coordinates}
    end
  end

  def record_location(%User{}, _lat, _lng), do: {:error, :forbidden}

  def sync_interval_seconds do
    Application.get_env(:runners, :location_sync_interval_seconds, 30)
  end

  defp profile_for(%User{id: id}), do: Repo.get_by(RunnerProfile, user_id: id)

  defp ensure_online(%RunnerProfile{is_online: true}), do: :ok
  defp ensure_online(%RunnerProfile{}), do: {:error, :runner_offline}

  defp sync_due?(%RunnerProfile{last_location_update: nil}), do: true

  defp sync_due?(%RunnerProfile{last_location_update: last}) do
    DateTime.diff(DateTime.utc_now(), last, :second) >= sync_interval_seconds()
  end

  defp persist_location(profile, point) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    profile
    |> RunnerProfile.changeset(%{current_location: point, last_location_update: now})
    |> Repo.update()
  end

  defp cache_ping(user_id, %Geo.Point{coordinates: {lng, lat}}) do
    payload =
      Jason.encode!(%{
        user_id: user_id,
        lat: lat,
        lng: lng,
        recorded_at: DateTime.utc_now() |> DateTime.to_iso8601()
      })

    try do
      case Redix.command(Runners.Redis, [
             "SET",
             redis_key(user_id),
             payload,
             "EX",
             Integer.to_string(@redis_ttl_seconds)
           ]) do
        {:ok, "OK"} ->
          :ok

        {:error, reason} ->
          Logger.warning("runner location cache failed: #{inspect(reason)}")
          :ok
      end
    catch
      :exit, reason ->
        Logger.warning("runner location cache unavailable: #{inspect(reason)}")
        :ok
    end
  end

  defp redis_key(user_id), do: "runner:location:#{user_id}"
end
