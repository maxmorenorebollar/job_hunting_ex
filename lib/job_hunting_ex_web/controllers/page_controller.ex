defmodule JobHuntingExWeb.PageController do
  use JobHuntingExWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def about(conn, _params) do
    render(conn, :about)
  end

  def to_home(conn, _params) do
    redirect(conn, to: ~p"/")
  end
end
