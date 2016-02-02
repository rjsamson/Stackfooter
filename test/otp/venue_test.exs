defmodule Stackfooter.VenueTest do
  use ExUnit.Case, async: true
  alias Stackfooter.Venue
  alias Stackfooter.VenueRegistry
  alias Stackfooter.Venue.Ticker

  setup do
    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "4cy7uf63Lw2Sx6652YmLwBKy662weU4q", "admin")

    nyc_tickers = [%Ticker{name: "New York Company", symbol: "NYC"}]
    {:ok, venue} = VenueRegistry.create(Stackfooter.VenueRegistry, "OBEX", nyc_tickers)

    {:ok, venue: venue}
  end

  test "has and tracks tickers", %{venue: venue} do
    {:ok, tickers} = Venue.tickers(venue)

    assert tickers == [%Ticker{name: "New York Company", symbol: "NYC"}]
    Venue.add_ticker(venue, %{symbol: "FOO", name: "Foo Fighters International"})

    {:ok, tickers} = Venue.tickers(venue)
    assert tickers == [%Stackfooter.Venue.Ticker{name: "Foo Fighters International", symbol: "FOO"}, %Ticker{name: "New York Company", symbol: "NYC"}]
  end
end
