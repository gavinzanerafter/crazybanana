defmodule Crazybanana.LobbyChannel do
  use Crazybanana.Web, :channel

  @doc """
  When you join the lobby, we'll send back a list of the current games
  """
  def join("lobby", _msg, socket) do
    {:ok, games(), socket}
  end

  @doc """
  If you send a `games` message, we'll reply with the current list of games
  """
  def handle_in("games", _params, socket) do
    {:reply, {:ok, games()}, socket}
  end

  @doc """
  Send a list of the current games to all sockets listening on the lobby channel
  """
  def broadcast_current_games do
    Crazybanana.Endpoint.broadcast("lobby", "games", games())
  end

  defp games do
    %{games: Crazybanana.Game.Supervisor.games()}
  end
end
