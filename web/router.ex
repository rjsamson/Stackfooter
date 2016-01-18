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

    get "/heartbeat", ApiController, :heartbeat
    get "/venues/:venue/heartbeat", VenueController, :heartbeat
    get "/venues/:venue/stocks", VenueController, :stocks
    get "/venues/:venue/stocks/:stock", VenueController, :orderbook
    get "/venues/:venue/stocks/:stock/quote", VenueController, :get_quote
    get "/venues/:venue/stocks/:stock/orders/:id", VenueController, :order_status
    get "/venues/:venue/accounts/:account/orders", VenueController, :all_orders
    get "/venues/:venue/accounts/:account/stocks/:stock/orders", VenueController, :all_orders_stock
  end

  # Other scopes may use custom stacks.
  # scope "/api", Stackfooter do
  #   pipe_through :api
  # end
end
