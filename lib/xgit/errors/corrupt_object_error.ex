defmodule Xgit.Errors.CorruptObjectError do
  @moduledoc ~S"""
  Raised when an object cannot be read from Git.
  """
  defexception [:message]

  def exception(id: id, why: why), do: %__MODULE__{message: "Object #{id} is corrupt: #{why}"}
  def exception(why: why), do: %__MODULE__{message: "Object (unknown) is corrupt: #{why}"}
end
