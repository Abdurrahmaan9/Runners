defmodule Runners.Repo.Migrations.CreateRunnerProfiles do
  use Ecto.Migration

  def up do
    create table(:runner_profiles, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :is_online, :boolean, null: false, default: false
      add :last_location_update, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:runner_profiles, [:user_id])
    create index(:runner_profiles, [:is_online])

    execute """
    ALTER TABLE runner_profiles
    ADD COLUMN current_location geography(Point, 4326)
    """

    execute """
    CREATE INDEX runner_profiles_current_location_index
    ON runner_profiles
    USING GIST (current_location)
    """
  end

  def down do
    drop table(:runner_profiles)
  end
end
