defmodule ChatWeb.LoginController do
  use ChatWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def create(conn, %{"username" => username}) do
    username = String.trim(username)

    if username == "" do
      conn
      |> put_flash(:error, "Username cannot be blank")
      |> redirect(to: "/login")
    else
      conn
      |> put_session(:username, username)
      |> configure_session(renew: true)
      |> redirect(to: "/lobby")
    end
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/login")
  end
end
