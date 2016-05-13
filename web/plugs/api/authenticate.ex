defmodule Stackfooter.Plugs.Api.Authenticate do
  use Stackfooter.Web, :controller
  alias Stackfooter.ApiKeyRegistry
  alias Stackfooter.Repo

  def init(options) do
    options
  end

  def call(conn, _) do
    token = case get_req_header(conn, "x-starfighter-authorization") do
      [token|_t] ->
        token
      _ ->
        if api_key = get_session(conn, :api_key) do
          api_key
        else
          nil
        end
    end

    case ApiKeyRegistry.lookup(ApiKeyRegistry, token) do
      {:ok, "ADMIN" = account} ->
        conn |> assign(:account, account) |> assign(:is_admin, true)
      {:ok, account} ->
        conn |> assign(:account, account) |> assign(:is_admin, false)
      :error ->
        put_status(conn, 401) |> json(%{ok: false, error: "Invalid API key."}) |> halt()
    end
  end
end
