defmodule Xgit.Errors.UnsupportedCharsetError do
  @moduledoc ~S"""
  Raised when an unsupported character encoding is specified.
  """
  defexception [:message]

  def exception(charset: charset),
    do: %__MODULE__{message: "Character set is unsupported: #{charset}"}
end
