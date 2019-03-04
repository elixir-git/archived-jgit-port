defmodule Xgit.Errors.CorruptObjectError do
  @moduledoc ~S"""
  Raised when an object cannot be read from Git.
  """
  defexception [:message, :error_type]

  def exception(id: id, error_type: error_type, why: why),
    do: %__MODULE__{message: "Object #{id} is corrupt: #{why}", error_type: error_type}

  def exception(id: id, why: why), do: %__MODULE__{message: "Object #{id} is corrupt: #{why}"}
  def exception(why: why), do: %__MODULE__{message: "Object (unknown) is corrupt: #{why}"}
end
