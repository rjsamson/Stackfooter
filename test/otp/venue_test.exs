defmodule Stackfooter.VenueTest do
  use ExUnit.Case, async: false
  alias Stackfooter.{Venue, VenueRegistry, Venue.Ticker}

  setup do
    Stackfooter.ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "4cy7uf63Lw2Sx6652YmLwBKy662weU4q", "admin")

    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    {:ok, venue: venue}
  end

  test "has and tracks tickers", %{venue: venue} do
    {:ok, tickers} = Venue.tickers(venue)

    assert tickers == [%Ticker{name: "New York Company", symbol: "NYC"}]
    Venue.add_ticker(venue, %{symbol: "FOO", name: "Foo Fighters International"})

    {:ok, tickers} = Venue.tickers(venue)
    assert tickers == [%Stackfooter.Venue.Ticker{name: "Foo Fighters International", symbol: "FOO"}, %Ticker{name: "New York Company", symbol: "NYC"}]
  end

  test "various order types", %{venue: venue} do
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 4, price: 100, account: "admin", orderType: "market"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 4, price: 100, account: "admin", orderType: "fill-or-kill"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 4, price: 100, account: "admin", orderType: "immediate-or-cancel"})
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 4, price: 100, account: "admin", orderType: "limit"})
    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 2, price: 100, account: "admin", orderType: "fill-or-kill"})
    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 4, price: 100, account: "admin", orderType: "immediate-or-cancel"})

    {:ok, order_book} = Venue.order_book(venue, "NYC")

    assert order_book["bids"] == []
    assert order_book["asks"] == []
    assert order_book["ok"]
  end

  test "can place orders", %{venue: venue} do
    {:ok, order} = Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 30, price: 5000, account: "rjsamson", orderType: "limit"})

    expected_order = %Stackfooter.Order{account: "RJSAMSON", direction: "sell", fills: [], id: 0, open: true, orderType: "limit", originalQty: 30, price: 5000, qty: 30, symbol: "NYC", totalFilled: 0, venue: "OBEX"}

    assert order.account == expected_order.account
    assert order.direction == expected_order.direction
    assert order.open == expected_order.open
    assert order.qty == expected_order.qty
    assert order.symbol == expected_order.symbol
    assert order.venue == expected_order.venue
    assert order.totalFilled == expected_order.totalFilled
  end

  test "orders fill when crossed", %{venue: venue} do
    Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 30, price: 5000, account: "rjsamson", orderType: "limit"})

    {:ok, second_order} = Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 20, price: 5100, account: "rjsamson", orderType: "limit"})

    fill = second_order.fills |> List.first
    assert fill.price == 5000
    assert fill.qty == 20
  end

  test "orderbook hold limit orders", %{venue: venue} do
    Enum.each(4200..4210, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    expected_order_book = %{"asks" => [%Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4220, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4221, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4222, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4223, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4224, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4225, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4226, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4227, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4228, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4229, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: false, price: 4230, qty: 7}],
                             "bids" => [%Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4210,
                               qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4209, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4208, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4207, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4206, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4205, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4204, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4203, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4202, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4201, qty: 7},
                              %Stackfooter.Venue.OrderbookEntry{isBuy: true, price: 4200, qty: 7}],
                             "ok" => true, "symbol" => "NYC", "ts" => "2016-02-02T18:49:48.343Z",
                             "venue" => "OBEX"}

      {:ok, order_book} = Venue.order_book(venue, "NYC")

      assert order_book["asks"] == expected_order_book["asks"]
      assert order_book["bids"] == expected_order_book["bids"]
  end

  test "venue resets properly", %{venue: venue} do
    Enum.each(4200..4210, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Venue.reset(venue)

    {:ok, order_book} = Venue.order_book(venue, "NYC")

    assert remove_timestamp(order_book) == %{"asks" => [], "bids" => [], "ok" => true, "symbol" => "NYC", "venue" => "OBEX"}
  end

  test "quote bid / ask amounts are correct", %{venue: venue} do
    Enum.each(4200..4210, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: 0, account: "rjsamson", orderType: "market"})

    {:ok, stock_quote} = Venue.get_quote(venue, "NYC")

    expected_quote = %{"ask" => 4221, "askDepth" => 70, "askSize" => 7, "bid" => 4210, "bidDepth" => 77, "bidSize" => 7, "last" => 4220, "lastSize" => 7, "lastTrade" => stock_quote["lastTrade"], "quoteTime" => stock_quote["quoteTime"], "symbol" => "NYC", "venue" => "OBEX"}

    assert stock_quote == expected_quote
  end

  defp remove_timestamp(result) do
    Map.delete(result,"ts")
  end
end
