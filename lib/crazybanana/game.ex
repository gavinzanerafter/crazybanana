defmodule Crazybanana.Game do
  use GenServer

  defstruct [
    id: nil,
    players: [],
    winner: nil,
    state: nil
  ]

  def join(id, player) do
    GenServer.call(via_tuple(id), {:join, player})
  end

  def init(id) do
    game = %__MODULE__{
      id: id,
      players: [],
      winner: nil,
      state: :waiting
    }

    {:ok, game}
  end

  def start_link(id) do
    GenServer.start_link(__MODULE__, id, name: via_tuple(id))
  end

  def handle_call({:join, player}, _from, game) do
    {:reply, {:ok, game.state}, %{game | players: [player | game.players]}}
  end

  def handle_call(:get_data, _from, game) do
    {:reply, game, game}
  end

  defp via_tuple(id) do
    {:via, Registry, {:game_registry, id}}
  end
end
