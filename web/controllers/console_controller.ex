defmodule Stackfooter.ConsoleController do
  use Stackfooter.Web, :controller

  plug :authenticate_user

  def index(conn, _params) do
    key = conn.assigns.current_user.api_keys |> List.first
    render conn, "index.html", api_key: key
  end
end
