defmodule Xgit.Transport.RefSpec do
  @moduledoc ~S"""
  Describes how refs in one repository copy into another repository.

  A ref specification provides matching support and limited rules to rewrite a
  reference in one repository to another reference in another repository.

  Struct members:
  * `force?`: Does this specification ask for forced updated (rewind/reset)?
  * `allow_mismatched_wildcards?`: Whether a wildcard is allowed on one side but not the other.
    * `false`: Reject refspecs with an asterisk on the source side and not the
      destination side or vice versa. This is the mode used by `FetchCommand`
      and `PushCommand` to create a one-to-one mapping between source and
      destination refs.
    * `true`: Allow refspecs with an asterisk on only one side. This can create a
      many-to-one mapping between source and destination refs, so `expandFromSource`
      and `expandFromDestination` are not usable in this mode.
  * `src_name`: Name of the ref(s) we would copy from.
  * `dst_name`: Name of the ref(s) we would copy into.
  """

  defstruct src_name: Constants.head(),
            dst_name: nil,
            allow_mismatched_wildcards?: true,
            force?: false

  alias Xgit.Lib.Constants
  alias Xgit.Lib.Ref

  @doc ~S"""
  Suffix for wildcard ref spec component, that indicates matching all refs
  ith specified prefix.
  """
  def wildcard_suffix, do: "/*"

  @doc ~S"""
  Parse a ref specification for use during transport operations.

  Specifications are typically one of the following forms:
  * `refs/heads/master`
  * `refs/heads/master:refs/remotes/origin/master`
  * `refs/heads/*:refs/remotes/origin/*`
  * `+refs/heads/master`
  * `+refs/heads/master:refs/remotes/origin/master`
  * `+refs/heads/*:refs/remotes/origin/*`
  * `+refs/pull/&#42;/head:refs/remotes/origin/pr/*`
  * `:refs/heads/master`

  If `allow_mismatched_wildcards?` is `true`, then these ref specs are also valid:
  * `refs/heads/*`
  * `refs/heads/*:refs/heads/master`

  Options may be:
  * `allow_mismatched_wildcards?`: `true`
  """
  def from_string(spec, opts \\ []) when is_binary(spec) and is_list(opts) do
    allow_mismatched_wildcards? = Keyword.get(opts, :allow_mismatched_wildcards?, false)

    unless is_boolean(allow_mismatched_wildcards?),
      do: raise(ArgumentError, "allow_mismatched_wildcards? must be boolean")

    {force?, s} = force_and_spec(spec)

    {src, dst} =
      case String.split(s, ~r{:[^:]*$}, include_captures: true) do
        [src, ":", ""] -> {src, nil}
        [src, ":" <> dst, ""] -> {src, dst}
        [src] -> {src, nil}
      end

    src = if src == "", do: nil, else: src

    unless allow_mismatched_wildcards? do
      if wildcard?(src) != wildcard?(dst) do
        raise ArgumentError, "Invalid wildcards #{spec}"
      end
    end

    %__MODULE__{
      src_name: assert_valid(src),
      dst_name: assert_valid(dst),
      allow_mismatched_wildcards?: allow_mismatched_wildcards?,
      force?: force?
    }
  end

  defp force_and_spec("+" <> s), do: {true, s}
  defp force_and_spec(s), do: {false, s}

  @doc ~S"""
  Create a new `RefSpec` with a different source name setting.

  Raises `ArgumentError` if destination and source are not compatible.
  """
  def replace_source(%__MODULE__{dst_name: dst} = ref_spec, source) do
    assert_valid(source)

    if wildcard?(source) && dst == nil,
      do: raise(ArgumentError, "Destination is not a wildcard.")

    if wildcard?(source) != wildcard?(dst),
      do: raise(ArgumentError, "Source/Destination must match.")

    %{ref_spec | src_name: source}
  end

  @doc ~S"""
  Create a new `RefSpec` with a different destination name setting.

  Raises `ArgumentError` if destination and source are not compatible.
  """
  def replace_destination(%__MODULE__{src_name: src} = ref_spec, destination) do
    assert_valid(destination)

    if wildcard?(src) != wildcard?(destination),
      do: raise(ArgumentError, "Source/Destination must match.")

    %{ref_spec | dst_name: destination}
  end

  @doc ~S"""
  Create a new `RefSpec` with a different source/destination name setting.

  Raises `ArgumentError` if destination and source are not compatible.
  """
  def replace_source_and_destination(%__MODULE__{} = ref_spec, source, destination) do
    assert_valid(source)
    assert_valid(destination)

    if wildcard?(source) != wildcard?(destination),
      do: raise(ArgumentError, "Source/Destination must match.")

    %{ref_spec | src_name: source, dst_name: destination}
  end

  @doc ~S"""
  Does this specification's source description match the ref name?
  """
  def match_source?(%__MODULE__{src_name: src}, r) when is_binary(r) or is_nil(r),
    do: match_name?(r, src)

  def match_source?(%__MODULE__{src_name: src}, r),
    do: match_name?(Ref.name(r), src)

  @doc ~S"""
  Does this specification's destination description match the ref name?
  """
  def match_destination?(%__MODULE__{dst_name: dst}, r) when is_binary(r) or is_nil(r),
    do: match_name?(r, dst)

  def match_destination?(%__MODULE__{dst_name: dst}, r),
    do: match_name?(Ref.name(r), dst)

  @doc ~S"""
  Expand this specification to exactly match a ref name.

  Callers must first verify the passed ref name matches this specification,
  otherwise expansion results may be unpredictable.

  `r` must be a ref name that matched our source specification. Could be a
  wildcard also. (It can also be a struct that implements the `Ref` protocol.)

  Returns a new `RefSpec` expanded from provided ref name. Result specification
  is wildcard if and only if provided ref name is wildcard.

  Raises `ArgumentError` when the `RefSpec` was constructed with wildcard mode that
  doesn't require matching wildcards.
  """
  def expand_from_source(
        %__MODULE__{src_name: src, dst_name: dst, allow_mismatched_wildcards?: false} = ref_spec,
        r
      )
      when is_binary(r) do
    if wildcard?(src),
      do: %{ref_spec | src_name: r, dst_name: expand_wildcard(r, src, dst)},
      else: ref_spec
  end

  def expand_from_source(_ref_spec, r) when is_binary(r) do
    raise ArgumentError,
          "RefSpec.expand_from_source/2 on a RefSpec that allows mismatched wildcards does not make sense."
  end

  def expand_from_source(ref_spec, r), do: expand_from_source(ref_spec, Ref.name(r))

  @doc ~S"""
  Expand this specification to exactly match a ref name.

  Callers must first verify the passed ref name matches this specification,
  otherwise expansion results may be unpredictable.

  `r` must be a ref name that matched our destination specification. Could be a
  wildcard also. (It can also be a struct that implements the `Ref` protocol.)

  Returns a new `RefSpec` expanded from provided ref name. Result specification
  is wildcard if and only if provided ref name is wildcard.

  Raises `ArgumentError` when the `RefSpec` was constructed with wildcard mode that
  doesn't require matching wildcards.
  """
  def expand_from_destination(
        %__MODULE__{src_name: src, dst_name: dst, allow_mismatched_wildcards?: false} = ref_spec,
        r
      )
      when is_binary(r) do
    if wildcard?(dst),
      do: %{ref_spec | dst_name: r, src_name: expand_wildcard(r, dst, src)},
      else: ref_spec
  end

  def expand_from_destination(_ref_spec, r) when is_binary(r) do
    raise ArgumentError,
          "RefSpec.expand_from_destination/2 on a RefSpec that allows mismatched wildcards does not make sense."
  end

  def expand_from_destination(ref_spec, r), do: expand_from_destination(ref_spec, Ref.name(r))

  defp match_name?(_name, nil), do: false

  defp match_name?(name, s) when is_binary(s) do
    if wildcard?(s) do
      [prefix, suffix] = String.split(s, "*", parts: 2)

      String.length(name) > String.length(prefix) + String.length(suffix) &&
        String.starts_with?(name, prefix) &&
        String.ends_with?(name, suffix)
    else
      name == s
    end
  end

  defp expand_wildcard(name, pattern1, pattern2) do
    [prefix1, trailing1] = String.split(pattern1, "*", parts: 2)

    match =
      String.slice(
        name,
        String.length(prefix1)..(String.length(name) - String.length(trailing1) - 1)
      )

    String.replace(pattern2, "*", match, global: false)
  end

  defp assert_valid(nil), do: nil

  defp assert_valid(s) when is_binary(s) do
    if valid?(s),
      do: s,
      else: raise(ArgumentError, "Invalid refspec #{s}")
  end

  defp valid?(s) do
    with true <- is_binary(s),
         false <- String.starts_with?(s, "/"),
         false <- String.contains?(s, "//"),
         false <- String.ends_with?(s, "/"),
         true <- length(String.split(s, "*")) < 3 do
      true
    else
      _ -> false
    end
  end

  @doc ~S"""
  Return `true` if this specification is actually a wildcard pattern.
  """
  def wildcard?(%__MODULE__{src_name: src_name, dst_name: dst_name}),
    do: wildcard?(src_name) || wildcard?(dst_name)

  def wildcard?(nil), do: false
  def wildcard?(s) when is_binary(s), do: String.contains?(s, "*")
end

defimpl String.Chars, for: Xgit.Transport.RefSpec do
  def to_string(%Xgit.Transport.RefSpec{force?: force?, src_name: src_name, dst_name: dst_name}),
    do: "#{force_str(force?)}#{src_str(src_name)}#{dst_str(dst_name)}"

  defp force_str(true), do: "+"
  defp force_str(_), do: ""

  defp src_str(nil), do: ""
  defp src_str(s), do: s

  defp dst_str(nil), do: ""
  defp dst_str(s), do: ":#{s}"
end
