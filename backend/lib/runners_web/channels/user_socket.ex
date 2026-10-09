defmodule RunnersWeb.UserSocket do
  use Phoenix.Socket

  alias Runners.Auth.Guardian

  channel "task_tracking:*", RunnersWeb.TaskTrackingChannel
  channel "task_dispatch:*", RunnersWeb.TaskDispatchChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) when is_binary(token) do
    case Guardian.resource_from_token(token) do
      {:ok, user, _claims} -> {:ok, assign(socket, :current_user, user)}
      _error -> :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
