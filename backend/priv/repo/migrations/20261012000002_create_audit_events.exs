defmodule Runners.Repo.Migrations.CreateAuditEvents do
  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :action, :string, null: false
      add :actor_id, references(:users, type: :uuid, on_delete: :nilify_all)
      add :subject_type, :string
      add :subject_id, :uuid
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_events, [:inserted_at])
    create index(:audit_events, [:action])
  end
end
