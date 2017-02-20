defmodule Crazybanana.Game.Supervisor do
  require Logger

  use Supervisor

  def init(_) do
    children = [
      worker(Crazybanana.Game, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one, name: __MODULE__)
  end

  def start_link, do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def create_game(id) do
    Supervisor.start_child(__MODULE__, [id])
  end

  def quit_game(id) do
    pid = GenServer.whereis(via_tuple(id))
    Crazybanana.Endpoint.broadcast("game:#{id}", "shutdown", %{})
    Supervisor.terminate_child(__MODULE__, pid)
  end

  def games do
    __MODULE__
    |> Supervisor.which_children
    |> Enum.map(&data/1)
  end

  defp data({_id, pid, _type, _modules}) do
    pid
    |> GenServer.call(:get_data)
  end

  defp via_tuple(id) do
    {:via, Registry, {:game_registry, id}}
  end
end
