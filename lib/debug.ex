defmodule Debug do
  defmacro debug(obj) do
    quote do
      unquote(obj) |> inspect |> IO.puts
    end
  end
end
