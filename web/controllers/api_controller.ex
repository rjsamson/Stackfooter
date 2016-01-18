defmodule Stackfooter.ApiController do
  use Stackfooter.Web, :controller

  def heartbeat(conn, _params) do
    conn |> json(%{"ok" => true, "error" => ""})
  end
