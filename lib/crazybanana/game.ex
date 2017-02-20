defmodule Crazybanana.Game do
  use GenServer

  defstruct [
    id: nil,
    players: [],
    winner: nil,
    state: nil,
    seconds: 60,
    x: nil,
    y: nil
  ]

  def join(id, player_id) do
    GenServer.call(via_tuple(id), {:join, player_id})
  end

  def ready(id, player_id) do
    GenServer.call(via_tuple(id), {:ready, player_id})
  end

  def score(id, player_id, score) do
    GenServer.call(via_tuple(id), {:score, player_id, score})
  end

  def start(id) do
    GenServer.call(via_tuple(id), :start)
  end

  def restart(id) do
    GenServer.call(via_tuple(id), :restart)
  end

  def get_data(id) do
    GenServer.call(via_tuple(id), :get_data)
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

  def handle_call({:join, player_id}, _from, game) do
    if Enum.find(game.players, fn(x) -> x[:id] == player_id end) do
      {:reply, {:ok, game.state}, game}
    else
      player = %{
        id: player_id,
        name: player_id,
        state: :waiting,
        score: 0
      }
      {:reply, {:ok, game.state}, %{game | players: [player | game.players]}}
    end
  end

  def handle_call({:ready, player_id}, _from, game) do
    player = %{
      id: player_id,
      name: player_id,
      state: :ready,
      score: 0
    }
    players = [player | Enum.reject(game.players, fn(x) -> x[:id] == player_id end)]
    {:reply, {:ok, game.state}, %{game | players: players}}
  end

  def handle_call({:score, player_id, score}, _from, game) do
    player = %{
      id: player_id,
      name: player_id,
      state: :ready,
      score: score
    }
    players = [player | Enum.reject(game.players, fn(x) -> x[:id] == player_id end)]
    {:reply, {:ok, game.state}, %{game | players: players}}
  end

  def handle_call(:start, _from, game) do
    game = handle_start(game)
    {:reply, {:ok, :playing}, game}
  end

  def handle_call(:restart, _from, game) do
    game = handle_start(game)
    {:reply, {:ok, :playing}, game}
  end

  def handle_call(:get_data, _from, game) do
    {:reply, game, game}
  end

  def handle_info(:tick, game) do
    next = %{game | seconds: game.seconds - 1}

    next = case rem(next.seconds, 3) do
      0 -> %{next | x: next.seconds, y: next.seconds}
      _ -> next
    end

    if next.seconds > 0 do
      schedule_tick()
    else
      schedule_finish()
    end

    Crazybanana.Endpoint.broadcast("game:#{next.id}", "tick", next)

    {:noreply, next}
  end

  def handle_info(:finish, game) do
    next = %{game | seconds: 0, state: :done, x: nil, y: nil}

    Crazybanana.Endpoint.broadcast("game:#{next.id}", "game", next)

    {:noreply, next}
  end

  defp handle_start(game) do
    game = %{game | state: :playing, seconds: 60, winner: nil, x: nil, y: nil}
    game = %{game | players: Enum.map(game.players, fn(x) -> %{x | score: 0} end)}
    schedule_tick()
    game
  end

  defp schedule_tick() do
    # TODO: eventually handle the amount of time that has passed
    Process.send_after(self(), :tick, 1000)
  end

  defp schedule_finish() do
    # TODO: eventually handle the amount of time that has passed
    Process.send_after(self(), :finish, 1000)
  end

  defp via_tuple(id) do
    {:via, Registry, {:game_registry, id}}
  end
end
