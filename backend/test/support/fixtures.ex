defmodule Runners.Fixtures do
  @moduledoc """
  Test data builders for accounts and tasks.
  """

  alias Runners.Accounts
  alias Runners.Tasks

  def unique_phone do
    suffix =
      System.unique_integer([:positive, :monotonic])
      |> Integer.to_string()
      |> String.pad_leading(8, "0")
      |> String.slice(-8, 8)

    "+2609" <> suffix
  end

  def register_user!(attrs \\ %{}) do
    role = to_string(attrs[:role] || attrs["role"] || "requester")

    params = %{
      "phone_number" => attrs[:phone_number] || attrs["phone_number"] || unique_phone(),
      "full_name" => attrs[:full_name] || attrs["full_name"] || "Test User",
      "role" => role
    }

    opts = if role == "admin", do: [allow_admin: true], else: []
    {:ok, user} = Accounts.register_user(params, opts)
    user
  end

  def task_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "title" => "Pick up groceries",
        "description" => "Buy milk and bread from the shop.",
        "task_type" => "store_pickup",
        "pickup_address" => "Shoprite Cairo Road, Lusaka",
        "pickup_location" => %{"lat" => -15.4167, "lng" => 28.2833},
        "dropoff_address" => "Kabulonga, Lusaka",
        "dropoff_location" => %{"lat" => -15.43, "lng" => 28.35},
        "estimated_cost" => "75.00"
      },
      overrides
    )
  end

  def create_task!(requester, overrides \\ %{}) do
    {:ok, task} = Tasks.create_task(requester, task_attrs(overrides))
    task
  end
end
