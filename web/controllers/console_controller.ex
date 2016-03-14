defmodule Stackfooter.ConsoleController do
  use Stackfooter.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", api_key: "1234567"
  end
end
