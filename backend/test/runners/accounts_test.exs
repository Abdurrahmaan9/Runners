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
               "phone_number" => "971112233",
               "password" => "password123",
               "full_name" => "Sneaky Admin",
               "role" => "admin"
             })

    assert "must be requester or runner" in errors_on(changeset).role

    user = register_user!(%{phone_number: "0971 112 234"})

    assert user.phone_number == "+260971112234"

    assert {:error, changeset} =
             Accounts.register_user(%{
               "phone_number" => "971112234",
               "password" => "password123",
               "full_name" => "Second Person",
               "role" => "requester"
             })

    assert "is already registered" in errors_on(changeset).phone_number
  end

  test "authenticate_by_phone_and_password accepts a local number" do
    user = register_user!(%{phone_number: "971234567", password: "password123"})

    assert {:ok, found} =
             Accounts.authenticate_by_phone_and_password("0971234567", "password123")

    assert found.id == user.id

    assert Accounts.authenticate_by_phone_and_password("971234567", "wrong-password") ==
             {:error, :invalid_credentials}

    assert Accounts.authenticate_by_phone_and_password("970000000", "password123") ==
             {:error, :invalid_credentials}
  end

  test "set_online_status is limited to runners" do
    runner = register_user!(%{role: "runner"})
    requester = register_user!(%{role: "requester"})

    assert {:ok, profile} = Accounts.set_online_status(runner, true)
    assert profile.is_online

    assert Accounts.set_online_status(requester, true) == {:error, :forbidden}
  end
end
