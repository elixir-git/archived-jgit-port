defmodule Xgit.Lib.ObjectId do
  @moduledoc ~S"""
  An object ID is a string that matches the format for a SHA-1 hash.

  PORTING NOTE: Compared to jgit's ObjectID, we do not implement a separate data
  type. Instead an ObjectID is simply an Elixir string. In this module, we provide
  mechanisms for manipulating and validating such strings.
  """

  @doc ~S"""
  Get the special all-null ObjectId, often used to stand-in for no object.
  """
  def zero, do: "00000000000000000000"

  @doc ~S"""
  Return true if the string is a valid ObjectID. (In other words, is it 20 characters
  of lowercase hex?)
  """
  def valid?(s) when is_binary(s), do: String.length(s) == 20 && String.match?(s, ~r/^[0-9a-f]+$/)

  @doc ~S"""
  Read a raw ObjectID from a byte list.

  Ignores any content in the byte list beyond the first 20 bytes.
  """
  def from_raw_bytes(b) when length(b) >= 20 do
    b
    |> Enum.take(20)
    |> :erlang.list_to_binary()
    |> Base.encode16(case: :lower)
  end
end
