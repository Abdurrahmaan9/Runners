defmodule RunnersWeb.Router do
  use RunnersWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug RunnersWeb.AuthPipeline
  end

  scope "/api", RunnersWeb do
    pipe_through :api

    get "/health", HealthController, :show
    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
  end

  scope "/api", RunnersWeb do
    pipe_through [:api, :auth]

    get "/auth/me", AuthController, :me

    patch "/runners/me/status", RunnerController, :update_status
    post "/runners/me/location", RunnerController, :update_location
    get "/runners/nearby", RunnerController, :nearby

    resources "/tasks", TaskController, except: [:new, :edit]
    post "/tasks/:id/accept", TaskController, :accept
    post "/tasks/:id/status", TaskController, :update_status
    post "/tasks/:id/cancel", TaskController, :cancel
  end
end
