defmodule RunnersWeb.AuditJSON do
  @moduledoc false

  alias Runners.Audit.Event

  def index(%{events: events}) do
    %{data: Enum.map(events, &data/1)}
  end

  def data(%Event{} = event) do
    %{
      id: event.id,
      action: event.action,
      actor_name: actor_name(event.actor),
      subject_type: event.subject_type,
      subject_id: event.subject_id,
      metadata: event.metadata || %{},
      inserted_at: event.inserted_at
    }
  end

  defp actor_name(%{full_name: name}), do: name
  defp actor_name(_actor), do: nil
end
