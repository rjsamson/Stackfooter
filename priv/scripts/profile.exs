defmodule Profile do
  alias Stackfooter.{Venue, VenueRegistry}

  def go do
    :fprof.apply(&run_test/0, [])
    :fprof.profile()
    :fprof.analyse([
        callers: true,
        sort: :own,
        totals: true,
        details: true
      ])
  end

  def run_test do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")

    Enum.each(4200..4450, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Enum.each(4200..4450, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)
  end
end
