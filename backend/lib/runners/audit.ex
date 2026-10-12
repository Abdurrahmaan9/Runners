defmodule Runners.Audit do
  @moduledoc """
  Append-only record of account and errand activity.
  """

  import Ecto.Query, warn: false

  alias Runners.Accounts.User
  alias Runners.Audit.Event
  alias Runners.Repo

  def record!(actor, action, metadata, opts \\ []) when is_binary(action) and is_map(metadata) do
    %Event{}
    |> Event.changeset(%{
      action: action,
      actor_id: actor && actor.id,
      subject_type: opts[:subject_type],
      subject_id: opts[:subject_id],
      metadata: metadata
    })
    |> Repo.insert!()
  end

  def list(%User{role: :admin}) do
    events =
      Event
      |> order_by([event], desc: event.inserted_at)
      |> limit(300)
      |> Repo.all()
      |> Repo.preload(:actor)

    {:ok, events}
  end

  def list(%User{}), do: {:error, :forbidden}
end
