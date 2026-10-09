defmodule Runners.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def up do
    create table(:tasks, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :requester_id, references(:users, type: :uuid, on_delete: :restrict), null: false

      add :runner_id, references(:users, type: :uuid, on_delete: :nilify_all)

      add :title, :string, null: false
      add :description, :text, null: false
      add :task_type, :string, null: false
      add :status, :string, null: false, default: "posted"
      add :pickup_address, :string, null: false
      add :dropoff_address, :string, null: false
      add :estimated_cost, :decimal, precision: 12, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    execute """
    ALTER TABLE tasks
    ADD COLUMN pickup_location geography(Point, 4326)
    """

    execute """
    ALTER TABLE tasks
    ADD COLUMN dropoff_location geography(Point, 4326) NOT NULL
    """

    execute """
    CREATE INDEX tasks_pickup_location_index
    ON tasks
    USING GIST (pickup_location)
    """

    execute """
    CREATE INDEX tasks_dropoff_location_index
    ON tasks
    USING GIST (dropoff_location)
    """

    create index(:tasks, [:requester_id])
    create index(:tasks, [:runner_id])
    create index(:tasks, [:status])

    create constraint(:tasks, :task_type_must_be_valid,
             check: "task_type IN ('store_pickup', 'delivery', 'home_chore')"
           )

    create constraint(:tasks, :status_must_be_valid,
             check:
               "status IN ('posted', 'assigned', 'runner_arrived', 'in_progress', 'completed', 'cancelled')"
           )
  end

  def down do
    drop table(:tasks)
  end
end
