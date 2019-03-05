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
  Return true if the string or charlist is a valid ObjectID. (In other words,
  is it 40 characters of lowercase hex?)
  """
  def valid?(s) when is_binary(s), do: String.length(s) == 20 && String.match?(s, ~r/^[0-9a-f]+$/)
  def valid?(b) when is_list(b), do: Enum.count(b) == 40 && Enum.all?(b, &valid_hex_digit?/1)

  defp valid_hex_digit?(c), do: (c >= ?0 && c <= ?9) || (c >= ?a && c <= ?f)

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
  Read an ObjectID from a hex string (charlist).

  If a valid ID is found, returns `{id, next}` where `id` is the matched ID string
  and `next` is the remainder of the charlist after the matched ID.

  If no such ID is found, returns `false`.
  """
  def from_hex_charlist(b) when is_list(b) do
    {maybe_id, remainder} = Enum.split(b, 40)

    if valid?(maybe_id),
      do: {maybe_id, remainder},
      else: false
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
