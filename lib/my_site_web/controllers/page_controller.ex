defmodule MySiteWeb.PageController do
  use MySiteWeb, :controller

  alias MySite.Blog

  def home(conn, _params) do
    posts = Blog.recent_posts(3)

    render(conn, :home, posts: posts)
  end

  def blog(conn, _params) do
    posts = Blog.all_posts()

    render(conn, :blog, posts: posts)
  end

  def redirect_to_blog(conn, _params) do
    redirect(conn, to: ~p"/blog")
  end

  def post(conn, %{"url_path" => url_path}) do
    post = Blog.get_post_by_url_path(url_path)

    render(conn, :post, post: post)
  end

  def public(conn, _params) do
    render(conn, :public)
  end
end
