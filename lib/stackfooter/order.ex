defmodule Stackfooter.Order do
  defmodule Fill do
    defstruct price: 0, qty: 0, ts: ""
  end

  defstruct symbol: "", venue: "", direction: "", originalQty: 0, price: 0, orderType: "", id: 0, account: "", ts: "", totalFilled: 0, open: true, fills: []

  def quantity_remaining(order) do
    order.originalQty - order.totalFilled
  end

  def close(order) do
    %{order | open: false}
  end

  def add_fill_to_order(order, fill) do
    updated_order_fills = order.fills ++ [fill]
    updated_order_total_filled = order.totalFilled + fill.qty
    updated_order_open = !(order.originalQty == updated_order_total_filled)

    %{order | fills: updated_order_fills, totalFilled: updated_order_total_filled, open: updated_order_open}
  end

  def calculate_total_filled(order) do
    filled = Enum.reduce(order.fills, 0, fn(fill, acc) ->
      fill.qty + acc
    end)

    filled
  end
end
