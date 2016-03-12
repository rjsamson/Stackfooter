# Run this to initialize a set of demo venues / accounts
alias Stackfooter.{Venue, Venue.Ticker, VenueRegistry}

Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "I1kaUrr1SN6HK6i870d54awmLlk76d06", "rjsamson1124")
Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "SO68190NJ47of2p7he37tGY1sBKPI85F", "account21234")
Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "7O4fvT212gU2p1gu7v6aM25oI1rfbimg", "account35678")

Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "SO68190NJ47of2p7he37tGY1sBKPI85F", "NOISEBOTS1237")

nyc_tickers = [%Ticker{name: "New York Company", symbol: "NYC"}]
VenueRegistry.create(Stackfooter.VenueRegistry, "OBEX", nyc_tickers)
foo_tickers = [%Ticker{name: "Foo Fighters International", symbol: "FOO"}]
VenueRegistry.create(Stackfooter.VenueRegistry, "TESTEX", foo_tickers)
