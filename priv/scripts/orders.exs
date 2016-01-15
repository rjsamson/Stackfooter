alias Stackfooter.Venue

{:ok, venue} = Venue.start_link("OBEX", ["NYC"])

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
