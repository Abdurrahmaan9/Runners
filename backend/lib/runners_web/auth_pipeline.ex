defmodule RunnersWeb.AuthPipeline do
  @moduledoc false

  use Guardian.Plug.Pipeline,
    otp_app: :runners,
    module: Runners.Auth.Guardian,
    error_handler: RunnersWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: false
end
