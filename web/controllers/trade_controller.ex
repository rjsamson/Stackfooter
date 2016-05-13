defmodule Stackfooter.TradeController do
  use Stackfooter.Web, :controller
  alias Stackfooter.VenueRegistry

  plug :authenticate_user

  def index(conn, _params) do
    username = conn.assigns.current_user.username
    venues = VenueRegistry.all_venue_names(VenueRegistry)
    IO.inspect venues
    render conn, "index.html", username: username, venues: venues
  end
end
