defmodule Crazybanana.GameChannel do
  require Logger

  use Crazybanana.Web, :channel

  def join("game:" <> id, _msg, socket) do
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

  def handle_in("player", params, socket) do
    socket =
      socket
      |> assign(:player_id, params["id"])

    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.join(game_id, params["id"])
    send self(), {:broadcast, game_id}

    {:reply, :ok, socket}
  end

  def handle_in("ready", params, socket) do
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.ready(game_id, params["id"])
    send self(), {:broadcast, game_id}

    {:reply, :ok, socket}
  end

  def handle_in("start", _params, socket) do
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.start(game_id)

    {:reply, :ok, socket}
  end

  def handle_in("restart", _params, socket) do
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.restart(game_id)

    {:reply, :ok, socket}
  end

  def handle_in("done", _params, socket) do
    game_id = socket.assigns[:game_id]
    _ = Crazybanana.Game.Supervisor.quit_game(game_id)

    {:reply, :ok, socket}
  end

  def handle_in("score", params, socket) do
    game_id = socket.assigns[:game_id]
    player_id = socket.assigns[:player_id]
    _ = Crazybanana.Game.score(game_id, player_id, params["score"])

    {:reply, :ok, socket}
  end

  def terminate(reason, _socket) do
    # When the client leaves or closes the connection
    case reason do
      {:shutdown, :closed} -> Logger.debug("SHUTDOWN CLOSED")
      {:shutdown, :left} -> Logger.debug("SHUTDOWN LEFT")
    end
    
    :ok
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
