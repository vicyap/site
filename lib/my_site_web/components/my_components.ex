defmodule MySiteWeb.MyComponents do
  use Phoenix.Component

  @doc """
  Renders a list of posts.

  ## Examples

  ```heex
  <.list_posts posts={@posts} />
  ```
  """
  @doc type: :component
  attr :posts, :list, required: true, doc: "A list of posts to render."

  def list_posts(assigns) do
    ~H"""
    <div :for={post <- @posts} class="border-b border-grey-lighter pb-8">
      <a
        href={"/blog/posts/#{post.year}/#{post.month_day_id}"}
        class="block font-body text-lg font-semibold text-primary transition-colors hover:text-green dark:text-white dark:hover:text-secondary"
      >
        {post.title}
      </a>
      <div class="flex items-center pt-4">
        <p class="pr-2 font-body font-light text-primary dark:text-white">
          {MySiteWeb.Utils.display_date(post.date)}
        </p>
      </div>
    </div>
    """
  end
end
