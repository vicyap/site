defmodule MySite.Blog.Post do
  @enforce_keys [:id, :url_path, :date, :title, :body, :tags]
  defstruct [:id, :url_path, :date, :title, :body, :tags]

  def build(rel_path, attrs, body) do
    basename = Path.basename(rel_path, ".md")
    [id, url_path] = String.split(basename, "-", parts: 2)

    attrs = Map.update!(attrs, :date, &Date.from_iso8601!/1)

    struct!(
      __MODULE__,
      [id: id, url_path: url_path, body: body] ++ Map.to_list(attrs)
    )
  end
end
