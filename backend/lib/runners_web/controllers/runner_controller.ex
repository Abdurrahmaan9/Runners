defmodule RunnersWeb.RunnerController do
  use RunnersWeb, :controller

  alias Runners.Accounts
  alias Runners.Auth.Guardian
  alias Runners.Geospatial
  alias Runners.Geospatial.Point

  action_fallback RunnersWeb.FallbackController

  def update_status(conn, %{"is_online" => is_online}) when is_boolean(is_online) do
    with {:ok, profile} <- Accounts.set_online_status(current_user(conn), is_online) do
      render(conn, :status, runner_profile: profile)
    end
  end

  def update_status(_conn, _params) do
    {:error, :invalid_online_flag}
  end

  def update_location(conn, %{"lat" => lat, "lng" => lng}) do
    case Geospatial.record_location(current_user(conn), lat, lng) do
      {:ok, %{lat: lat, lng: lng, persisted: persisted}} ->
        render(conn, :location, lat: lat, lng: lng, persisted: persisted)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update_location(_conn, _params) do
    {:error, :invalid_coordinates}
  end

  def nearby(conn, params) do
    with {:ok, lat} <- coordinate(params["lat"]),
         {:ok, lng} <- coordinate(params["lng"]),
         {:ok, radius} <- radius(params["radius_in_meters"]),
         :ok <- bounds(lat, lng) do
      runners = Geospatial.list_nearby_runners(lat, lng, radius)
      render(conn, :index, runners: runners)
    end
  end

  defp coordinate(value) do
    case Point.cast_number(value) do
      {:ok, number} -> {:ok, number}
      :error -> {:error, :invalid_coordinates}
    end
  end

  defp bounds(lat, lng) do
    if Point.valid?(lat, lng), do: :ok, else: {:error, :invalid_coordinates}
  end

  defp radius(nil), do: {:ok, 5_000}
  defp radius(""), do: {:ok, 5_000}

  defp radius(value) do
    case Integer.parse(to_string(value)) do
      {meters, ""} when meters > 0 and meters <= 50_000 -> {:ok, meters}
      _ -> {:error, :invalid_radius}
    end
  end

  defp current_user(conn), do: Guardian.Plug.current_resource(conn)
end
