defmodule Xgit.Lib.AbbreviatedObjectId do
  @moduledoc ~S"""
  A prefix abbreviation of an `ObjectId`.

  Sometimes git produces abbreviated SHA-1 strings, using sufficient leading
  digits from the `ObjectId` name to still be unique within the repository the
  string was generated from. These IDs are likely to be unique for a useful
  period of time, especially if they contain at least 6-10 hex digits.
  """

  @type t :: String.t()

  @doc ~S"""
  Test a string of characters to verify it is a valid abbreviated ID.
  """
  def valid?(id) when is_binary(id) do
    length = String.length(id)
    length >= 2 && length <= 40 && String.match?(id, ~r/^[0-9a-f]+$/)
  end

  @doc ~S"""
  Is this abbreviated object ID actually a complete ID?
  """
  def complete?(id) when is_binary(id), do: String.length(id) == 40

  @doc ~S"""
  Compares this abbreviation to a full object ID.

  Returns:
  * `:lt` if the abbreviation `a` names an object that is less than `other`
  * `:eq` if the abbreviation `a` exactly matches the first `length/1` digits of `other`
  * `:gt` if the abbreviation `a` names an object that is after `other`
  """
  def prefix_compare(a, other) when is_binary(a) and is_binary(other) do
    if String.starts_with?(other, a),
      do: :eq,
      else: compare_charlists(String.to_charlist(a), String.to_charlist(other))
  end

  defp compare_charlists([c | a], [c | other]), do: compare_charlists(a, other)

  defp compare_charlists([c1 | _], [c2 | _]) when c1 < c2, do: :lt
  defp compare_charlists([c1 | _], [c2 | _]) when c1 > c2, do: :gt

  defp compare_charlists([], _), do: :eq
end
