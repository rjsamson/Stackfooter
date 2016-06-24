defmodule Stackfooter.ScoreControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.{Venue, VenueRegistry, ApiKeyRegistry, SettlementDesk}

  @admin_apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"
  @non_admin_apikey "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0"

  setup_all do
    ApiKeyRegistry.add_key(Stackfooter.ApiKeyRegistry, "KVi7irGjY8ZhYg6B20QU7H6IIbhWmyt0", "rjsamson1234")

    {:ok, venue} = VenueRegistry.lookup(Stackfooter.VenueRegistry, "OBEX")
    Venue.reset(venue)
    SettlementDesk.reset_accounts(SettlementDesk)

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
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "sell", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    Enum.each(4220..4230, fn x ->
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
      :timer.sleep(20)
      Venue.place_order(venue, %{direction: "buy", symbol: "NYC", qty: 7, price: x, account: "rjsamson", orderType: "limit"})
    end)

    :ok
  end

  test "returns the correct score for all users" do
    scores = [%{"cash" => 1176, "name" => "A", "nav" => 1176, "positions" => [%{"price" => 4225, "qty" => 0, "stock" => "NYC"}]},
              %{"cash" => -1176, "name" => "RJSA", "nav" => -1176, "positions" => [%{"price" => 4225, "qty" => 0, "stock" => "NYC"}]}]

    conn = get(build_conn(), "/ob/api/scores")
    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
    assert resp["scores"] == scores
  end

  test "returns the correct score for an individual user" do
    conn = put_req_header(build_conn(), "x-starfighter-authorization", @admin_apikey)
    |> get("/ob/api/scores/admin")
    resp = json_response(conn, 200)

    account_score = %{"cash" => 1176, "name" => "ADMIN", "nav" => 1176, "positions" => [%{"price" => 4225, "qty" => 0, "stock" => "NYC"}]}

    assert resp
    assert resp["ok"]
    assert resp["account"] == account_score
  end

  test "all scores route is unauthenticated" do
    conn = get(build_conn(), "/ob/api/scores")

    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
  end

  test "individual scores route is authenticated" do
    conn = put_req_header(build_conn(), "x-starfighter-authorization", @admin_apikey)
    |> get("/ob/api/scores/admin")

    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]

    conn = get(build_conn(), "/ob/api/scores/admin")

    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]

    conn = put_req_header(build_conn(), "x-starfighter-authorization", @non_admin_apikey)
    |> get("/ob/api/scores/admin")

    resp = json_response(conn, 401)

    assert resp
    refute resp["ok"]
  end
end
