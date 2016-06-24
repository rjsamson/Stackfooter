defmodule Stackfooter.TradeControllerTest do
  use Stackfooter.ConnCase

  @apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"

  setup config do
    reset_api_keys()

    if username = config[:login_as] do
      user = insert_user(username: username, api_keys: [@apikey])
      conn = assign(build_conn(), :current_user, user)

      {:ok, conn: conn, user: user}
    else
      {:ok, conn: build_conn()}
    end
  end

  @tag login_as: "rjsamson1234"
  test "Trade path is authenticated", %{conn: conn, user: _user} do
    conn = get(conn, "/trade")
    assert html_response(conn, 200) =~ "rjsamson1234"
  end

  test "Redirects if not authenticated", %{conn: conn} do
    conn = get(conn, "/trade")
    assert redirected_to(conn) == session_path(conn, :new)
  end
end
