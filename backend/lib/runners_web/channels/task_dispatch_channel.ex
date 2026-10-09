defmodule RunnersWeb.TaskDispatchChannel do
  @moduledoc """
  Per-runner topic `task_dispatch:<user_id>`.

  Nearby `task_posted` events and later status changes are broadcast here.
  """

  use RunnersWeb, :channel

  @impl true
  def join("task_dispatch:" <> user_id, _payload, socket) do
    if socket.assigns.current_user.id == user_id do
      {:ok, socket}
    else
      {:error,
       %{code: "FORBIDDEN", message: "You can only subscribe to your own dispatch channel"}}
    end
  end
end
