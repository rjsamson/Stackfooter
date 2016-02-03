defmodule Stackfooter.VenueControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.VenueRegistry
  alias Stackfooter.Venue

  @apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"

  test "place order with no content type", %{conn: conn} do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    order = %{"venue" => "OBEX",
              "stock" => "NYC",
              "account" => "ADMIN",
              "direction" => "sell",
              "orderType" => "limit",
              "qty" => 100,
              "price" => 5000}

    conn = put_req_header(conn, "x-starfighter-authorization", @apikey)
    |> post("/ob/api/venues/obex/stocks/nyc/orders", order)
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100
  end
end
