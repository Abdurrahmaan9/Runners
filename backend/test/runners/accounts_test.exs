defmodule Runners.AccountsTest do
  use Runners.DataCase, async: true

  alias Runners.Accounts

  test "register_user creates a runner profile only for runners" do
    runner = register_user!(%{role: "runner", full_name: "Joseph Phiri"})
    requester = register_user!(%{role: "requester"})

    assert runner.role == :runner
    assert runner.runner_profile.is_online == false
    assert requester.runner_profile == nil
  end

  test "register_user rejects public admin signup and duplicate phones" do
    assert {:error, changeset} =
             Accounts.register_user(%{
               "phone_number" => "+260971112233",
               "full_name" => "Sneaky Admin",
               "role" => "admin"
             })

    assert "must be requester or runner" in errors_on(changeset).role

    user = register_user!(%{phone_number: "+260 97 111 2234"})

    assert user.phone_number == "+260971112234"

    assert {:error, changeset} =
             Accounts.register_user(%{
               "phone_number" => "+260971112234",
               "full_name" => "Second Person",
               "role" => "requester"
             })

    assert "is already registered" in errors_on(changeset).phone_number
  end

  test "authenticate_by_phone finds a normalized number" do
    user = register_user!(%{phone_number: "+260971234567"})

    assert {:ok, found} = Accounts.authenticate_by_phone("+260 97 123 4567")
    assert found.id == user.id
    assert Accounts.authenticate_by_phone("+260970000000") == {:error, :invalid_credentials}
  end

  test "set_online_status is limited to runners" do
    runner = register_user!(%{role: "runner"})
    requester = register_user!(%{role: "requester"})

    assert {:ok, profile} = Accounts.set_online_status(runner, true)
    assert profile.is_online

    assert Accounts.set_online_status(requester, true) == {:error, :forbidden}
  end
end
