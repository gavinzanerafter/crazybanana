defmodule Crazybanana.GameChannel do
  require Logger

  use Crazybanana.Web, :channel

  def join("game:" <> id, _msg, socket) do
    Logger.warn("JOIN")
    pid =
      case Crazybanana.Game.Supervisor.create_game(id) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    game = GenServer.call(pid, :get_data)

    socket =
      socket
      |> assign(:game_id, id)

    send self(), {:after_join, game.state}

    {:ok, game, socket}
  end

  def handle_info({:after_join, _status}, socket) do
    Crazybanana.LobbyChannel.broadcast_current_games

    {:noreply, socket}
  end

  def handle_info({:broadcast, game_id}, socket) do
    broadcast_game(game_id)

    {:noreply, socket}
  end

  def handle_info({:tick, game_id}, socket) do
    Logger.debug(">>>>>> TICK")
    Crazybanana.Game.tick(game_id)
    broadcast_tick(game_id)

    {:noreply, socket}
  end

  def handle_info({:finish, game_id, tref}, socket) do
    :timer.cancel(tref)
    Crazybanana.Game.finish(game_id)
    broadcast_game(game_id)

    {:noreply, socket}
  end

  def handle_in("player", params, socket) do
    Logger.warn("PLAYER #{params["id"]}")
    socket =
      socket
      |> assign(:player_id, params["id"])

    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.join(game_id, params["id"])
    # send self(), {:broadcast, game_id}
    {:reply, :ok, socket}
  end

  def handle_in("ready", params, socket) do
    Logger.warn("READY #{params["id"]}")
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.ready(game_id, params["id"])
    send self(), {:broadcast, game_id}
    {:reply, :ok, socket}
  end

  def handle_in("start", _params, socket) do
    Logger.warn("START")
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.start(game_id)
    {:ok, tref} = :timer.send_interval(1000, {:tick, game_id})
    :timer.send_after(60000, {:finish, game_id, tref})
    {:reply, :ok, socket}
  end

  def handle_in("restart", _params, socket) do
    Logger.warn("RESTART")
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.restart(game_id)
    {:ok, tref} = :timer.send_interval(1000, {:tick, game_id})
    :timer.send_after(60000, {:finish, game_id, tref})
    {:reply, :ok, socket}
  end

  def handle_in("score", params, socket) do
    Logger.warn("SCORE")
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:player_id]
    _ = Crazybanana.Game.score(game_id, player_id, params["score"])

    {:reply, :ok, socket}
  end

  def broadcast_game(id) do
    game = Crazybanana.Game.get_data(id)

    Crazybanana.Endpoint.broadcast("game:#{id}", "game", game)
  end

  def broadcast_tick(id) do
    game = Crazybanana.Game.get_data(id)

    Crazybanana.Endpoint.broadcast("game:#{id}", "tick", game)
  end
end
