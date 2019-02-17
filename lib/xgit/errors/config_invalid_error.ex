defmodule Xgit.Errors.ConfigInvalidError do
  @moduledoc ~S"""
  Indicates a text string is not a valid Git style configuration.
  """
  defexception [:message]
end
