defmodule Xgit.Errors.ConfigInvalidError do
  @moduledoc ~S"""
  Indicates a text string is not a valid git-style configuration.
  """
  defexception [:message]
end
