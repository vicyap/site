defmodule MySite.Blog.Post do
  @enforce_keys [:id, :date, :author, :title, :body, :description, :tags]
  defstruct [:id, :date, :author, :title, :body, :description, :tags]

  def build(filename, attrs, body) do
    path = Path.rootname(filename)
    id = path |> Path.split() |> Enum.take(-1)
    [year, month, day, _id] = String.split(id, "-", parts: 4)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    struct!(
      __MODULE__,
      [id: id, date: date, body: body] ++ Map.to_list(attrs)
    )
  end
end
