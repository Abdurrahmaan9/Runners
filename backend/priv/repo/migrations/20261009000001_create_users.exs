defmodule Runners.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS postgis", "DROP EXTENSION IF EXISTS postgis"

    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :phone_number, :string, null: false
      add :full_name, :string, null: false
      add :role, :string, null: false
      add :is_verified, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:phone_number])

    create constraint(:users, :role_must_be_valid,
             check: "role IN ('requester', 'runner', 'admin')"
           )
  end
end
