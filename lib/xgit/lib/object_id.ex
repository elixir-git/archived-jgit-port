defmodule Xgit.Lib.ObjectId do
  @moduledoc ~S"""
  An object ID is a string that matches the format for a SHA-1 hash.

  PORTING NOTE: Compared to jgit's ObjectID, we do not implement a separate data
  type. Instead an ObjectID is simply an Elixir string. In this module, we provide
  mechanisms for manipulating and validating such strings.
  """

  alias Xgit.Lib.Constants

  @type t :: String.t()

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

  @doc ~S"""
  Compute the git "name" of an object.

  `obj_type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.
  """
  def id_for(obj_type, data) when is_integer(obj_type) and is_list(data) do
    # FYI :sha in Erlang parlance == SHA-1.

    :sha
    |> :crypto.hash_init()
    |> :crypto.hash_update(Constants.encoded_type_string(obj_type))
    |> :crypto.hash_update(' ')
    |> :crypto.hash_update('#{Enum.count(data)}')
    |> :crypto.hash_update([0])
    |> :crypto.hash_update(data)
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
