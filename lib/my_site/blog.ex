defmodule MySite.Blog do
  alias MySite.Blog.Post

  use NimblePublisher,
    build: Post,
    from: "./priv/posts/**/*.md",
    as: :posts,
    highlighters: [:makeup_elixir, :makeup_erlang]

  @posts Enum.sort_by(@posts, & &1.date, {:desc, Date})

  @tags @posts |> Enum.flat_map(& &1.tags) |> Enum.uniq() |> Enum.sort()

  def all_posts, do: @posts
  def recent_posts(num), do: Enum.take(all_posts(), num)
  def all_tags, do: @tags

  def get_post_by_id(id) do
    all_posts()
    |> Enum.find(&(&1.id == id))
  end

  def get_post_by_url_path(url_path) do
    all_posts()
    |> Enum.find(&(&1.url_path == url_path))
  end
end
