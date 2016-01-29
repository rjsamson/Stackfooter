defmodule Stackfooter.PageController do
  use Stackfooter.Web, :controller

  def index(conn, _params) do
    put_layout(conn, false)
    |> render("index.html")
  end
end
