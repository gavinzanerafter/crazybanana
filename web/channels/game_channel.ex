defmodule Crazybanana.GameChannel do
  use Crazybanana.Web, :channel

  def join("game", _msg, socket) do
    {:ok, current(), socket}
  end

  def handle_in("game", _params, socket) do
    {:reply, {:ok, current()}, socket}
  end

  def broadcast_current_game do
    Crazybanana.Endpoint.broadcast("game", "game", current())
  end

  def current do
    Crazybanana.Game.Supervisor.current
  end

  defp games do
    %{games: Crazybanana.Game.Supervisor.games}
  end
end
