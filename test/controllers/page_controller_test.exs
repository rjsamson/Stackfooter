defmodule Stackfooter.PageControllerTest do
  use Stackfooter.ConnCase

  setup_all do
    reset_api_keys()
    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Stackfooter"
  end
end
