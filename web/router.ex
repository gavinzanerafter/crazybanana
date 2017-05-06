defmodule Crazybanana.Router do
  use Crazybanana.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Crazybanana do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/shop", PageController, :shop
    get "/slots", PageController, :slots
    get "/others", PageController, :others
    get "/crazy", PageController, :crazy
    get "/lobby", PageController, :lobby
    get "/game", PageController, :game
    get "/remember", PageController, :remember
  end

  # Other scopes may use custom stacks.
  # scope "/api", Crazybanana do
  #   pipe_through :api
  # end
end
