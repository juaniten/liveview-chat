defmodule ChatWeb.Login do
  import Plug.Conn
  import Phoenix.Controller

  def init(default) do
    default
  end

  def call(conn, opts) do
    require_authentication(conn, opts)
  end

  def require_authentication(conn, _opts) do
    if get_session(conn, :username) do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: "/login")
      |> halt()
    end
  end
end
