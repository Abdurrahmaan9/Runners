alias Runners.Accounts

public_users = [
  %{phone_number: "+260971000001", full_name: "Amina Banda", role: "requester"},
  %{phone_number: "+260971000002", full_name: "Joseph Phiri", role: "runner"}
]

for attrs <- public_users do
  if is_nil(Accounts.get_user_by_phone(attrs.phone_number)) do
    {:ok, _user} = Accounts.register_user(attrs)
  end
end

admin = %{phone_number: "+260971000003", full_name: "Platform Admin", role: "admin"}

if is_nil(Accounts.get_user_by_phone(admin.phone_number)) do
  {:ok, _admin} = Accounts.register_user(admin, allow_admin: true)
end
