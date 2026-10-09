defmodule Runners.GeospatialTest do
  use Runners.DataCase, async: true

  alias Runners.Accounts
  alias Runners.Geospatial

  test "list_nearby_runners returns online runners inside the radius" do
    near = register_user!(%{role: "runner", full_name: "Near Runner"})
    far = register_user!(%{role: "runner", full_name: "Far Runner"})
    offline = register_user!(%{role: "runner", full_name: "Offline Runner"})

    {:ok, _} = Accounts.set_online_status(near, true)
    {:ok, _} = Accounts.set_online_status(far, true)
    {:ok, _} = Accounts.set_online_status(offline, true)

    assert {:ok, %{persisted: true}} = Geospatial.record_location(near, -15.3875, 28.3228)
    assert {:ok, %{persisted: true}} = Geospatial.record_location(far, -15.5, 28.3228)
    assert {:ok, %{persisted: true}} = Geospatial.record_location(offline, -15.388, 28.323)

    {:ok, _} = Accounts.set_online_status(offline, false)

    ids =
      -15.3875
      |> Geospatial.list_nearby_runners(28.3228, 3_000)
      |> Enum.map(& &1.user_id)

    assert near.id in ids
    refute far.id in ids
    refute offline.id in ids
  end

  test "record_location rejects an offline runner" do
    runner = register_user!(%{role: "runner"})

    assert Geospatial.record_location(runner, -15.3875, 28.3228) == {:error, :runner_offline}
  end
end
