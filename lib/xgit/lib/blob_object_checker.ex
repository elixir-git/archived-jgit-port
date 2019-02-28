defprotocol Xgit.Lib.BlobObjectChecker do
  @moduledoc ~S"""
  Verifies that a blob object is a valid object.

  Unlike trees, commits and tags, there's no validity of blobs. Implementers
  can optionally implement this protocol to reject certain blobs.
  """

  @doc ~S"""
  Check a new fragment (byte array) of the blob.

  Raise `CorruptObjectError` if invalid.
  """
  def update(checker, blob_fragment)

  @doc ~S"""
  Called when all of the blob has been checked.

  `id` is the identity of the object being checked.

  Raise `CorruptObjectError` if invalid.
  """
  def end_blob(checker, object_id)
end

defmodule Xgit.Lib.BlobObjectChecker.NullChecker do
  defstruct [:null]
end

defimpl Xgit.Lib.BlobObjectChecker, for: Xgit.Lib.BlobObjectChecker.NullChecker do
  def update(_checker, _blob_fragment), do: :ok
  def end_blob(_checker, _object_id), do: :ok
end
