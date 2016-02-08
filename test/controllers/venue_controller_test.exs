defmodule Stackfooter.VenueControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.VenueRegistry
  alias Stackfooter.Venue

  @apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"

  test "api heartbeat", %{conn: conn} do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/heartbeat")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok
  end

  test "place order with various content types", %{conn: conn} do
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

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "application/json")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100
  end

  test "orderbook" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Enum.each(4200..4201, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Enum.each(4220..4221, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    expected_order_book = %{"asks" => [
        %{"isBuy" => false, "price" => 4220, "qty" => 7},
        %{"isBuy" => false, "price" => 4220, "qty" => 7},
        %{"isBuy" => false, "price" => 4221, "qty" => 7},
        %{"isBuy" => false, "price" => 4221, "qty" => 7}
      ],
      "bids" => [
        %{"isBuy" => true, "price" => 4201, "qty" => 2},
        %{"isBuy" => true, "price" => 4201, "qty" => 7},
        %{"isBuy" => true, "price" => 4200, "qty" => 7},
        %{"isBuy" => true, "price" => 4200, "qty" => 7}
      ],
      "ok" => true,
      "symbol" => "NYC",
      "venue" => "OBEX"}

      conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
      |> get("/ob/api/venues/obex/stocks/nyc")
      resp = json_response(conn, 200)
      %{"ok" => resp_ok, "asks" => resp_asks, "bids" => resp_bids} = resp

      assert resp
      assert resp_ok
      assert resp_asks == expected_order_book["asks"]
      assert resp_bids == expected_order_book["bids"]
  end

  test "stock quote and order cancellation" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Enum.each(4200..4210, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    stock_quote = %{"ask" => 4220,
    "askDepth" => 77,
    "askSize" => 7,
    "bid" => 4210,
    "bidDepth" => 72,
    "bidSize" => 2,
    "last" => 4210,
    "lastSize" => 5,
    "ok" => true,
    "symbol" => "NYC",
    "venue" => "OBEX"}

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/quote")
    resp = json_response(conn, 200)

    %{"ok" => resp_ok, "ask" => ask, "askDepth" => ask_depth, "askSize" => ask_size, "bid" => bid, "bidDepth" => bid_depth, "bidSize" => bid_size, "last" => last, "lastSize" => last_size} = resp

    assert resp
    assert resp_ok
    assert ask == stock_quote["ask"]
    assert ask_depth == stock_quote["askDepth"]
    assert ask_size == stock_quote["askSize"]
    assert bid == stock_quote["bid"]
    assert bid_depth == stock_quote["bidDepth"]
    assert bid_size == stock_quote["bidSize"]
    assert last == stock_quote["last"]
    assert last_size == stock_quote["lastSize"]

    deleted_order = %{"account" => "RJSAMSON",
    "direction" => "buy",
    "id" => 10,
    "ok" => true,
    "open" => false,
    "orderType" => "limit",
    "originalQty" => 7,
    "price" => 4210,
    "qty" => 2,
    "symbol" => "NYC",
    "totalFilled" => 5,
    "venue" => "OBEX"}

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/10")
    resp = json_response(conn, 200)
    %{"ok" => resp_ok, "id" => resp_id, "open" => resp_open, "qty" => resp_qty, "originalQty" => resp_original_qty} = resp

    assert resp
    assert resp_ok
    assert resp_id == deleted_order["id"]
    assert resp_open == deleted_order["open"]
    assert resp_qty == deleted_order["qty"]
    assert resp_original_qty == deleted_order["originalQty"]

    updated_stock_quote = %{"ask" => 4220,
    "askDepth" => 77,
    "askSize" => 7,
    "bid" => 4209,
    "bidDepth" => 70,
    "bidSize" => 7,
    "last" => 4210,
    "lastSize" => 5,
    "ok" => true,
    "symbol" => "NYC",
    "venue" => "OBEX"}

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/quote")
    resp = json_response(conn, 200)
    %{"ok" => resp_ok, "ask" => ask, "askDepth" => ask_depth, "askSize" => ask_size, "bid" => bid, "bidDepth" => bid_depth, "bidSize" => bid_size, "last" => last, "lastSize" => last_size} = resp

    assert resp
    assert resp_ok
    assert ask == updated_stock_quote["ask"]
    assert ask_depth == updated_stock_quote["askDepth"]
    assert ask_size == updated_stock_quote["askSize"]
    assert bid == updated_stock_quote["bid"]
    assert bid_depth == updated_stock_quote["bidDepth"]
    assert bid_size == updated_stock_quote["bidSize"]
    assert last == updated_stock_quote["last"]
    assert last_size == updated_stock_quote["lastSize"]
  end

  test "all responses reply with ok", %{conn: conn} do
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
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/quote")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/heartbeat")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/admin/orders")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/admin/stocks/nyc/orders")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok
  end
end
