defmodule Stackfooter.VenueRegistry do
  alias Stackfooter.Venue
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def lookup(pid, name) do
    GenServer.call(pid, {:lookup, name})
  end

  def create(pid, name, tickers) do
    GenServer.cast(pid, {:create, name, tickers})
  end

  def init(:ok) do
    venue_names = %{}
    refs = %{}
    {:ok, {venue_names, refs}}
  end

  def handle_call({:lookup, name}, _from, {venue_names, _} = state) do
    {:reply, Map.fetch(venue_names, name), state}
  end

  def handle_cast({:create, name, tickers}, {venue_names, refs}) do
    if Map.has_key?(venue_names, name) do
      {:noreply, venue_names}
    else
      {:ok, pid} = Supervisor.start_child(Stackfooter.Venue.Supervisor, [String.upcase(name), tickers])
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      venue_names = Map.put(venue_names, name, pid)
      {:noreply, {venue_names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {venue_names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    venue_names = Map.delete(venue_names, name)
    {:noreply, {venue_names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
