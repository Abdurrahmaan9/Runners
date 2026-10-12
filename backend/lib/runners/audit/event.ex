defmodule Runners.Audit.Event do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "audit_events" do
    field :action, :string
    field :subject_type, :string
    field :subject_id, :binary_id
    field :metadata, :map, default: %{}

    belongs_to :actor, Runners.Accounts.User

    timestamps(type: :utc_datetime, updated_at: false)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:action, :actor_id, :subject_type, :subject_id, :metadata])
    |> validate_required([:action])
    |> validate_length(:action, max: 64)
  end
end
