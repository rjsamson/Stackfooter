# Run this to initialize a set of demo venues / accounts

alias Stackfooter.Venue
alias Stackfooter.Venue.Ticker
alias Stackfooter.VenueRegistry

Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "I1kaUrr1SN6HK6i870d54awmLlk76d06", "rjsamson")
Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "SO68190NJ47of2p7he37tGY1sBKPI85F", "account2")
Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "7O4fvT212gU2p1gu7v6aM25oI1rfbimg", "account3")

nyc_tickers = [%Ticker{name: "New York Company", symbol: "NYC"}]
VenueRegistry.create(Stackfooter.VenueRegistry, "OBEX", nyc_tickers)
foo_tickers = [%Ticker{name: "Foo Fighters International", symbol: "FOO"}]
VenueRegistry.create(Stackfooter.VenueRegistry, "TESTEX", foo_tickers)

{:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
{:ok, testex} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "TESTEX")


# Sample Orders

# Limit sell


Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 30, price: 5000, account: "rjsamson", orderType: "limit"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 30, price: 6000, account: "rjsamson", orderType: "limit"})

# Limit buy

Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 40, price: 6000, account: "account1", orderType: "limit"})

Stackfooter.SettlementDesk.lookup(Stackfooter.SettlementDesk, "rjsamson")

Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 30, price: 6000, account: "rjsamson", orderType: "limit"})
Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 10, price: 7120, account: "rjsamson", orderType: "limit"})
Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 21, price: 7970, account: "rjsamson", orderType: "limit"})

# Market buy/sell

Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 40, price: 0, account: "rjsamson", orderType: "market"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "rjsamson", orderType: "market"})

Venue.order_book(venue, "NYC")
Venue.get_quote(venue, "NYC")
Venue.cancel_order(venue, 1, "RJSAMSON")
Venue.order_status(venue, 1, "RJSAMSON")
Venue.get_quote(venue, "NYC")
Venue.all_orders(venue, "RJSAMSON")
Venue.all_orders_stock(venue, "RJSAMSON", "NYC")

# Stack the order book WAY up

Enum.each(4200..4450, fn x ->
  Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
end)

Enum.each(4460..4710, fn x ->
  Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
end)
