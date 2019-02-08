defmodule Xgit.Errors.BinaryBlobError do
  @moduledoc ~S"""
  Raised when binary data was found in a context that requires text
  (e.g. for generating textual diffs).
  """
  defexception [:message]

  def exception(_), do: %__MODULE__{message: "A NULL byte was found where text was expected."}
end
