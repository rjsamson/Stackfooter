defmodule Stackfooter.Api.AdminController do
  use Stackfooter.Web, :controller
  alias Stackfooter.VenueRegistry
  alias Stackfooter.Venue
  alias Stackfooter.SettlementDesk

  plug Stackfooter.Plugs.Api.Authenticate
  plug Stackfooter.Plugs.Api.AuthorizeAdmin
  plug :check_venue when action in [:reset]

  def reset(conn, _params) do
    Venue.reset(conn.assigns[:venue])
    Beaker.Counter.clear()
    SettlementDesk.reset_accounts(SettlementDesk)
    conn |> json(%{"ok" => true, "error" => ""})
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
