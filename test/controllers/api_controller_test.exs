defmodule Stackfooter.ApiControllerTest do
  use Stackfooter.ConnCase

  test "API Heartbeat", %{conn: conn} do
    conn = get(conn, "/ob/api/heartbeat")
    resp = json_response(conn, 200)

    assert resp
    assert resp["ok"]
    assert resp["error"] == ""
  end
end
