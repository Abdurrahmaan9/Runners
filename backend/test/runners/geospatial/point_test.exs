defmodule Runners.Geospatial.PointTest do
  use ExUnit.Case, async: true

  alias Runners.Geospatial.Point

  test "builds a WGS84 point with longitude first" do
    assert {:ok, point} = Point.parse(%{"lat" => "-15.4167", "lng" => "28.2833"})
    assert point.coordinates == {28.2833, -15.4167}
    assert point.srid == 4326
    assert Point.to_map(point) == %{lat: -15.4167, lng: 28.2833}
  end

  test "rejects coordinates outside WGS84 bounds" do
    assert Point.parse(%{"lat" => 95, "lng" => 28}) == {:error, :invalid_coordinates}
    assert Point.parse(%{"lat" => -15, "lng" => 200}) == {:error, :invalid_coordinates}
  end

  test "treats a missing point as empty" do
    assert Point.parse(nil) == {:ok, nil}
  end
end
