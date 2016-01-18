defmodule Stackfooter.ApiKeyRegistry do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(table) do
    api_keys = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, api_keys}
  end

  def add_key(pid, api_key, account) do
    GenServer.call(pid, {:add_key, api_key, account})
  end

  def lookup(pid, api_key) when is_atom(pid) do
    case :ets.lookup(pid, api_key) do
      [{^api_key, account}] -> {:ok, account}
      [] -> :error
    end
  end

  def handle_call({:add_key, api_key, account}, _from, api_keys) do
    :ets.insert(api_keys, {api_key, account})
    {:reply, {:ok, {api_key, account}}, api_keys}
  end
end
