defmodule Xgit.Lib.PersonIdent do
  @moduledoc ~S"""
  A combination of a person identity and time in Git.

  Git combines Name + email + time + time zone to specify who wrote or
  committed something.
  """

  @enforce_keys [:name, :email, :when, :tz_offset]
  defstruct [:name, :email, :when, :tz_offset]

  @doc ~S"""
  Sanitize the given string for use in an identity and append to output.

  Trims whitespace from both ends and special characters `\n < >` that
  interfere with parsing; appends all other characters to the output.
  """
  def sanitized(s) when is_binary(s) do
    s
    |> String.trim()
    |> String.replace(~r/[<>\0-\x1F]/, "")
  end
end
