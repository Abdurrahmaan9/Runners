defmodule Runners.Geospatial.Point do
  @moduledoc """
  Converts API coordinates into a WGS84 `Geo.Point`.

  GeoJSON and PostGIS use `{longitude, latitude}` order. The HTTP API uses
  `lat` and `lng` so clients do not have to remember that order.
  """

  @type parse_result :: {:ok, Geo.Point.t() | nil} | {:error, :invalid_coordinates}

  @doc """
  Accepts `%{"lat" => ..., "lng" => ...}`, atom-key maps, or `nil`.
  """
  @spec parse(term()) :: parse_result()
  def parse(nil), do: {:ok, nil}

  def parse(%{"lat" => lat, "lng" => lng}) do
    build(lat, lng)
  end

  def parse(%{lat: lat, lng: lng}) do
    build(lat, lng)
  end

  def parse(_other), do: {:error, :invalid_coordinates}

  @spec to_map(Geo.Point.t() | nil) :: %{lat: number(), lng: number()} | nil
  def to_map(nil), do: nil

  def to_map(%Geo.Point{coordinates: {lng, lat}}) do
    %{lat: lat, lng: lng}
  end

  @spec valid?(number(), number()) :: boolean()
  def valid?(lat, lng) when is_number(lat) and is_number(lng) do
    lat >= -90 and lat <= 90 and lng >= -180 and lng <= 180
  end

  def valid?(_lat, _lng), do: false

  @spec cast_number(term()) :: {:ok, float()} | :error
  def cast_number(value) when is_float(value), do: {:ok, value}
  def cast_number(value) when is_integer(value), do: {:ok, value * 1.0}

  def cast_number(value) when is_binary(value) do
    case Float.parse(String.trim(value)) do
      {number, ""} -> {:ok, number}
      _ -> :error
    end
  end

  def cast_number(_value), do: :error

  defp build(lat, lng) do
    with {:ok, lat} <- cast_number(lat),
         {:ok, lng} <- cast_number(lng),
         true <- valid?(lat, lng) do
      {:ok, %Geo.Point{coordinates: {lng, lat}, srid: 4326}}
    else
      _ -> {:error, :invalid_coordinates}
    end
  end
end
