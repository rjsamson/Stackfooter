defmodule Stackfooter.VenueControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.{Venue, VenueRegistry}

  @apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"

  setup_all do
    reset_api_keys()
    :ok
  end

  test "returns all open venues" do
    conn = get(build_conn(), "/ob/api/venues/")
    resp = json_response(conn, 200)

    expected_venues = [%{"id" => 0, "name" => "", "state" => "open", "venue" => "TESTEX"},
                       %{"id" => 1, "name" => "", "state" => "open", "venue" => "OBEX"}]

    assert resp
    assert resp["id"]
    assert resp["venues"] == expected_venues
  end

  test "returns correct error when trying to cancel invalid order numbers" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/10")
    resp = json_response(conn, 401)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Highest order id is 1"

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/-1")
    resp = json_response(conn, 401)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Highest order id is 1"
  end

  test "returns correct error when trying to get status on invalid order numbers" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/orders/10")
    resp = json_response(conn, 401)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Highest order id is 1"

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/orders/-1")
    resp = json_response(conn, 401)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Highest order id is 1"
  end

  test "returns correct errors when an integer is not supplied for order id in order status" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/orders/a")
    resp = json_response(conn, 200)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Invalid order id. Please supply an integer"
  end

  test "returns correct errors when an integer is not supplied for order id in cancellation" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/a")
    resp = json_response(conn, 200)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Invalid order id. Please supply an integer"
  end

  test "returns unauthorized when trying to access another account's all orders" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "rjsamson", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/rjsamson/orders")
    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Not authorized to access details about that account's orders."

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/rjsamson/stocks/nyc/orders")
    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Not authorized to access details about that account's orders."
  end

  test "getting order info on unowned order returns correct error" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "rjsamson", orderType: "market"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Only account owner can access that order"
  end

  test "cancelling unowned order returns correct error" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "rjsamson", orderType: "market"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 100, account: "rjsamson", orderType: "limit"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Not authorized to delete that order.  You have to own account  RJSAMSON."

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("ob/api/venues/obex/stocks/nyc/orders/1")
    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Not authorized to delete that order.  You have to own account  RJSAMSON."
  end

  test "cancels an order with a post request" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    expected_order = %{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 0,
                       "ok" => true, "open" => false, "orderType" => "market", "originalQty" => 5,
                       "price" => 0, "qty" => 0, "symbol" => "NYC", "totalFilled" => 0,
                       "venue" => "OBEX"}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> post("ob/api/venues/obex/stocks/nyc/orders/0/cancel")
    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
    assert strip_timestamps(resp) == expected_order
  end

  test "returns the order when cancelling a closed order" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})

    expected_order = %{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 0,
                       "ok" => true, "open" => false, "orderType" => "market", "originalQty" => 5,
                       "price" => 0, "qty" => 0, "symbol" => "NYC", "totalFilled" => 0,
                       "venue" => "OBEX"}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
    assert strip_timestamps(resp) == expected_order
  end

  test "order status" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "limit"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "limit"})
    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 10, price: 0, account: "admin", orderType: "market"})

    expected_order = %{"account" => "ADMIN", "direction" => "buy",
                       "fills" => [%{"price" => 0, "qty" => 5}, %{"price" => 0, "qty" => 5}],
                       "id" => 2, "ok" => true, "open" => false, "orderType" => "market",
                       "originalQty" => 10, "price" => 0, "qty" => 0, "symbol" => "NYC",
                       "totalFilled" => 10, "venue" => "OBEX"}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("ob/api/venues/obex/stocks/nyc/orders/2")
    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
    assert strip_timestamps(resp) == expected_order
  end

  test "returns all orders" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})
    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: 500, account: "admin", orderType: "limit"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: 550, account: "admin", orderType: "limit"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("ob/api/venues/obex/accounts/admin/orders")
    resp = json_response(conn, 200)

    expected_orders = [%{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 2, "open" => true, "orderType" => "limit", "originalQty" => 7,
                         "price" => 550, "qty" => 7, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"},
                       %{"account" => "ADMIN", "direction" => "buy", "fills" => [], "id" => 1, "open" => true, "orderType" => "limit", "originalQty" => 7,
                         "price" => 500, "qty" => 7, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"},
                       %{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 0, "open" => false, "orderType" => "market", "originalQty" => 5,
                         "price" => 0, "qty" => 0, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"}]

    assert resp
    assert resp["ok"]
    assert strip_timestamps(resp["orders"]) == expected_orders
  end

  test "returns all orders for a stock" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 5, price: 0, account: "admin", orderType: "market"})
    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: 500, account: "admin", orderType: "limit"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: 550, account: "admin", orderType: "limit"})

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("ob/api/venues/obex/accounts/admin/stocks/nyc/orders")
    resp = json_response(conn, 200)

    expected_orders = [%{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 2, "open" => true, "orderType" => "limit", "originalQty" => 7,
                         "price" => 550, "qty" => 7, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"},
                       %{"account" => "ADMIN", "direction" => "buy", "fills" => [], "id" => 1, "open" => true, "orderType" => "limit", "originalQty" => 7,
                         "price" => 500, "qty" => 7, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"},
                       %{"account" => "ADMIN", "direction" => "sell", "fills" => [], "id" => 0, "open" => false, "orderType" => "market", "originalQty" => 5,
                         "price" => 0, "qty" => 0, "symbol" => "NYC", "totalFilled" => 0, "venue" => "OBEX"}]

    assert resp
    assert resp["ok"]
    assert strip_timestamps(resp["orders"]) == expected_orders
  end

  test "api heartbeat" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/heartbeat")
    resp = json_response(conn, 200)
    assert resp
    assert resp["ok"]
    assert resp["venue"] == "OBEX"
  end

  test "sends proper error for non-existent venue" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("ob/api/venues/tryex/stocks/nyc/orders/2")
    resp = json_response(conn, 404)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "No venue exists with the symbol TRYEX."
  end

  test "errors placing orders return the proper errors", %{conn: conn} do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    order = %{"venue" => "TRYEX",
              "stock" => "NYC",
              "account" => "ADMIN",
              "direction" => "sell",
              "orderType" => "limit",
              "qty" => 100,
              "price" => 5000}

    conn = put_req_header(conn, "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "application/json")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))

    resp = json_response(conn, 200)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Venue or stock did not match venue or stock provided in the URL."

    order = %{"venue" => "OBEX",
              "stock" => "NYC",
              "account" => "ADMIN",
              "direction" => "sell",
              "orderType" => "limit",
              "qty" => -100,
              "price" => 5000}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "application/json")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))

    resp = json_response(conn, 200)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Please include a valid price and quantity."

    order = %{"venue" => "OBEX",
              "stock" => "NYC",
              "account" => "ADMIN",
              "direction" => "sell",
              "qty" => -100,
              "price" => 5000}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "application/json")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))

    resp = json_response(conn, 200)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "You failed to include some required parameters for the order, or formatted the price or quantity incorrectly."
  end

  test "errors on malformed json" do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> post("/ob/api/venues/obex/stocks/nyc/orders", %{"A.B.C:1.:{:{" => "Nothing"})
    resp = json_response(conn, 500)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Invalid JSON."

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", "A.B.C:1.:{:{")
    resp = json_response(conn, 500)
    assert resp
    refute resp["ok"]
    assert resp["error"] == "Invalid JSON."
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
              "price" => "5000"}

    conn = put_req_header(conn, "x-starfighter-authorization", @apikey)
    |> post("/ob/api/venues/obex/stocks/nyc/orders", order)
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> post("/ob/api/venues/obex/stocks/nyc/orders", %{Poison.encode!(order) => "Nothing"})
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "application/json")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> put_req_header("content-type", "")
    |> post("/ob/api/venues/obex/stocks/nyc/orders", Poison.encode!(order))
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok, "direction" => resp_direction, "fills" => resp_fills, "qty" => resp_qty} = resp
    assert resp_ok
    assert resp_direction == "sell"
    assert resp_fills == []
    assert resp_qty == 100

    order = %{"venue" => "OBEX",
              "symbol" => "NYC",
              "account" => "ADMIN",
              "direction" => "sell",
              "orderType" => "limit",
              "qty" => 100,
              "price" => 5000}

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
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

      conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
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

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
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

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
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

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
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

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/quote")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/heartbeat")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/stocks")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/admin/orders")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> get("/ob/api/venues/obex/accounts/admin/stocks/nyc/orders")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @apikey)
    |> delete("/ob/api/venues/obex/stocks/nyc/orders/0")
    resp = json_response(conn, 200)
    assert resp
    %{"ok" => resp_ok} = resp
    assert resp_ok
  end

  defp strip_timestamps(orders) when is_list(orders) do
    Enum.map(orders, fn order ->
      strip_timestamps(order)
    end)
  end

  defp strip_timestamps(%{"fills" => fills} = order) when is_map(order) do
    new_fills = Enum.map(fills, fn fill ->
      Map.delete(fill,"ts")
    end)

    Map.put(order, "fills", new_fills)
    |> Map.delete("ts")
  end

  defp strip_timestamps(order) when is_map(order) do
    Map.delete(order,"ts")
  end
end
