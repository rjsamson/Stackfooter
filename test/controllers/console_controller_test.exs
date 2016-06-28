defmodule Stackfooter.ConsoleControllerTest do
  use Stackfooter.ConnCase
  alias Stackfooter.UserAuth

  @apikey "4cy7uf63Lw2Sx6652YmLwBKy662weU4q"

  @session Plug.Session.init(
      store: :cookie,
      key: "_app",
      encryption_salt: "yadayada",
      signing_salt: "yadayada"
    )

  setup config do
    reset_api_keys()

    cond do
      config[:no_login] ->
        {:ok, conn: build_conn()}
      %{username: username, password: password} = config[:login_as] ->
        user = insert_user(username: username, api_keys: [@apikey], password: password)

        conn = Plug.Session.call(build_conn(), @session) |> fetch_session()
        {:ok, conn} = UserAuth.login_by_username_and_pass(conn, username, password, repo: Repo)

        {:ok, conn: conn, user: user}
      true ->
        {:ok, conn: build_conn()}
    end
  end

  @tag no_login: true
  test "Redirects if not authenticated", %{conn: conn} do
    conn = get(conn, "/console")
    assert redirected_to(conn) == session_path(conn, :new)
  end

  @tag login_as: %{username: "rjsamson1234", password: "password"}
  test "Trade path is authenticated", %{conn: conn, user: _user} do
    conn = get(conn, "/console")
    assert html_response(conn, 200) =~ "rjsamson1234"
  end
end
