defmodule Stackfooter.VenueController do
  use Stackfooter.Web, :controller

  plug Stackfooter.Plugs.Api.Authenticate
  plug :check_venue

  alias Stackfooter.Venue
  alias Stackfooter.VenueRegistry

  def heartbeat(conn, %{"venue" => venue}) do
    {:ok, %{venue: hb_venue}} = Venue.heartbeat(conn.assigns[:venue])
    render conn, "heartbeat.json", %{venue: String.upcase(hb_venue)}
  end

  def stocks(conn, %{"venue" => venue}) do
    {:ok, tickers} = Venue.tickers(conn.assigns[:venue])
    render conn, "stocks.json", %{tickers: tickers}
  end

  def orderbook(conn, %{"venue" => venue, "stock" => stock}) do
    {:ok, orderbook} = Venue.order_book(conn.assigns[:venue], stock)
    conn |> json(orderbook)
  end

  def get_quote(conn, %{"venue" => venue, "stock" => stock}) do
    {:ok, stock_quote} = Venue.get_quote(conn.assigns[:venue], stock)
    conn |> json(stock_quote)
  end

  def order_status(conn, %{"venue" => venue, "stock" => stock, "id" => order_id}) do
    order_id = String.to_integer(order_id)
    case Venue.order_status(conn.assigns[:venue], order_id, conn.assigns[:account]) do
      {:ok, stock_quote} -> conn |> json(stock_quote)
      {:error, msg} -> conn |> json(msg)
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
end
