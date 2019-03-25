defmodule Xgit.Test.MockObjectReader do
  @moduledoc false
  # Used for testing only.

  @enforce_keys [:objects]
  defstruct [:objects]
end

defimpl Xgit.Lib.ObjectReader.Strategy, for: Xgit.Test.MockObjectReader do
  alias Xgit.Lib.AbbreviatedObjectId
  alias Xgit.Test.MockObjectReader

  def resolve(%MockObjectReader{objects: objects} = _reader, abbreviated_id) do
    objects
    |> Enum.filter(&object_matches_abbrev?(&1, abbreviated_id))
    |> Enum.map(fn {_object_id, object} -> object end)
  end

  defp object_matches_abbrev?({object_id, _object}, abbreviated_id),
    do: AbbreviatedObjectId.prefix_compare(abbreviated_id, object_id) == :eq
end
