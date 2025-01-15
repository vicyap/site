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

  def post(conn, %{"year" => year, "month_day_id" => month_day_id}) do
    post = Blog.get_post_by_year_and_month_day_id(year, month_day_id)

    render(conn, :post, post: post)
  end

  def public(conn, _params) do
    render(conn, :public)
  end
end
