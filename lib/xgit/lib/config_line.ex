defmodule Xgit.Lib.ConfigLine do
  @moduledoc ~S"""
  A line in a Git `Config` file.

  Struct members:
  * `prefix`: The text content before entry.
  * `section`: The section name for the entry.
  * `subsection`: Subsection name.
  * `name`: The key name.
  * `value`: The value.
  * `suffix`: The text content after entry.
  * `included_from`: The source from which this line was included from.
  """

  defstruct [:prefix, :section, :subsection, :name, :value, :suffix, :included_from]

  @doc ~S"""
  Return `true` if this config line matches the section, subection, and key.
  """
  def match?(%__MODULE__{section: sec1, subsection: sub1, name: key1}, sec2, sub2, key2),
    do: match_ignore_case?(sec1, sec2) && sub1 == sub2 && match_ignore_case?(key1, key2)

  @doc ~S"""
  Return `true` if this config line matches the section and key.
  """
  def match?(%__MODULE__{section: sec1, name: key1}, sec2, key2),
    do: match_ignore_case?(sec1, sec2) && match_ignore_case?(key1, key2)

  defp match_ignore_case?(s1, s2), do: maybe_downcase(s1) == maybe_downcase(s2)

  defp maybe_downcase(nil), do: nil
  defp maybe_downcase(s), do: String.downcase(s)

  @doc ~S"""
  Render this ConfigLine as a string.
  """
  def to_string(%__MODULE__{section: section, subsection: subsection, name: name, value: value}),
    do: "#{section_str(section)}#{subsection_str(subsection)}#{name_str(name)}#{value_str(value)}"

  def section_str(nil), do: "<empty>"
  def section_str(s), do: s

  def subsection_str(nil), do: ""
  def subsection_str(s), do: ".#{s}"

  def name_str(nil), do: ""
  def name_str(s), do: ".#{s}"

  def value_str(nil), do: ""
  def value_str(s), do: "=#{s}"
end
