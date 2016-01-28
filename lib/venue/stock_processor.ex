defmodule Stackfooter.Venue.StockProcessor do
  alias Stackfooter.Order

  def start_link(open_orders, last_execution, symbol, venue, account) do
    Task.start_link(__MODULE__, :process_quote, [open_orders, last_execution, symbol, venue, account])
  end

  def process_quote(open_orders, last_execution, symbol, venue, account) do
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

    ticker_quote = %{"ok" => true, "quote" => stock_quote}

    Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{account}-#{venue}", {:ticker, ticker_quote}
    Phoenix.PubSub.broadcast Stackfooter.PubSub, "tickers:#{account}-#{venue}-#{symbol}", {:ticker, ticker_quote}

    Process.exit(self, :normal)
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

  defp sort_direction(orders, direction) do
    case direction do
      "buy" ->
        orders |> Enum.sort(&(&1.price > &2.price))
      "sell" ->
        orders |> Enum.sort(&(&1.price < &2.price))
    end
  end
end
