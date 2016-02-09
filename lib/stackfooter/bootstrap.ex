defmodule Stackfooter.Bootstrap do
  alias Stackfooter.{Venue.Ticker, VenueRegistry}

  def bootstrap do
    default_api_key = Application.get_env(:stackfooter, :bootstrap)[:default_api_key]
    default_account = Application.get_env(:stackfooter, :bootstrap)[:default_account]

    # Default API key(s) to be added on application start.
    # Add more here, and in config/env.secret.exs

    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, default_api_key, default_account)

    # Default Venues and tickers to be added on application start
    # Add more here

    nyc_tickers = [%Ticker{name: "New York Company", symbol: "NYC"}]
    VenueRegistry.create(Stackfooter.VenueRegistry, "OBEX", nyc_tickers)

    foo_tickers = [%Ticker{name: "Foo Fighters International", symbol: "FOO"}]
    VenueRegistry.create(Stackfooter.VenueRegistry, "TESTEX", foo_tickers)
  end
end
