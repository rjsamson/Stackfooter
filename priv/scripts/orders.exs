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


# Limit sell

Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: 7100, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 9, price: 7200, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 10, price: 7000, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 21, price: 7900, account: "1234567", order_type: "limit"})

# Limit buy

Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: 7800, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 9, price: 7400, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 10, price: 7120, account: "1234567", order_type: "limit"})
Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 21, price: 7970, account: "1234567", order_type: "limit"})

Venue.order_book(venue, "NYC")

# Market buy/sell

Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 16, price: 0, account: "1234567", order_type: "market"})
Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "1234567", order_type: "market"})
