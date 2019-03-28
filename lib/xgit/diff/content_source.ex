defmodule Xgit.Diff.ContentSource do
  @moduledoc ~S"""
  Supplies the content of a file for `DiffFormatter`.

  PORTING NOTE: In jgit, `ContentSource` is an abstract class. In xgit, it is
  a module which switches behavior based on whether it is passed a `WorkingTreeIterator`
  (not yet ported) or a struct that implements the `ObjectReader` source.
  """

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectId
  alias Xgit.Lib.ObjectReader

  @type t :: ObjectReader.t()
  # PORTING NOTE: add WorkingTreeIterator.t(), whenever that is defined

  @doc ~S"""
  Determine the size of the object.

  `path` is the path of the file, relative to the root of the repository.

  `object_id` is the blob ID of the file, if known.

  Returns the size of the object, in bytes.
  """
  @spec size(source :: t, path :: String.t(), object_id :: ObjectId.t()) :: non_neg_integer()
  def size(source, _path, object_id),
    do: ObjectReader.object_size(source, object_id, Constants.obj_blob())

  @doc ~S"""
  Open the object.

  `path` is the path of the file, relative to the root of the repository.

  `object_id` is the blob ID of the file, if known.

  Returns an `ObjectLoader` that can supply the content of the file. The loader
  must be used before another loader can be obtained from this same source.
  """
  @spec open(source :: t, path :: String.t(), object_id :: ObjectId.t()) :: ObjectLoader.t()
  def open(source, _path, object_id),
    do: ObjectReader.open(source, object_id, Constants.obj_blob())
end
