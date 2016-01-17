defmodule Stackfooter.Router do
  use Stackfooter.Web, :router

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

  scope "/", Stackfooter do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/ob/api", Stackfooter do
    pipe_through :api

    get "/venues/:venue/heartbeat", VenueController, :heartbeat
    get "/venues/:venue/stocks", VenueController, :stocks
  end

  # Other scopes may use custom stacks.
  # scope "/api", Stackfooter do
  #   pipe_through :api
  # end
end
