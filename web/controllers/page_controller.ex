defmodule Crazybanana.PageController do
  use Crazybanana.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def crazy(conn, _params) do
    render conn, "crazy.html"
  end

  def lobby(conn, params) do
    render conn, "lobby.html", id: params["name"]
  end

  def game(conn, params) do
    render conn, "game.html", id: params["id"], user_id: params["name"]
  end

  def shop(conn, _params) do
    render conn, "shop.html"
  end
end
