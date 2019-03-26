defmodule Xgit.Test.MockObjectReader do
  @moduledoc false
  # Used for testing only.

  @enforce_keys [:objects]
  defstruct [:objects, :skip_default_object_size?]
end

defimpl Xgit.Lib.ObjectReader.Strategy, for: Xgit.Test.MockObjectReader do
  alias Xgit.Errors.MissingObjectError
  alias Xgit.Lib.AbbreviatedObjectId
  alias Xgit.Lib.SmallObjectLoader
  alias Xgit.Test.MockObjectReader

  def resolve(%MockObjectReader{objects: objects} = _reader, abbreviated_id) do
    objects
    |> Enum.filter(&object_matches_abbrev?(&1, abbreviated_id))
    |> Enum.map(fn {_object_id, object} -> object end)
  end

  defp object_matches_abbrev?({object_id, _object}, abbreviated_id),
    do: AbbreviatedObjectId.prefix_compare(abbreviated_id, object_id) == :eq

  def has_object?(%MockObjectReader{objects: objects} = _reader, object_id, _type_hint),
    do: Map.has_key?(objects, object_id)

  def open(%MockObjectReader{objects: objects} = _reader, object_id, type_hint) do
    case Map.get(objects, object_id) do
      %{type: type, data: data} ->
        %SmallObjectLoader{type: type, data: data}

      _ ->
        raise(MissingObjectError, object_id: object_id, type: type_hint)
    end
  end

  def object_size(
        %MockObjectReader{skip_default_object_size?: true} = _reader,
        _object_id,
        _type_hint
      ) do
    42
    # probably wrong, but useful for testing
  end

  def object_size(%MockObjectReader{objects: _objects} = _reader, _object_id, _type_hint),
    do: :default
end
