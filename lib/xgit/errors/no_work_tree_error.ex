defmodule Xgit.Errors.NoWorkTreeError do
  @moduledoc ~S"""
  Indicates a `Repository` has no working directory and is thus bare.
  """
  defexception [:message]

  def exception(),
    do: %__MODULE__{message: "Bare Repository has neither a working tree, nor an index"}
end
