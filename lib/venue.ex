defmodule Stackfooter.Venue do
  alias Stackfooter.Order
  alias Stackfooter.Order.Fill

  use GenServer

  defmodule OrderbookEntry do
    defstruct price: 0, qty: 0, isBuy: true
  end

  defmodule Ticker do
    defstruct name: "", symbol: ""
  end

  def place_order(pid, order), do: GenServer.call(pid, {:place_order, order})

  def order_book(pid, symbol), do: GenServer.call(pid, {:order_book, String.upcase(symbol)})

  def cancel_order(pid, order_id, account), do: GenServer.call(pid, {:cancel_order, order_id, String.upcase(account)})

  def order_status(pid, order_id, account), do: GenServer.call(pid, {:order_status, order_id, String.upcase(account)})

  def all_orders(pid, account), do: GenServer.call(pid, {:all_orders, String.upcase(account)})

  def all_orders_stock(pid, account, stock), do: GenServer.call(pid, {:all_orders_stock, String.upcase(account), String.upcase(stock)})

  def tickers(pid), do: GenServer.call(pid, :tickers)

  def add_ticker(pid, ticker), do: GenServer.call(pid, {:add_ticker, String.upcase(ticker)})

  def get_quote(pid, symbol), do: GenServer.call(pid, {:get_quote, String.upcase(symbol)})

  def heartbeat(pid), do: GenServer.call(pid, :heartbeat)

  def start_link(venue_name, tickers) do
    last_executions =
      Enum.reduce(tickers, %{}, fn(ticker, acc) ->
        fill = %Fill{price: ((:random.uniform(50) + 20) * 100), qty: (:random.uniform(50) + 20), ts: get_timestamp}
        Map.put(acc, ticker.symbol, fill)
      end)

    GenServer.start_link(__MODULE__, {0, last_executions, venue_name, tickers, [], []}, name: String.to_atom(venue_name))
  end

  def handle_call(:heartbeat, _from, {_, _, venue, _, _, _} = state) do
    {:reply, {:ok, %{ok: true, venue: venue}}, state}
  end

  def handle_call(:tickers, _from, {_, _, _, tickers, _, _} = state) do
    {:reply, {:ok, tickers}, state}
  end

  def handle_call({:add_ticker, {symbol, name}}, _from, {num_orders, last_execution, venue, tickers, closed_orders, open_orders}) do
    ticker = %Ticker{symbol: symbol, name: name}
    new_tickers = [ticker] ++ tickers
    {:reply, {:ok, new_tickers}, {num_orders, last_execution, venue, new_tickers, closed_orders, open_orders}}
  end

  def handle_call({:get_quote, symbol}, _from, {_num_orders, last_executions, venue, _tickers, _closed_orders, open_orders} = state) do

    open_orders = Enum.filter(open_orders, fn order ->
      order.symbol == symbol
    end)

    last_execution = last_executions[symbol]
    bid_info = bid_ask_info(open_orders, symbol, "buy")
    ask_info = bid_ask_info(open_orders, symbol, "sell")

    stock_quote = %{"ok" => true, "symbol" => symbol, "venue" => venue,
              "bid" => bid_info[:price], "ask" => ask_info[:price], "bidSize" => bid_info[:size],
              "askSize" => ask_info[:size], "bidDepth" => bid_info[:depth],
              "askDepth" => ask_info[:depth], "last" => last_execution.price,
              "lastSize" => last_execution.qty, "lastTrade" => last_execution.ts,
              "quoteTime" => get_timestamp}

    {:reply, {:ok, stock_quote}, state}
  end

  def handle_call({:order_status, order_id, account}, _from, {_, _, venue, _, closed_orders, open_orders} = state) do
    order =
      open_orders
      |> Enum.filter(fn order -> order.id == order_id end)
      |> List.first

    if order == nil do
      order =
        closed_orders
        |> Enum.filter(fn order -> order.id == order_id end)
        |> List.first
    end

    cond do
      order == nil ->
        {:reply, {:error, %{ok: false, error: "No order with that id / account"}}, state}
      order.account == account ->
        order_fills =
          order.fills
          |> Enum.map(fn fill -> %{price: fill.price, qty: fill.qty, ts: fill.ts} end)

        order_status = %{ok: true, symbol: order.symbol, venue: venue, direction: order.direction, originalQty: order.originalQty, qty: Order.quantity_remaining(order), price: order.price, orderType: order.orderType, id: order.id, account: order.account, ts: order.ts, fills: order_fills, totalFilled: order.totalFilled, open: order.open}

        {:reply, {:ok, order_status}, state}
      true ->
        {:reply, {:error, %{ok: false, error: "Only account owner can access that order"}}, state}
    end
  end

  def handle_call({:all_orders, account}, _from, {_, _, _, _, closed_orders, open_orders} = state) do
    closed =
      closed_orders
      |> Enum.filter(fn order -> order.account == account end)

    open =
      open_orders
      |> Enum.filter(fn order -> order.account == account end)

    {:reply, {:ok, open ++ closed}, state}
  end

  def handle_call({:all_orders_stock, account, stock}, _from, {_, _, _, _, closed_orders, open_orders} = state) do
    closed =
      closed_orders
      |> Enum.filter(fn order -> order.account == account && order.symbol == stock end)

    open =
      open_orders
      |> Enum.filter(fn order -> order.account == account && order.symbol == stock end)

    {:reply, {:ok, open ++ closed}, state}
  end

  def handle_call({:cancel_order, order_id, account}, _from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}) do
    order_to_cancel =
      open_orders
      |> Enum.filter(fn order -> order.id == order_id end)
      |> List.first

    cond do
      order_id > num_orders ->
        {:reply, {:error, %{"ok" => false, "error" => "Highest order id is #{num_orders}"}}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}}
      order_to_cancel == nil ->
        cancelled_order =
          closed_orders
          |> Enum.filter(fn order -> order.id == order_id end)
          |> List.first

        {:reply, {:ok, cancelled_order}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}}
      order_to_cancel.account == account ->
        new_open_orders = open_orders |> Enum.reject(fn order -> order.id == order_id end)
        cancelled_order = %{order_to_cancel | open: false}
        {:reply, {:ok, cancelled_order}, {num_orders, last_executions, venue, tickers, [cancelled_order] ++ closed_orders, new_open_orders}}
      order_to_cancel.account != account ->
        {:reply, {:error, %{"ok" => false, "error" => "Not authorized to delete that order.  You have to own account  #{order_to_cancel.account}."}}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}}
    end
  end

  def handle_call({:place_order, %{direction: direction, account: account, symbol: symbol, qty: qty, orderType: orderType, price: price} = _order_info}, _from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}) do
    account = String.upcase(account)
    symbol = String.upcase(symbol)
    venue = String.upcase(venue)
    direction = String.downcase(direction)
    orderType = String.downcase(orderType)
    order_id = num_orders + 1

    order = %Order{id: order_id, direction: direction, venue: venue,
                   account: account, symbol: symbol, originalQty: qty,
                   price: price, orderType: orderType, ts: get_timestamp}

    {new_order, new_open_orders, new_closed_orders, new_last_executions} = process_order(order, open_orders, last_executions)

    {:reply, {:ok, new_order}, {num_orders + 1, new_last_executions, venue, tickers, new_closed_orders ++ closed_orders, new_open_orders}}
  end

  def handle_call({:order_book, symbol}, _from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}) do
    bids =
      open_orders
      |> Enum.filter(fn order ->
        order.direction == "buy" && order.symbol == symbol
      end)
      |> Enum.sort(&(&1.price > &2.price))
      |> Enum.map(fn order ->
        %OrderbookEntry{price: order.price, qty: Order.quantity_remaining(order), isBuy: true}
      end)
      |> consolidate_entries

    asks =
      open_orders
      |> Enum.filter(fn order ->
        order.direction == "sell" && order.symbol == symbol
      end)
      |> Enum.sort(&(&1.price < &2.price))
      |> Enum.map(fn order ->
        %OrderbookEntry{price: order.price, qty: Order.quantity_remaining(order), isBuy: false}
      end)
      |> consolidate_entries

    order_book = %{"ok" => true, "venue" => venue, "symbol" => symbol, "bids" => bids, "asks" => asks, "ts" => get_timestamp}

    {:reply, {:ok, order_book}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders}}
  end

  defp consolidate_entries(entries) do
    Enum.reduce(entries, %{}, fn(entry, acc) ->
      total_entry = Map.get(acc, entry.price, %OrderbookEntry{qty: 0})
      qty = entry.qty + total_entry.qty
      Map.put(acc, entry.price, %OrderbookEntry{price: entry.price, qty: qty, isBuy: entry.isBuy})
    end)
    |> Map.values
  end

  defp process_order(%Order{orderType: orderType} = order, orders, last_fills) do
    process_order(order, orderType, orders, last_fills)
  end

  defp process_order(order, "market", orders, last_fills) do
    orders |> get_open_matching_orders(order) |> execute_order(orders, order, last_fills, true)
  end

  defp process_order(order, "fill-or-kill", orders, last_fills) do
    quantity_available = matching_quantity_available(orders, order)

    if quantity_available < order.originalQty do
      closed_order = Order.close(order)
      {closed_order, orders, [closed_order], last_fills}
    else
      orders |> get_limit_matches(order) |> execute_order(orders, order, last_fills, true)
    end
  end

  defp process_order(order, "limit", orders, last_fills) do
    orders |> get_limit_matches(order) |> execute_order(orders, order, last_fills, false)
  end

  defp process_order(order, "immediate-or-cancel", orders, last_fills) do
    orders |> get_limit_matches(order) |> execute_order(orders, order, last_fills, true)
  end

  defp get_open_matching_orders(orders, order) do
    direction = matching_direction(order.direction)

    orders
    |> Enum.filter(fn ord ->
      ord.symbol == order.symbol && ord.direction == direction
    end)
    |> sort_direction(order.direction)
  end

  defp sort_direction(orders, direction) do
    case direction do
      "buy" ->
        orders |> Enum.sort(&(&1.price > &2.price))
      "sell" ->
        orders |> Enum.sort(&(&1.price < &2.price))
    end
  end

  defp get_limit_matches(orders, order) do
    direction = matching_direction(order.direction)

    case direction do
      "buy" ->
        get_open_matching_orders(orders, order) |> Enum.filter(fn ord ->
          ord.price >= order.price
        end)
      "sell" ->
        get_open_matching_orders(orders, order) |> Enum.filter(fn ord ->
          ord.price <= order.price
        end)
    end
  end

  defp execute_order(matching_orders, orders, order, last_fill, close_order) do
    remaining_orders = orders -- matching_orders
    {new_order, new_orders, closed_orders, new_last_fill} = matching_orders |> execute_order_fill(order, last_fill)
    if close_order do
      closed_order = Order.close(new_order)
      {closed_order, new_orders ++ remaining_orders, [closed_order] ++ closed_orders, new_last_fill}
    else
      if new_order.open do
        {new_order, [new_order] ++ new_orders ++ remaining_orders, closed_orders, new_last_fill}
      else
        {new_order, new_orders ++ remaining_orders, [new_order] ++ closed_orders, new_last_fill}
      end
    end
  end

  defp execute_order_fill(matching_orders, order, last_fills) do
    execute_order_fill(matching_orders, order, [], [], Order.quantity_remaining(order), last_fills)
  end

  defp execute_order_fill([], order, updated_orders, closed_orders, _quantity_remaining, last_fills) do
    {order, updated_orders, closed_orders, last_fills}
  end

  defp execute_order_fill(matching_orders, order, updated_orders, closed_orders, 0, last_fills) do
    {order, matching_orders ++ updated_orders, closed_orders, last_fills}
  end

  defp execute_order_fill([h|t] = _orders, order, updated_orders, closed_orders, _quantity_remaining, last_fills) do
    qty_available_from_match = Order.quantity_remaining(h)
    qty_remaining_to_trade = Order.quantity_remaining(order)
    qty_to_execute = calculate_fill_quantity(qty_remaining_to_trade, qty_available_from_match)
    price = h.price

    # settle at the fills
    fill = %Fill{price: price, qty: qty_to_execute, ts: get_timestamp}

    updated_order = Order.add_fill_to_order(order, fill)
    updated_matching_order = Order.add_fill_to_order(h, fill)

    last_fills = Map.put(last_fills, order.symbol, fill)

    if updated_matching_order.open do
      execute_order_fill(t, updated_order, [updated_matching_order] ++ updated_orders, closed_orders, Order.quantity_remaining(updated_order), last_fills)
    else
      execute_order_fill(t, updated_order, updated_orders, [updated_matching_order] ++ closed_orders, Order.quantity_remaining(updated_order), last_fills)
    end

  end

  defp matching_quantity_available(orders, order) do
    get_limit_matches(orders, order) |> Enum.reduce(0, fn(ord, acc) ->
      acc + Order.quantity_remaining(ord)
    end)
  end

  defp matching_direction(direction) do
    case direction do
      "buy" ->
        "sell"
      "sell" ->
        "buy"
    end
  end

  defp calculate_fill_quantity(qty_remaining, qty_available) do
    if qty_remaining < qty_available do
      qty_remaining
    else
      qty_available
    end
  end

  defp bid_ask_info(orders, symbol, direction) do
    filtered_orders =
      orders
      |> Enum.filter(fn ord ->
        ord.open && ord.symbol == symbol && ord.direction == direction
      end)
      |> sort_direction(direction)

    bid_ask_price = get_bid_ask_price(filtered_orders)
    bid_ask_depth = order_quantity(filtered_orders)
    bid_ask_size =
      filtered_orders
      |> Enum.filter(fn ord ->
        ord.price == bid_ask_price
      end)
      |> order_quantity

    %{price: bid_ask_price, size: bid_ask_size, depth: bid_ask_depth}
  end

  defp get_bid_ask_price([]) do
    0
  end

  defp get_bid_ask_price([order|_t]) do
    order.price
  end

  defp order_quantity(orders) do
    orders
    |> Enum.reduce(0, fn(order, qty) ->
       qty + Order.quantity_remaining(order)
    end)
  end

  defp get_timestamp do
    {:ok, timestamp} = Timex.Date.now |> Timex.DateFormat.format("{ISOz}")
    timestamp
  end
end
