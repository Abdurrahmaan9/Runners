defmodule RunnersWeb.ErrorJSON do
  @moduledoc """
  Standard error envelope: `%{error: %{code: ..., message: ...}}`.
  """

  def error(%{changeset: changeset}) do
    render("error.json", %{changeset: changeset})
  end

  def error(%{code: code, message: message}) do
    render("error.json", %{code: code, message: message})
  end

  def render("error.json", %{changeset: changeset}) do
    %{
      error: %{
        code: "VALIDATION_ERROR",
        message: "Request payload is invalid",
        details: field_errors(changeset)
      }
    }
  end

  def render("error.json", %{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end

  def render("401.json", _assigns) do
    %{error: %{code: "UNAUTHORIZED", message: "Authentication required"}}
  end

  def render("404.json", _assigns) do
    %{error: %{code: "NOT_FOUND", message: "Resource does not exist"}}
  end

  def render("500.json", _assigns) do
    %{error: %{code: "INTERNAL_ERROR", message: "Internal server error"}}
  end

  def render(template, _assigns) do
    %{
      error: %{
        code: "INTERNAL_ERROR",
        message: Phoenix.Controller.status_message_from_template(template)
      }
    }
  end

  defp field_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
