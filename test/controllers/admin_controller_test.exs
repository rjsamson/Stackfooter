defmodule Stackfooter.AdminControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.{Venue, VenueRegistry, ApiKeyRegistry}

  @admin_apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"
  @non_admin_apikey "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0"

  setup_all do
    ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0", "rjsamson1234")

    :ok
  end

  setup do
    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Enum.each(4200..4201, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Enum.each(4220..4221, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    :ok
  end

  test "resets a venue" do
    conn = put_req_header(conn(), "x-starfighter-authorization", @admin_apikey)
    |> post("/ob/api/admin/reset/obex")

    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
  end

  test "only admin account can perform admin actions" do
    conn = put_req_header(conn(), "x-starfighter-authorization", @non_admin_apikey)
    |> post("/ob/api/admin/reset/obex")

    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "Invalid API key for that action."
  end

  test "errors properly when a venue does not exist" do
    conn = put_req_header(conn(), "x-starfighter-authorization", @admin_apikey)
    |> post("/ob/api/admin/reset/notavenue")

    resp = json_response(conn, 404)

    assert resp
    refute resp["ok"]
    assert resp["error"] == "No venue exists with the symbol NOTAVENUE."
  end
end
