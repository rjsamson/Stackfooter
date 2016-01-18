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
    IO.inspect conn
    {:ok, orderbook} = Venue.order_book(conn.assigns[:venue], stock)
    conn |> json(orderbook)
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
