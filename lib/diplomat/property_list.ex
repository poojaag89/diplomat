defmodule Diplomat.PropertyList do
  alias Diplomat.Property

  def new(%{}=prop), do: prop |> Map.to_list |> from_list([])
  def new(prop) when is_list(prop), do: from_list(prop, [])
  def new(prop), do: from_list([prop], [])

  defp from_list([], acc) do
    acc |> Enum.reverse
  end

  defp from_list([head|tail], acc) do
    from_list(tail, [Property.new(head)|acc])
  end
end