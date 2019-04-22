defmodule Xgit.Util.Paths do
  @moduledoc ~S"""
  Utility functions for paths inside of a git repository.
  """

  use Bitwise

  alias Xgit.Lib.FileMode

  @doc ~S"""
  Remove trailing `/` if present.
  """
  def strip_trailing_separator([]), do: []

  def strip_trailing_separator(path) when is_list(path) do
    if List.last(path) == ?/ do
      path
      |> Enum.reverse()
      |> Enum.drop_while(&(&1 == ?/))
      |> Enum.reverse()
    else
      path
    end
  end

  @doc ~S"""
  Compare two paths according to git path sort ordering rules.

  Returns:
  * `:lt` if `path1` sorts before `path2`.
  * `:eq` if they are the same.
  * `:gt` if `path1` sorts after `path2`.
  """
  def compare(path1, mode1, path2, mode2)
      when is_list(path1) and is_integer(mode1) and is_list(path2) and is_integer(mode2) do
    case core_compare(path1, mode1, path2, mode2) do
      :eq -> mode_compare(mode1, mode2)
      x -> x
    end
  end

  @doc ~S"""
  Compare two paths, checking for identical name.

  Unlike `compare/4`, this method returns `:eq` when the paths have
  the same characters in their names, even if the mode differs. It is
  intended for use in validation routines detecting duplicate entries.

  Returns `:eq` if the names are identical and a conflict exists
  between `path1` and `path2`, as they share the same name.

  Returns `:lt` if all possible occurrences of `path1` sort
  before `path2` and no conflict can happen. In a properly sorted
  tree there are no other occurrences of `path1` and therefore there
  are no duplicate names.

  Returns `:gt` when it is possible for a duplicate occurrence of
  `path1` to appear later, after `path2`. Callers should
  continue to examine candidates for `path2` until the method returns
  one of the other return values.

  `mode2` is the mode of the second file. Trees are sorted as though
  `List.last(path2) == ?/`, even if no such character exists.
  Return `:lt` if no duplicate name could exist; `:eq` if the paths
  have the same name; `:gt` if other `path2` should still be checked
  by caller.
  """
  def compare_same_name(path1, path2, mode2),
    do: core_compare(path1, FileMode.type_tree(), path2, mode2)

  defp core_compare(path1, mode1, path2, mode2)

  defp core_compare([c | rem1], mode1, [c | rem2], mode2),
    do: core_compare(rem1, mode1, rem2, mode2)

  defp core_compare([c1 | _rem1], _mode1, [c2 | _rem2], _mode2),
    do: compare_chars(c1, c2)

  defp core_compare([c1 | _rem1], _mode1, [], mode2),
    do: compare_chars(band(c1, 0xFF), last_path_char(mode2))

  defp core_compare([], mode1, [c2 | _], _mode2),
    do: compare_chars(last_path_char(mode1), band(c2, 0xFF))

  defp core_compare([], _mode1, [], _mode2), do: :eq

  defp compare_chars(c, c), do: :eq
  defp compare_chars(c1, c2) when c1 < c2, do: :lt
  defp compare_chars(_, _), do: :gt

  defp last_path_char(mode) do
    if band(mode, FileMode.type_mask()) == FileMode.type_tree(),
      do: ?/,
      else: 0
  end

  defp mode_compare(mode1, mode2) do
    if band(mode1, FileMode.type_mask()) == FileMode.type_gitlink() or
         band(mode2, FileMode.type_mask()) == FileMode.type_gitlink(),
       do: :eq,
       else: compare_chars(last_path_char(mode1), last_path_char(mode2))
  end
end
