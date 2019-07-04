# Copyright (C) 2008, 2013 Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/transport/RefSpec.java
#
# Copyright (C) 2019, Eric Scouten <eric+xgit@scouten.com>
#
# This program and the accompanying materials are made available
# under the terms of the Eclipse Distribution License v1.0 which
# accompanies this distribution, is reproduced below, and is
# available at http://www.eclipse.org/org/documents/edl-v10.php
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# - Neither the name of the Eclipse Foundation, Inc. nor the
#   names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior
#   written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

defmodule Xgit.Transport.RefSpec do
  @moduledoc ~S"""
  Describes how refs in one repository copy into another repository.

  A ref specification provides matching support and limited rules to rewrite a
  reference in one repository to another reference in another repository.
  """

  @typedoc ~S"""
  A specification for mapping refs from one repository into another repository.

  ## Struct Members

  * `force?`: (boolean) Does this specification ask for forced updates (rewind/reset)?
  * `allow_mismatched_wildcards?`: (boolean) Whether a wildcard is allowed on one side
      but not the other:
    * `false`: Reject refspecs with an asterisk on the source side and not the
      destination side or vice versa. This is the mode used by `FetchCommand`
      and `PushCommand` to create a one-to-one mapping between source and
      destination refs.
    * `true` (default): Allow refspecs with an asterisk on only one side. This can
      create a many-to-one mapping between source and destination refs, so
      `expand_from_source/2` and `expand_from_destination/2` are not usable in this mode.
  * `src_name`: (string) Name of the ref(s) we would copy from.
  * `dst_name`: (string) Name of the ref(s) we would copy into.
  """
  @type t :: %__MODULE__{
          src_name: String.t(),
          dst_name: String.t() | nil,
          allow_mismatched_wildcards?: boolean,
          force?: boolean
        }

  alias Xgit.Lib.Constants
  alias Xgit.Lib.Ref

  defstruct src_name: Constants.head(),
            dst_name: nil,
            allow_mismatched_wildcards?: true,
            force?: false

  @doc ~S"""
  Suffix for wildcard ref spec component, that indicates matching all refs
  ith specified prefix.
  """
  @spec wildcard_suffix() :: String.t()
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
  * `+refs/pull/*/head:refs/remotes/origin/pr/*`
  * `:refs/heads/master`

  If `allow_mismatched_wildcards?` is `true`, then these ref specs are also valid:
  * `refs/heads/*`
  * `refs/heads/*:refs/heads/master`

  ## Options

  * `allow_mismatched_wildcards?`: `true` to allow wildcards on only one side of the ref spec.
  """
  @spec from_string(spec :: String.t(), opts :: Keyword.t()) :: t
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

    src =
      if src == "",
        do: nil,
        else: src

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
  @spec replace_source(ref_spec :: t, source :: String.t()) :: t
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
  @spec replace_destination(ref_spec :: t, destination :: String.t()) :: t
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
  @spec replace_source_and_destination(
          ref_spec :: t,
          source :: String.t(),
          destination :: String.t()
        ) :: t
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
  @spec match_source?(ref_spec :: t, source_ref_name :: String.t() | nil) :: boolean
  def match_source?(ref_spec, ref_name)

  def match_source?(%__MODULE__{src_name: src}, r) when is_binary(r) or is_nil(r),
    do: match_name?(r, src)

  def match_source?(%__MODULE__{src_name: src}, r),
    do: match_name?(Ref.name(r), src)

  @doc ~S"""
  Does this specification's destination description match the ref name?
  """
  @spec match_destination?(ref_spec :: t, dest_ref_name :: String.t() | nil) :: boolean
  def match_destination?(%__MODULE__{dst_name: dst}, r) when is_binary(r) or is_nil(r),
    do: match_name?(r, dst)

  def match_destination?(%__MODULE__{dst_name: dst}, r),
    do: match_name?(Ref.name(r), dst)

  @doc ~S"""
  Expand this specification to exactly match a ref name.

  Callers must first verify the passed ref name matches this specification,
  otherwise expansion results may be unpredictable.

  `r` must be a ref name that matched our source specification. Could be a
  wildcard also. It can also be a struct that implements the `Xgit.Lib.Ref`
  protocol.

  Returns a new `RefSpec` expanded from provided ref name. Result specification
  is wildcard if and only if provided ref name is wildcard.

  Raises `ArgumentError` when the `RefSpec` was constructed with wildcard mode that
  doesn't require matching wildcards.
  """
  @spec expand_from_source(ref_spec :: t, r :: String.t()) :: t
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
  wildcard also. It can also be a struct that implements the `Xgit.Lib.Ref`
  protocol.

  Returns a new `RefSpec` expanded from provided ref name. Result specification
  is wildcard if and only if provided ref name is wildcard.

  Raises `ArgumentError` when the `RefSpec` was constructed with wildcard mode that
  doesn't require matching wildcards.
  """
  @spec expand_from_destination(ref_spec :: t, r :: String.t()) :: t
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
  @spec wildcard?(ref_spec :: t) :: boolean
  def wildcard?(%__MODULE__{src_name: src_name, dst_name: dst_name}),
    do: wildcard?(src_name) || wildcard?(dst_name)

  def wildcard?(nil), do: false
  def wildcard?(s) when is_binary(s), do: String.contains?(s, "*")

  defimpl String.Chars do
    def to_string(%Xgit.Transport.RefSpec{force?: force?, src_name: src_name, dst_name: dst_name}),
      do: "#{force_str(force?)}#{src_str(src_name)}#{dst_str(dst_name)}"

    defp force_str(true), do: "+"
    defp force_str(_), do: ""

    defp src_str(nil), do: ""
    defp src_str(s), do: s

    defp dst_str(nil), do: ""
    defp dst_str(s), do: ":#{s}"
  end
end
