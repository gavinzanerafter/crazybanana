defmodule Crazybanana.LobbyChannel do
  use Crazybanana.Web, :channel

  @doc """
  When you join the lobby, we'll send back a list of the current games
  """
  def join("lobby", _msg, socket) do
    {:ok, games, socket}
  end

  def handle_in("start_game", params, socket) do
    id = params["id"]

    pid =
      case Crazybanana.Game.Supervisor.create_game(id) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    game = GenServer.call(pid, :get_data)

    send self(), {:after_start, game.state}

    {:reply, {:ok, game}, socket}
  end

  def handle_in("quit_game", params, socket) do
    id = params["id"]

    Crazybanana.Game.Supervisor.quit_game(id)

    {:reply, :ok, socket}
  end

  def handle_info({:after_start, _state}, socket) do
    Crazybanana.LobbyChannel.broadcast_current_games

    {:noreply, socket}
  end

  @doc """
  If you send a `games` message, we'll reply with the current list of games
  """
  def handle_in("games", _params, socket) do
    {:reply, {:ok, games}, socket}
  end

  @doc """
  Send a list of the current games to all sockets listening on the lobby channel
  """
  def broadcast_current_games do
    Crazybanana.Endpoint.broadcast("lobby", "games", games)
  end

  defp games do
    %{games: Crazybanana.Game.Supervisor.games}
  end
end
