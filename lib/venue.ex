defmodule Stackfooter.Venue do
  alias Stackfooter.Order
  alias Stackfooter.Order.Fill
  alias Stackfooter.Venue.StockProcessor
  alias Stackfooter.ApiKeyRegistry

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

  def add_ticker(pid, ticker_info), do: GenServer.call(pid, {:add_ticker, ticker_info})

  def get_quote(pid, symbol), do: GenServer.call(pid, {:get_quote, String.upcase(symbol)})

  def heartbeat(pid), do: GenServer.call(pid, :heartbeat)

  def update_quote(pid, stock_quote, symbol), do: GenServer.cast(pid, {:update_quote, stock_quote, symbol})

  def reset(pid), do: GenServer.cast(pid, :reset_venue)

  def start_link(venue_name, tickers) do
    last_executions =
      Enum.reduce(tickers, %{}, fn(ticker, acc) ->
        fill = %Fill{price: ((:rand.uniform(50) + 20) * 100), qty: (:rand.uniform(50) + 20), ts: get_timestamp}
        Map.put(acc, ticker.symbol, fill)
      end)

    GenServer.start_link(__MODULE__, {0, last_executions, venue_name, tickers, [], [], %{}}, name: String.to_atom(venue_name))
  end

  def handle_call(:heartbeat, _from, {_, _, venue, _, _, _, _} = state) do
    {:reply, {:ok, %{ok: true, venue: venue}}, state}
  end

  def handle_call(:tickers, _from, {_, _, _, tickers, _, _, _} = state) do
    {:reply, {:ok, tickers}, state}
  end

  def handle_call({:add_ticker, %{symbol: symbol, name: name}}, _from, {num_orders, last_execution, venue, tickers, closed_orders, open_orders, stock_quotes}) do
    ticker = %Ticker{symbol: String.upcase(symbol), name: name}
    new_tickers = [ticker] ++ tickers
    {:reply, {:ok, new_tickers}, {num_orders, last_execution, venue, new_tickers, closed_orders, open_orders, stock_quotes}}
  end

  def handle_call({:get_quote, symbol}, _from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, stock_quotes} = state) do

    stock_quote = case Map.get(stock_quotes, symbol, :error)  do
      :error ->
        last_execution = last_executions[symbol]
        generate_quote(open_orders, last_execution, symbol, venue) |> Map.put("ok", true)
      retrieved_quote ->
        retrieved_quote
    end

    {:reply, {:ok, stock_quote}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, Map.put(stock_quotes, symbol, stock_quote)}}
  end

  def handle_call({:order_status, order_id, account}, from, {num_orders, _, venue, _, closed_orders, open_orders, _stock_quotes} = state) do
    spawn(fn ->
      order =
        open_orders
        |> Enum.find(fn order -> order.id == order_id end)

      if order == nil do
        order =
          closed_orders
          |> Enum.find(fn order -> order.id == order_id end)
      end

      cond do
        order_id >= num_orders || order_id < 0 ->
          GenServer.reply(from, {:error, %{ok: false, error: "Highest order id is #{num_orders}"}})
        order.account == account ->
          order_fills =
            order.fills
            |> Enum.map(fn fill -> %{price: fill.price, qty: fill.qty, ts: fill.ts} end)

          order_status = %{ok: true, symbol: order.symbol, venue: venue, direction: order.direction, originalQty: order.originalQty, qty: Order.quantity_remaining(order), price: order.price, orderType: order.orderType, id: order.id, account: order.account, ts: order.ts, fills: order_fills, totalFilled: order.totalFilled, open: order.open}

          GenServer.reply(from, {:ok, order_status})
        true ->
          GenServer.reply(from, {:error, %{ok: false, error: "Only account owner can access that order"}})
      end
    end)

    {:noreply, state}
  end

  def handle_call({:all_orders, account}, from, {_, _, _, _, closed_orders, open_orders, _stock_quotes} = state) do
    spawn(fn ->
      closed =
        closed_orders
        |> Enum.filter(fn order -> order.account == account end)

      open =
        open_orders
        |> Enum.filter(fn order -> order.account == account end)

      GenServer.reply(from, {:ok, open ++ closed})
    end)

    {:noreply, state}
  end

  def handle_call({:all_orders_stock, account, stock}, from, {_, _, _, _, closed_orders, open_orders, _stock_quotes} = state) do
    spawn(fn ->
      closed =
        closed_orders
        |> Enum.filter(fn order -> order.account == account && order.symbol == stock end)

      open =
        open_orders
        |> Enum.filter(fn order -> order.account == account && order.symbol == stock end)

      GenServer.reply(from, {:ok, open ++ closed})
    end)

    {:noreply, state}
  end

  def handle_call({:cancel_order, order_id, account}, from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, stock_quotes} = state) do
    order_to_cancel =
      open_orders
      |> Enum.find(fn order -> order.id == order_id end)

    cond do
      order_id >= num_orders || order_id < 0 ->
        {:reply, {:error, %{"ok" => false, "error" => "Highest order id is #{num_orders}"}}, state}
      order_to_cancel == nil ->
        spawn(fn ->
          cancelled_order =
            closed_orders
            |> Enum.find(fn order -> order.id == order_id end)

          GenServer.reply(from, {:ok, cancelled_order})
        end)

        {:noreply, state}
      order_to_cancel.account == account ->
        new_open_orders = open_orders |> Enum.reject(fn order -> order.id == order_id end)
        cancelled_order = %{order_to_cancel | open: false}

        symbol = cancelled_order.symbol

        stock_quote = Map.get(stock_quotes, symbol)
        stock_quote = update_stock_quote_from_cancellation(stock_quote, cancelled_order)

        ticker_quote = %{"ok" => true, "quote" => stock_quote}

        # Uncomment for documented behavior (instead of observed behavior)
        #
        # all_accounts = ApiKeyRegistry.all_account_names(ApiKeyRegistry)
        # for acct <- all_accounts do
        #   Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{acct}-#{venue}", {:ticker, ticker_quote}
        #   Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{acct}-#{venue}-#{symbol}", {:ticker, ticker_quote}
        # end

        Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{venue}", {:ticker, ticker_quote}
        Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{venue}-#{symbol}", {:ticker, ticker_quote}

        {:reply, {:ok, cancelled_order}, {num_orders, last_executions, venue, tickers, [cancelled_order] ++ closed_orders, new_open_orders, Map.put(stock_quotes, symbol, stock_quote)}}
      order_to_cancel.account != account ->
        {:reply, {:error, %{"ok" => false, "error" => "Not authorized to delete that order.  You have to own account  #{order_to_cancel.account}."}}, state}
    end
  end

  def handle_call({:place_order, %{direction: direction, account: account, symbol: symbol, qty: qty, orderType: orderType, price: price} = _order_info}, _from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, stock_quotes}) do
    account = String.upcase(account)
    symbol = String.upcase(symbol)
    venue = String.upcase(venue)
    direction = String.downcase(direction)
    orderType = String.downcase(orderType)

    order = %Order{id: num_orders, direction: direction, venue: venue,
                   account: String.upcase(account), symbol: symbol, originalQty: qty,
                   price: price, orderType: orderType, ts: get_timestamp, qty: qty}

    {new_order, new_open_orders, new_closed_orders, new_last_executions} = process_order(order, open_orders, last_executions)

    new_last_execution = new_last_executions[symbol]

    stock_quote = generate_quote(new_open_orders, new_last_execution, symbol, venue)
    ticker_quote = %{"ok" => true, "quote" => stock_quote}

    # Uncomment for documented behavior (instead of observed behavior)
    #
    # all_accounts = ApiKeyRegistry.all_account_names(ApiKeyRegistry)
    # for acct <- all_accounts do
    #   Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{acct}-#{venue}", {:ticker, ticker_quote}
    #   Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{acct}-#{venue}-#{symbol}", {:ticker, ticker_quote}
    # end

    Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{venue}", {:ticker, ticker_quote}
    Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{venue}-#{symbol}", {:ticker, ticker_quote}

    {:reply, {:ok, new_order}, {num_orders + 1, new_last_executions, venue, tickers, new_closed_orders ++ closed_orders, new_open_orders, Map.put(stock_quotes, symbol, stock_quote)}}
  end

  def handle_call({:order_book, symbol}, from, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, stock_quotes} = state) do
    spawn(fn ->
      bids =
        open_orders
        |> Enum.filter(fn order ->
          order.direction == "buy" && order.symbol == symbol
        end)
        |> Enum.sort(&(&1.ts > &2.ts))
        |> Enum.sort(&(&1.price > &2.price))
        |> Enum.map(fn order ->
          %OrderbookEntry{price: order.price, qty: order.qty, isBuy: true}
        end)

      asks =
        open_orders
        |> Enum.filter(fn order ->
          order.direction == "sell" && order.symbol == symbol
        end)
        |> Enum.sort(&(&1.ts > &2.ts))
        |> Enum.sort(&(&1.price < &2.price))
        |> Enum.map(fn order ->
          %OrderbookEntry{price: order.price, qty: order.qty, isBuy: false}
        end)

      order_book = %{"ok" => true, "venue" => venue, "symbol" => symbol, "bids" => bids, "asks" => asks, "ts" => get_timestamp}

      GenServer.reply(from, {:ok, order_book})
    end)

    {:noreply, state}
  end

  def handle_cast(:reset_venue, {_num_orders, _last_executions, venue, tickers, _closed_orders, _open_orders, _stock_quotes}) do
    new_last_executions =
      Enum.reduce(tickers, %{}, fn(ticker, acc) ->
        fill = %Fill{price: ((:rand.uniform(50) + 20) * 100), qty: (:rand.uniform(50) + 20), ts: get_timestamp}
        Map.put(acc, ticker.symbol, fill)
      end)

    {:noreply, {0, new_last_executions, venue, tickers, [], [], %{}}}
  end

  def handle_cast({:update_quote, stock_quote, symbol}, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, stock_quotes}) do
    {:noreply, {num_orders, last_executions, venue, tickers, closed_orders, open_orders, Map.put(stock_quotes, symbol, stock_quote)}}
  end

  # defp consolidate_entries(entries) do
  #   Enum.reduce(entries, %{}, fn(entry, acc) ->
  #     total_entry = Map.get(acc, entry.price, %OrderbookEntry{qty: 0})
  #     qty = entry.qty + total_entry.qty
  #     Map.put(acc, entry.price, %OrderbookEntry{price: entry.price, qty: qty, isBuy: entry.isBuy})
  #   end)
  #   |> Map.values
  # end

  defp update_stock_quote_from_cancellation(stock_quote, cancelled_order) do
    symbol = cancelled_order.symbol

    if cancelled_order.direction == "buy" do
      new_bid_size = stock_quote["bidSize"] - cancelled_order.qty
      new_bid_depth = stock_quote["bidDepth"] - cancelled_order.qty

      %{stock_quote | "bidSize" => new_bid_size, "bidDepth" => new_bid_depth, "quoteTime" => get_timestamp}
    else
      new_ask_size = stock_quote["askSize"] - cancelled_order.qty
      new_ask_depth = stock_quote["askDepth"] - cancelled_order.qty

      %{stock_quote | "askSize" => new_ask_size, "askDepth" => new_ask_depth, "quoteTime" => get_timestamp}
    end
  end

  defp generate_quote(open_orders, last_execution, symbol, venue) do
    bid_info = bid_ask_info(open_orders, symbol, "buy")
    ask_info = bid_ask_info(open_orders, symbol, "sell")

    stock_quote = %{"symbol" => symbol, "venue" => venue,
              "bidSize" => bid_info[:size],
              "askSize" => ask_info[:size], "bidDepth" => bid_info[:depth],
              "askDepth" => ask_info[:depth], "last" => last_execution.price,
              "lastSize" => last_execution.qty, "lastTrade" => last_execution.ts,
              "quoteTime" => get_timestamp}

    stock_quote =
      case bid_info[:price] do
        0 ->
          stock_quote
        _ ->
          Map.put(stock_quote, "bid", bid_info[:price])
      end

    stock_quote =
      case ask_info[:price] do
        0 ->
          stock_quote
        _ ->
          Map.put(stock_quote, "ask", ask_info[:price])
      end

    stock_quote
  end

  defp process_order(%Order{orderType: orderType} = order, orders, last_fills) do
    process_order(order, orderType, orders, last_fills)
  end

  defp process_order(order, "market", orders, last_fills) do
    order = %{order | price: 0}
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
    |> Enum.sort(&(&1.ts > &2.ts))
    |> sort_direction(direction)
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
        |> Enum.sort(&(&1.ts > &2.ts))
        |> sort_direction("buy")
      "sell" ->
        get_open_matching_orders(orders, order) |> Enum.filter(fn ord ->
          ord.price <= order.price
        end)
        |> Enum.sort(&(&1.ts > &2.ts))
        |> sort_direction("sell")
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

    fill = %Fill{price: price, qty: qty_to_execute, ts: get_timestamp}

    {buy_account, sell_account} = get_buy_sell_accounts(order, h)
    transaction = %{buy_account: buy_account, sell_account: sell_account, stock: order.symbol, fill: fill}
    :ok = Stackfooter.SettlementDesk.settle_transaction(Stackfooter.SettlementDesk, transaction)

    updated_order = Order.add_fill_to_order(order, fill)
    updated_matching_order = Order.add_fill_to_order(h, fill)

    standing_id = updated_matching_order.id
    incoming_id = updated_order.id
    standing_complete = !updated_matching_order.open
    incoming_complete = !updated_order.open
    account1 = String.upcase(updated_order.account)
    account2 = String.upcase(updated_matching_order.account)
    venue = String.upcase(updated_order.venue)
    symbol = String.upcase(updated_order.symbol)

    exec_info = [%{account: account1, order: updated_order}] ++ [%{account: account2, order: updated_matching_order}]

    for info <- exec_info do
      execution_stream = %{"ok" => true, "account" => info[:account], "venue" => venue,
        "symbol" => symbol, "order" => Order.order_map_with_ok(info[:order]),
        "standingId" => standing_id, "incomingId" => incoming_id, "price" => fill.price,
        "filled" => fill.qty, "filledAt" => fill.ts, "standingComplete" => standing_complete,
        "incomingComplete" => incoming_complete}

      Phoenix.PubSub.broadcast Stackfooter.PubSub, "executions:#{info[:account]}-#{venue}-#{symbol}", {:execution, execution_stream}
      Phoenix.PubSub.broadcast Stackfooter.PubSub, "executions:#{info[:account]}-#{venue}", {:execution, execution_stream}
    end

    last_fills = Map.put(last_fills, order.symbol, fill)

    if updated_matching_order.open do
      execute_order_fill(t, updated_order, [updated_matching_order] ++ updated_orders, closed_orders, Order.quantity_remaining(updated_order), last_fills)
    else
      execute_order_fill(t, updated_order, updated_orders, [updated_matching_order] ++ closed_orders, Order.quantity_remaining(updated_order), last_fills)
    end
  end

  defp get_buy_sell_accounts(order1, order2) do
    case order1.direction do
      "buy" ->
        {order1.account, order2.account}
      "sell" ->
        {order2.account, order1.account}
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

  defp get_bid_ask_price(orders, symbol, direction) do
    filtered_orders =
      orders
      |> Enum.filter(fn ord ->
        ord.open && ord.symbol == symbol && ord.direction == direction
      end)
      |> sort_direction(direction)

    do_get_bid_ask_price(filtered_orders)
  end

  defp bid_ask_info(orders, symbol, direction) do
    filtered_orders =
      orders
      |> Enum.filter(fn ord ->
        ord.open && ord.symbol == symbol && ord.direction == direction
      end)
      |> sort_direction(direction)

    bid_ask_price = do_get_bid_ask_price(filtered_orders)
    bid_ask_depth = order_quantity(filtered_orders)
    bid_ask_size =
      filtered_orders
      |> Enum.filter(fn ord ->
        ord.price == bid_ask_price
      end)
      |> order_quantity

    %{price: bid_ask_price, size: bid_ask_size, depth: bid_ask_depth}
  end

  defp do_get_bid_ask_price([]) do
    0
  end

  defp do_get_bid_ask_price([order|_t]) do
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
