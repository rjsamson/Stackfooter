defmodule Stackfooter.ScoreControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.{Venue, VenueRegistry, ApiKeyRegistry}

  @admin_apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"
  @non_admin_apikey "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0"

  setup_all do
    ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0", "rjsamson1234")

    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)

    Enum.each(4200..4211, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Enum.each(4220..4231, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "admin", orderType: "limit"})
    end)

    Enum.each(4200..4210, fn x ->
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "account2", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "account2", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "account2", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "account2", orderType: "limit"})
    end)

    :ok
  end

  test "all scores route is unauthenticated" do
    conn = get(conn(), "/ob/api/scores")

    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
  end

  test "individual scores route is authenticated" do
    conn = put_req_header(conn(), "x-starfighter-authorization", @admin_apikey)
    |> get("/ob/api/scores/admin")

    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]

    conn = get(conn(), "/ob/api/scores/admin")

    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]

    conn = put_req_header(conn(), "x-starfighter-authorization", @non_admin_apikey)
    |> get("/ob/api/scores/admin")

    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
  end
end
