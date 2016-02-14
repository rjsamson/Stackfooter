defmodule Stackfooter.VenueRegistryTest do
  use ExUnit.Case, async: true
  alias Stackfooter.{Venue, VenueRegistry, Venue.Ticker}

  setup do
    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "4cy7uf63Lw2Sx6652YmLwBKy662weU4q", "admin")

    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    {:ok, venue: venue}
  end

  test "returns existing venue when creating a venue that already exists", %{venue: venue} do
    foo_tickers = [%Ticker{name: "Foo Fighters International", symbol: "FOO"}]
    {:ok, same_venue} = VenueRegistry.create(VenueRegistry, "OBEX", foo_tickers)

    assert venue == same_venue
  end

  test "returns all venue names available" do
    all_venue_names = VenueRegistry.all_venue_names(VenueRegistry)

    assert all_venue_names == ["TESTEX", "OBEX"]
  end
end
