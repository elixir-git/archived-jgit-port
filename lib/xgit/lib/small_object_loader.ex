defmodule Xgit.Lib.SmallObjectLoader do
  @moduledoc ~S"""
  Simple loader for cached byte lists.

  `ObjectReader` implementations can fall back to this implementation when the
  object's content is small enough to be accessed as a single byte list.
  """

  @enforce_keys [:type, :data]
  defstruct [:type, :data]
end

defimpl Xgit.Lib.ObjectLoader, for: Xgit.Lib.SmallObjectLoader do
  alias Xgit.Lib.SmallObjectLoader

  def type(%SmallObjectLoader{type: type}), do: type
  def size(%SmallObjectLoader{data: data}), do: Enum.count(data)
  def large?(_), do: false
  def cached_bytes(%SmallObjectLoader{data: data}), do: data
  def stream(%SmallObjectLoader{data: data}), do: data
end
