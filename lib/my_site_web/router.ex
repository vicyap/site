defmodule MySiteWeb.Router do
  use MySiteWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_current_url
    plug :put_page_title
    plug :put_root_layout, html: {MySiteWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", MySiteWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/blog", PageController, :blog
    get "/blog/posts/:year/:month_day_id", PageController, :post
    get "/public", PageController, :public
    # get "/uses", PageController, :uses
    # get "/contact", PageController, :contact
  end

  defp put_current_url(conn = %Plug.Conn{}, _opts) do
    conn
    |> assign(:current_url, Phoenix.Controller.current_url(conn, %{}))
  end

  defp put_page_title(conn = %Plug.Conn{request_path: "/"}, _opts),
    do: assign(conn, :page_title, "Home")

  defp put_page_title(conn = %Plug.Conn{request_path: "/blog"}, _opts),
    do: assign(conn, :page_title, "Blog")

  defp put_page_title(conn = %Plug.Conn{request_path: "/blog/" <> _rest}, _opts),
    do: assign(conn, :page_title, "Blog")

  defp put_page_title(conn = %Plug.Conn{request_path: "/public"}, _opts),
    do: assign(conn, :page_title, "Public")

  defp put_page_title(conn = %Plug.Conn{}, _opts), do: assign(conn, :page_title, "")
end
