defmodule Xgit.Lib.GitmoduleEntry do
  @moduledoc ~S"""
  A .gitmodules file found in the pack. Stores the blob of the file itself (e.g.
  to access its contents) and the tree where it was found (e.g. to check if it
  is in the root).
  """

  @enforce_keys [:tree_id, :blob_id]
  defstruct [:tree_id, :blob_id]
end
