defmodule Stackfooter.VenueController do
  alias Stackfooter.Venue
  use Stackfooter.Web, :controller

  def heartbeat(conn, %{"venue" => venue}) do
    venue_atom = String.upcase(venue) |> String.to_atom

    try do
      {:ok, %{venue: hb_venue}} = Venue.heartbeat(venue_atom)
      render conn, "heartbeat.json", %{venue: String.upcase(hb_venue)}
    catch
      _,_ ->
        put_status(conn, 404)
        |> render("heartbeat.json", %{error: "404", venue: String.upcase(venue)})
    end
  end

  def stocks(conn, %{"venue" => venue}) do
    venue_atom = String.upcase(venue) |> String.to_atom

    try do
      {:ok, tickers} = Venue.tickers(venue_atom)
      render conn, "stocks.json", %{tickers: tickers}
    catch
      _,_ ->
        put_status(conn, 404)
        |> render("heartbeat.json", %{error: "404", venue: String.upcase(venue)})
    end
  end

  # defp check_venue(conn, _params) do
  #   %{"venue" => venue} = conn.params
  #   venue_atom = String.upcase(venue) |> String.to_atom
  #
  #   try do
  #     {:ok, %{venue: hb_venue}} = Venue.heartbeat(venue_atom)
  #     conn
  #   catch
  #     _,_ ->
  #       render conn, "heartbeat.json", %{error: "404", venue: String.upcase(venue)}
  #       halt(conn)
  #   end
  # end
end
