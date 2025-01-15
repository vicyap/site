defmodule MySite.Blog.Post do
  @enforce_keys [:year, :month_day_id, :date, :author, :title, :body, :description, :tags]
  defstruct [:year, :month_day_id, :date, :author, :title, :body, :description, :tags]

  def build(filename, attrs, body) do
    path = Path.rootname(filename)
    [year, month_day_id] = path |> Path.split() |> Enum.take(-2)
    [month, day, _id] = String.split(month_day_id, "-", parts: 3)
    date = Date.from_iso8601!("#{year}-#{month}-#{day}")

    struct!(
      __MODULE__,
      [year: year, month_day_id: month_day_id, date: date, body: body] ++ Map.to_list(attrs)
    )
  end
end
