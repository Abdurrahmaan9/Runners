defmodule RunnersWeb.ErrorJSONTest do
  use ExUnit.Case, async: true

  test "renders 404" do
    assert RunnersWeb.ErrorJSON.render("404.json", %{}) == %{
             error: %{code: "NOT_FOUND", message: "Resource does not exist"}
           }
  end

  test "renders 500" do
    assert RunnersWeb.ErrorJSON.render("500.json", %{}) == %{
             error: %{code: "INTERNAL_ERROR", message: "Internal server error"}
           }
  end
end
