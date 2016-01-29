defmodule Stackfooter.VenueController do
  use Stackfooter.Web, :controller

  plug Stackfooter.Plugs.Api.Authenticate when action in [:order_status, :cancel_order, :all_orders,
                                    :all_orders_stock, :place_order]

  plug :parse_body_params when action in [:place_order]
  plug :check_venue when action in [:heartbeat, :stocks, :orderbook, :get_quote,
                                    :order_status, :cancel_order, :all_orders,
                                    :all_orders_stock, :place_order]

  alias Stackfooter.Venue
  alias Stackfooter.VenueRegistry

  def heartbeat(conn, %{"venue" => _venue}) do
    {:ok, %{venue: hb_venue}} = Venue.heartbeat(conn.assigns[:venue])
    conn |> json(%{ok: true, venue: String.upcase(hb_venue)})
  end

  def venues(conn, _params) do
    venues = VenueRegistry.all_venue_names(VenueRegistry)
    conn |> json(venues)
  end

  def stocks(conn, %{"venue" => _venue}) do
    {:ok, tickers} = Venue.tickers(conn.assigns[:venue])
    conn |> json(%{ok: true, symbols: tickers})
    # render conn, "stocks.json", %{tickers: tickers}
  end

  def orderbook(conn, %{"venue" => _venue, "stock" => stock}) do
    {:ok, orderbook} = Venue.order_book(conn.assigns[:venue], stock)
    conn |> json(orderbook)
  end

  def get_quote(conn, %{"venue" => _venue, "stock" => stock}) do
    {:ok, stock_quote} = Venue.get_quote(conn.assigns[:venue], stock)
    conn |> json(stock_quote)
  end

  def order_status(conn, %{"venue" => _venue, "stock" => _stock, "id" => order_id}) do
    case Integer.parse(order_id) do
      {val, _} ->
        order_id = val
        case Venue.order_status(conn.assigns[:venue], order_id, conn.assigns[:account]) do
          {:ok, order} ->
            order = Map.delete(order, :__struct__) |> Map.put(:ok, true)
            conn |> json(order)
          {:error, msg} -> conn |> json(msg)
        end
      :error ->
        conn |> json(%{"ok" => false, "error" => "Invalid order id. Please supply an integer"})
    end
  end

  def cancel_order(conn, %{"venue" => _venue, "stock" => _stock, "id" => order_id}) do
    case Integer.parse(order_id) do
      {val, _} ->
        order_id = val
        case Venue.cancel_order(conn.assigns[:venue], order_id, conn.assigns[:account]) do
          {:ok, cancelled_order} ->
            cancelled_order = Map.delete(cancelled_order, :__struct__) |> Map.put(:ok, true)
            conn |> json(cancelled_order)
          {:error, msg} -> conn |> json(msg)
        end
      :error ->
        conn |> json(%{"ok" => false, "error" => "Invalid order id. Please supply an integer"})
    end
  end

  def all_orders(conn, %{"venue" => venue, "account" => account}) do
    account = String.upcase(account)
    venue = String.upcase(venue)

    if account == conn.assigns[:account] do
      {:ok, orders} = Venue.all_orders(conn.assigns[:venue], account)
      conn |> json(%{"ok" => true, "venue" => venue, "orders" => orders})
    else
      conn |> put_status(401) |> json(%{"ok" => false, "error" => "Not authorized to access details about that account's orders."})
    end
  end

  def all_orders_stock(conn, %{"venue" => venue, "account" => account, "stock" => stock}) do
    account = String.upcase(account)
    venue = String.upcase(venue)
    stock = String.upcase(stock)

    if account == conn.assigns[:account] do
      {:ok, orders} = Venue.all_orders_stock(conn.assigns[:venue], account, stock)
      conn |> json(%{"ok" => true, "venue" => venue, "orders" => orders})
    else
      conn |> put_status(401) |> json(%{"ok" => false, "error" => "Not authorized to access details about that account's orders."})
    end
  end

  def place_order(conn, %{"venue" => path_venue, "stock" => path_stock} = _params) do
    path_venue = String.upcase(path_venue)
    path_stock = String.upcase(path_stock)

    account = Map.get(conn.body_params, "account")
    direction = Map.get(conn.body_params, "direction")
    order_type = Map.get(conn.body_params, "orderType")

    qty = check_integer_param(Map.get(conn.body_params, "qty", 0))
    price = check_integer_param(Map.get(conn.body_params, "price", 0))

    stock = Map.get(conn.body_params, "stock")
    venue = Map.get(conn.body_params, "venue")

    cond do
      account == nil || direction == nil || order_type == nil || !is_integer(qty) || !is_integer(price) || stock == nil || venue == nil ->
        conn |> json(%{"ok" => false, "error" => "You failed to include some required parameters for the order, or formatted the price or quantity incorrectly."})
      String.upcase(venue) != path_venue || String.upcase(stock) != path_stock ->
        conn |> json(%{"ok" => false, "error" => "Venue or stock did not match venue or stock provided in the URL."})
      true ->
        order = %{account: String.upcase(account), direction: direction, orderType: order_type, price: price, qty: qty, symbol: stock}
        {:ok, placed_order} = Venue.place_order(conn.assigns[:venue], order)
        placed_order = Map.delete(placed_order, :__struct__) |> Map.put(:ok, true)

        conn |> json(placed_order)
    end
  end

  defp check_venue(conn, _params) do
    %{"venue" => venue_str} = conn.params

    case VenueRegistry.lookup(VenueRegistry, venue_str) do
      {:ok, venue} ->
        conn |> assign(:venue, venue)
      :error ->
        put_status(conn, 404)
        |> json(%{ok: false, error: "No venue exists with the symbol #{String.upcase(venue_str)}."})
        |> halt()
    end
  end

  defp parse_body_params(conn, _params) do
    {:ok, body, _} = read_body(conn)
    keys = Map.keys(conn.body_params)

    cond do
      length(keys) > 1 && String.length(body) == 0 ->
        conn
      String.length(body) > 0 ->
        case Poison.Parser.parse(body) do
          {:ok, json} ->
            %{conn | body_params: json}
          {:error, _} ->
            conn
        end
      length(keys) == 1 ->
        json = keys |> List.first |> Poison.Parser.parse!()
        %{conn | body_params: json}
      true ->
        conn
    end
  end

  defp check_integer_param(param) do
    if is_binary(param) do
      case Integer.parse(param) do
        {parsed, _} ->
          parsed
        :error ->
          nil
      end
    else
      param
    end
  end
end
