defmodule Stackfooter.Venue do
  alias Stackfooter.Order
  alias Stackfooter.Order.Fill

  use GenServer

  defmodule OrderbookEntry do
    defstruct price: 0, qty: 0, is_buy: true
  end

  def place_order(pid, order), do: GenServer.call(pid, {:place_order, order})

  def order_book(pid, symbol), do: GenServer.call(pid, {:order_book, symbol})

  def cancel_order(pid, order_id, account), do: GenServer.call(pid, {:cancel_order, order_id, account})

  def order_status(pid, order_id, account), do: GenServer.call(pid, {:order_status, order_id, account})

  def tickers(pid), do: GenServer.call(pid, :tickers)

  def add_ticker(pid, ticker), do: GenServer.call(pid, {:add_ticker, ticker})

  def start_link(venue_name, tickers) do
    GenServer.start_link(__MODULE__, {0, venue_name, tickers, []})
  end

  def handle_call(:tickers, _from, {_, _, tickers, _} = state) do
    {:reply, tickers, state}
  end

  def handle_call({:add_ticker, ticker}, _from, {num_orders, venue, tickers, orders}) do
    {:reply, tickers ++ [ticker], {num_orders, venue, tickers ++ [ticker], orders}}
  end

  def handle_call({:order_status, order_id, account}, _from, {_, _, _, orders} = state) do
    order =
      orders
      |> Enum.filter(fn order -> order.id == order_id end)
      |> List.first

    if order.account == account do
      {:reply, {:ok, order}, state}
    else
      {:reply, {:error, "Only account owner can access that order"}, state}
    end
  end

  def handle_call({:cancel_order, order_id, account}, _from, {num_orders, venue, tickers, orders}) do
    order_to_cancel =
      orders
      |> Enum.filter(fn order -> order.id == order_id end)
      |> List.first

    cond do
      order_id > num_orders ->
        {:reply, {:error, "Highest order id is #{num_orders}"}, {num_orders, venue, tickers, orders}}
      order_to_cancel.account == account ->
        new_orders = orders |> Enum.reject(fn order -> order.id == order_id end)
        cancelled_order = %{order_to_cancel | open: false}
        {:reply, {:ok, "Order cancelled"}, {num_orders, venue, tickers, new_orders ++ [cancelled_order]}}
      order_to_cancel.account != account ->
        {:reply, {:error, "Only account " <> order_to_cancel.account <> " can cancel that order"}, {num_orders, venue, tickers, orders}}
    end
  end

  def handle_call({:place_order, %{direction: direction, account: account, symbol: symbol, qty: qty, order_type: order_type, price: price} = _order_info}, _from, {num_orders, venue, tickers, orders}) do
    order_id = num_orders + 1
    order = %Order{id: order_id, direction: direction, venue: venue,
                   account: account, symbol: symbol, original_qty: qty,
                   price: price, order_type: order_type, ts: get_timestamp}

    new_orders = process_order(order, orders)

    {:reply, {:ok, order}, {num_orders + 1, venue, tickers, new_orders}}
  end

  def handle_call({:order_book, symbol}, _from, {num_orders, venue, tickers, all_orders}) do
    orders =
      all_orders
      |> Enum.filter(fn order ->
        order.symbol == symbol
      end)
      |> Enum.filter(fn order ->
        order.open
      end)

    bids =
      orders
      |> Enum.filter(fn order ->
        order.direction == "buy"
      end)
      |> Enum.sort(&(&1.price > &2.price))
      |> Enum.map(fn order ->
        %OrderbookEntry{price: order.price, qty: Order.quantity_remaining(order), is_buy: true}
      end)
      |> consolidate_entries
      |> Enum.map(fn order ->
        %{"price" => order.price, "qty" => order.qty, "isBuy" => order.is_buy}
      end)

    asks =
      orders
      |> Enum.filter(fn order ->
        order.direction == "sell"
      end)
      |> Enum.sort(&(&1.price < &2.price))
      |> Enum.map(fn order ->
        %OrderbookEntry{price: order.price, qty: Order.quantity_remaining(order), is_buy: false}
      end)
      |> consolidate_entries
      |> Enum.map(fn order ->
        %{"price" => order.price, "qty" => order.qty, "isBuy" => order.is_buy}
      end)

    order_book = %{"ok" => true, "venue" => venue, "symbol" => symbol, "bids" => bids, "asks" => asks, "ts" => get_timestamp}

    {:reply, {:ok, order_book}, {num_orders, venue, tickers, all_orders}}
  end

  defp consolidate_entries(entries) do
    modified_entries =
      Enum.reduce(entries, [], fn(entry, acc) ->
        like_entries =
          Enum.filter(entries, fn other_entry ->
             other_entry.price == entry.price
          end)

        total_qty =
          Enum.reduce(like_entries, 0, fn(like_entry, qty) ->
            qty + like_entry.qty
          end)

        acc ++ [%OrderbookEntry{price: entry.price, qty: total_qty, is_buy: entry.is_buy}]
      end)

    modified_entries |> Enum.uniq
  end

  defp process_order(%Order{order_type: order_type} = order, orders) do
    process_order(order, order_type, orders)
  end

  defp process_order(order, "market", orders) do
    case order.direction do
      "buy" ->
        sell_orders =
          orders
          |> Enum.filter(fn ord ->
            ord.symbol == order.symbol
          end)
          |> Enum.filter(fn ord ->
            ord.direction == "sell"
          end)
          |> Enum.filter(fn ord ->
            ord.open
          end)
          |> Enum.sort(&(&1.price < &2.price))

        remaining_orders = orders -- sell_orders
        new_orders = sell_orders |> execute_market_order(order)
        remaining_orders ++ new_orders
      "sell" ->
        buy_orders =
          orders
          |> Enum.filter(fn ord ->
            ord.symbol == order.symbol
          end)
          |> Enum.filter(fn ord ->
            ord.direction == "buy"
          end)
          |> Enum.filter(fn ord ->
            ord.open
          end)
          |> Enum.sort(&(&1.price > &2.price))

        remaining_orders = orders -- buy_orders
        new_orders = buy_orders |> execute_market_order(order)
        remaining_orders ++ new_orders
    end
  end

  defp process_order(order, _order_type, orders) do
    orders ++ [order]
  end

  defp execute_market_order(sell_orders, order) do
    execute_market_order(sell_orders, order, [], Order.quantity_remaining(order))
  end

  defp execute_market_order([], order, updated_orders, _quantity_remaining) do
    updated_orders ++ [Order.close(order)]
  end

  defp execute_market_order(sell_orders, order, updated_orders, 0) do
    sell_orders ++ updated_orders ++ [order]
  end

  defp execute_market_order([h|t] = _orders, order, updated_orders, _quantity_remaining) do
    qty_available_from_match = Order.quantity_remaining(h)
    qty_remaining_to_trade = Order.quantity_remaining(order)

    qty_to_purchase = calculate_fill_quantity(qty_remaining_to_trade, qty_available_from_match)

    # settle at the fills
    fill = %Fill{price: h.price, qty: qty_to_purchase, ts: get_timestamp}

    updated_order = Order.add_fill_to_order(order, fill)
    updated_matching_order = Order.add_fill_to_order(h, fill)

    execute_market_order(t, updated_order, updated_orders ++ [updated_matching_order], Order.quantity_remaining(updated_order))
  end

  defp calculate_fill_quantity(qty_remaining, qty_available) do
    if qty_remaining < qty_available do
      qty_remaining
    else
      qty_available
    end
  end

  defp get_timestamp do
    {:ok, timestamp} = Timex.Date.now |> Timex.DateFormat.format("{ISOz}")
    timestamp
  end
end
