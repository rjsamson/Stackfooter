defmodule Stackfooter.PageControllerTest do
  use Stackfooter.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Stackfooter"
  end
end
