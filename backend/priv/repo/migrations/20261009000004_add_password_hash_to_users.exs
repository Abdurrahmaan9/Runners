defmodule Runners.Repo.Migrations.AddPasswordHashToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :password_hash, :string
    end

    flush()

    hash = Bcrypt.hash_pwd_salt("password123")
    repo().query!("UPDATE users SET password_hash = $1 WHERE password_hash IS NULL", [hash])

    alter table(:users) do
      modify :password_hash, :string, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :password_hash
    end
  end
end
