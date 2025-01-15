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

  def get_post_by_year_and_month_day_id(year, month_day_id) do
    @posts
    |> Enum.filter(&(&1.year == year))
    |> Enum.find(&(&1.month_day_id == month_day_id))
  end
end
