# Copyright (C) 2008-2010, Google Inc.
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectChecker.java
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

defmodule Xgit.Lib.ObjectChecker do
  @moduledoc ~S"""
  Verifies that an object is formatted correctly.

  Verifications made by this module only check that the fields of an object are
  formatted correctly. The object ID checksum of the object is not verified, and
  connectivity links between objects are also not verified. It's assumed that
  the caller can provide both of these validations on its own.
  """

  alias Xgit.Errors.CorruptObjectError
  alias Xgit.Lib.Constants
  alias Xgit.Lib.FileMode
  alias Xgit.Lib.ObjectId
  alias Xgit.Util.Paths
  alias Xgit.Util.RawParseUtils

  defprotocol Strategy do
    @moduledoc ~S"""
    Implements some of the object-type checks for `Xgit.Lib.ObjectChecker`.
    """

    @typedoc "Any struct for which `Xgit.Lib.ObjectChecker.Strategy` is implemented."
    @type t :: struct

    @doc ~S"""
    Check a commit for errors.

    ## Return Value

    * `:ok` if commit is validated.
    * `:default` to reuse the default implementation.

    ## Errors

    Raise `Xgit.Errors.CorruptObjectError` if the commit is invalid.
    """
    @spec check_commit!(strategy :: t, commit_data :: [byte]) :: :ok | :default
    def check_commit!(strategy, commit_data)

    @doc ~S"""
    Check a blob for errors.

    ## Return Value

    * `:ok` if blob is validated.
    * `:default` to reuse the default implementation.

    ## Errors

    Raise `Xgit.Errors.CorruptObjectError` if the blob is invalid.
    """
    @spec check_blob!(strategy :: t, blob_data :: [byte]) :: :ok | :default
    def check_blob!(strategy, blob_data)
  end

  @typedoc ~S"""
  Specification for how object checking should be performed.

  ## Struct Members

  _(All members are optional.)_

  * `:strategy`: A struct for which `Xgit.Lib.ObjectChecker.Strategy` is implemented.
  * `:skiplist`: A `MapSet` of object IDs to ignore when checking.
  * `:ignore_error_types`: A map containing zero or more of the following values:
    * `bad_tree_sha1: true`: Ignore a malformed tree object ID
    * `null_sha1: true`: Ignore an object ID that is all zeros
    * `zero_padded_filemode: true`: Ignore file mode that has leading zeros
    * `full_pathname: true`: Ignore a file path that has a `/` in it
    * `empty_name: true`: Ignore a file path that is empty
    * `has_dot: true`: Ignore a file path that is just `.`
    * `has_dotdot: true`: Ignore a file path that is just `..`
    * `has_dotgit: true`: Ignore a file path that is `.git`
    * `tree_not_sorted: true`: Ignore a tree where the file paths are not sorted
    * `duplicate_entries: true`: Ignore duplicate entries in the tree
  * `:allow_invalid_person_ident?`: (boolean) `true` to ignore errors in the
    formation of author / committer IDs
  * `:windows?`: (boolean) `true` to enforce Windows file naming conventions.
  * `:macosx?`: (boolean) `true` to enforce Mac OS X file naming conventions.
  """
  @type t :: %__MODULE__{
          strategy: struct | nil,
          skiplist: MapSet.t() | nil,
          ignore_error_types: %{} | nil,
          allow_invalid_person_ident?: boolean | nil,
          windows?: boolean | nil,
          macosx?: boolean | nil
        }

  defstruct strategy: nil,
            skiplist: nil,
            ignore_error_types: nil,
            allow_invalid_person_ident?: false,
            windows?: false,
            macosx?: false

  @doc ~S"""
  Check an object for parsing errors.

  ## Parameters

  `obj_type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.

  `data` is the raw data which comprises the object. This should be in the
  canonical format (that is the format used to generate the `object_id` of
  the object).

  ## Return Values

  If the object is of type `tree`, returns `{:ok, gitsubmodules}` where `gitsubmodules`
  is a list of all submodule entries found. `gitsubmodules` is a list of tuples
  of the form `{tree_id, blob_id}` where `tree_id` is the object ID of the tree
  containing the submodule reference and `blob_id` is the object ID of the
  submodule that was referenced.

  For all other object types, returns `:ok` if the object is successfully validated.

  ## Errors

  Raises `Xgit.Errors.CorruptObjectError` if an error is identified.
  """
  @spec check!(checker :: t, obj_type :: Constants.obj_type(), data :: [byte]) ::
          {:ok, [{String.t(), String.t()}]} | :ok
  def check!(%__MODULE__{} = checker, obj_type, data)
      when is_integer(obj_type) and is_list(data) do
    check!(checker, id_for(checker, obj_type, data), obj_type, data)
  end

  @doc ~S"""
  Check an object for parsing errors.

  Like `check!/3` but `id` has already been calculated.
  """
  @spec check!(checker :: t, id :: ObjectId.t(), obj_type :: Constants.obj_type(), data :: [byte]) ::
          {:ok, [{String.t(), String.t()}]} | :ok
  def check!(checker, id, obj_type, data)

  # def check(%ObjectChecker{} = checker, id, obj_type, data) when is_binary(id)
  # ... is_integer(obj_type) and is_list(data) do
  # switch (objType) {

  # type 1 = commit

  def check!(%__MODULE__{strategy: nil} = checker, id, 1, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    check_commit!(checker, id, data)
  end

  def check!(%__MODULE__{strategy: strategy} = checker, id, 1, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    case Strategy.check_commit!(strategy, data) do
      :default -> check_commit!(checker, id, data)
      x -> x
    end
  end

  # type 4 = tag

  def check!(%__MODULE__{} = checker, id, 4, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    check_tag!(checker, id, data)
  end

  # type 2 = tree

  def check!(%__MODULE__{} = checker, id, 2, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    check_tree!(checker, id, data)
  end

  # type 3 = blob

  def check!(%__MODULE__{strategy: nil} = _checker, id, 3, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    :ok
  end

  def check!(%__MODULE__{strategy: strategy} = _checker, id, 3, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    case Strategy.check_blob!(strategy, data) do
      :default -> :ok
      x -> x
    end
  end

  # unknown type

  def check!(%__MODULE__{} = checker, id, obj_type, data)
      when (is_binary(id) or id == nil) and is_list(data) do
    report(checker, :unknown_type, id, "invalid type #{obj_type}")
  end

  defp check_id(data) do
    case ObjectId.from_hex_charlist(data) do
      {_id, [?\n | remainder]} ->
        {true, remainder}

      {_id, _remainder} ->
        {false, RawParseUtils.next_lf(data)}

      false ->
        {false, RawParseUtils.next_lf(data)}
    end
  end

  defp check_id_or_report!(%__MODULE__{} = checker, data, error_type: error_type, id: id, why: why) do
    case check_id(data) do
      {true, data} ->
        data

      {false, data} ->
        report(checker, error_type, id, why)
        data
    end
  end

  defp check_person_ident_or_report!(%__MODULE__{allow_invalid_person_ident?: true}, _id, data),
    do: RawParseUtils.next_lf(data)

  defp check_person_ident_or_report!(checker, id, data) do
    with {:missing_email, [?< | email_start]} <-
           {:missing_email, RawParseUtils.next_lf(data, ?<)},
         {:bad_email, [?> | after_email]} <- {:bad_email, RawParseUtils.next_lf(email_start, ?>)},
         {:missing_space_before_date, [?\s | date]} <- {:missing_space_before_date, after_email},
         {:bad_date, {_date, [?\s | tz]}} <- {:bad_date, RawParseUtils.parse_base_10(date)},
         {:bad_timezone, {_tz, [?\n | next]}} <- {:bad_timezone, RawParseUtils.parse_base_10(tz)} do
      next
    else
      {cause, _} ->
        {error_type, why} = error_type_and_message_for_cause(cause)
        report(checker, error_type, id, why)
        RawParseUtils.next_lf(data)
    end
  end

  defp error_type_and_message_for_cause(:missing_email),
    do: {:missing_email, "missing email"}

  defp error_type_and_message_for_cause(:bad_email),
    do: {:bad_email, "bad email"}

  defp error_type_and_message_for_cause(:missing_space_before_date),
    do: {:missing_space_before_date, "bad date"}

  defp error_type_and_message_for_cause(:bad_date),
    do: {:bad_date, "bad date"}

  defp error_type_and_message_for_cause(:bad_timezone),
    do: {:bad_timezone, "bad time zone"}

  defp check_commit!(%__MODULE__{} = checker, id, data) do
    data =
      match_or_report!(checker, data,
        prefix: 'tree ',
        error_type: :missing_tree,
        id: id,
        why: "no tree header"
      )

    data =
      check_id_or_report!(checker, data,
        error_type: :bad_tree_sha1,
        id: id,
        why: "invalid tree"
      )

    data = check_commit_parents!(checker, id, data)

    data =
      match_or_report!(checker, data,
        prefix: 'author ',
        error_type: :missing_author,
        id: id,
        why: "no author"
      )

    data = check_person_ident_or_report!(checker, id, data)

    data =
      match_or_report!(checker, data,
        prefix: 'committer ',
        error_type: :missing_committer,
        id: id,
        why: "no committer"
      )

    check_person_ident_or_report!(checker, id, data)
    :ok
  end

  defp check_commit_parents!(checker, id, data) do
    case RawParseUtils.match_prefix?(data, 'parent ') do
      {true, after_match} ->
        data =
          check_id_or_report!(checker, after_match,
            error_type: :bad_parent_sha1,
            id: id,
            why: "invalid parent"
          )

        check_commit_parents!(checker, id, data)

      _ ->
        data
    end
  end

  defp check_tag!(%__MODULE__{} = checker, id, data) do
    data =
      match_or_report!(checker, data,
        prefix: 'object ',
        error_type: :missing_tree,
        id: id,
        why: "no object header"
      )

    data =
      check_id_or_report!(checker, data,
        error_type: :bad_tree_sha1,
        id: id,
        why: "invalid object"
      )

    data =
      match_or_report!(checker, data,
        prefix: 'type ',
        error_type: :missing_tree,
        id: id,
        why: "no type header"
      )

    data = RawParseUtils.next_lf(data)

    data =
      match_or_report!(checker, data,
        prefix: 'tag ',
        error_type: :missing_tag,
        id: id,
        why: "no tag header"
      )

    data = RawParseUtils.next_lf(data)

    case RawParseUtils.match_prefix?(data, 'tagger ') do
      {true, after_match} -> check_person_ident_or_report!(checker, id, after_match)
      _ -> :ignore
    end

    :ok
  end

  defp check_tree!(%__MODULE__{windows?: true} = checker, id, data),
    do: check_tree!(checker, id, data, MapSet.new(), [], 0, [])

  defp check_tree!(%__MODULE__{macosx?: true} = checker, id, data),
    do: check_tree!(checker, id, data, MapSet.new(), [], 0, [])

  defp check_tree!(%__MODULE__{} = checker, id, data),
    do: check_tree!(checker, id, data, nil, [], 0, [])

  defp check_tree!(
         _checker,
         _id,
         [] = _data,
         _maybe_normalized_paths,
         _previous_name,
         _previous_mode,
         gitsubmodules
       ),
       do: {:ok, Enum.reverse(gitsubmodules)}

  defp check_tree!(
         %__MODULE__{} = checker,
         id,
         data,
         maybe_normalized_paths,
         previous_name,
         previous_mode,
         gitsubmodules
       ) do
    # Scan one entry then recurse to scan remaining entries.

    {file_mode, data} = check_file_mode!(checker, id, data, 0)

    file_mode_type = FileMode.from_bits(file_mode).object_type

    if file_mode_type == Constants.obj_bad(),
      do: raise(CorruptObjectError, why: "invalid mode #{file_mode}")

    {this_name, data} = scan_path_segment_with_nil(checker, data, id)

    check_path_segment2(checker, this_name, id)

    if Enum.count(this_name) == 5 and Enum.map(this_name, &to_lower/1) == 'git~1',
      do: report(checker, :has_dotgit, id, "invalid name '#{this_name}'")

    maybe_normalized_paths =
      report_if_duplicate_names(checker, id, maybe_normalized_paths, this_name, data)

    report_if_incorrectly_sorted(checker, id, previous_name, previous_mode, this_name, file_mode)

    {raw_object_id, data} = Enum.split(data, Constants.object_id_length())

    if Enum.count(raw_object_id) != Constants.object_id_length(),
      do: raise(CorruptObjectError, why: "truncated in object id")

    if Enum.all?(raw_object_id, &(&1 == 0)),
      do: report(checker, :null_sha1, id, "entry points to null SHA-1")

    gitsubmodules =
      if id != nil and gitmodules?(checker, this_name, id),
        do: [{id, ObjectId.from_raw_bytes(raw_object_id)} | gitsubmodules],
        else: gitsubmodules

    check_tree!(checker, id, data, maybe_normalized_paths, this_name, file_mode, gitsubmodules)
  end

  defp report_if_incorrectly_sorted(
         checker,
         id,
         previous_name,
         previous_mode,
         this_name,
         this_mode
       ) do
    if previous_name != nil do
      if Paths.compare(previous_name, previous_mode, this_name, this_mode) == :gt do
        report(checker, :tree_not_sorted, id, "incorrectly sorted")
      end
    end
  end

  defp report_if_duplicate_names(checker, id, nil = _normalized_paths, this_name, data) do
    if duplicate_name?(this_name, data),
      do: report(checker, :duplicate_entries, id, "duplicate entry names")

    nil
  end

  defp report_if_duplicate_names(checker, id, %MapSet{} = normalized_paths, this_name, _data) do
    normalized_path = normalize(checker, this_name)

    if MapSet.member?(normalized_paths, normalized_path) do
      report(checker, :duplicate_entries, id, "duplicate entry names")
      normalized_paths
    else
      MapSet.put(normalized_paths, normalized_path)
    end
  end

  defp duplicate_name?(this_name, data) do
    data = Enum.drop(data, Constants.object_id_length())

    {mode_str, data} = Enum.split_while(data, &(&1 != ?\s))
    mode = parse_octal(mode_str)

    data = Enum.drop(data, 1)

    {next_name, data} = Enum.split_while(data, &(&1 != 0))

    data = Enum.drop(data, 1)

    compare = Paths.compare_same_name(this_name, next_name, mode)

    cond do
      Enum.empty?(mode_str) or Enum.empty?(next_name) -> false
      compare == :lt -> false
      compare == :eq -> true
      compare == :gt -> duplicate_name?(this_name, data)
    end
  end

  defp parse_octal(data) do
    case Integer.parse(to_string(data), 8) do
      {n, _} when is_integer(n) -> n
      :error -> 0
    end
  end

  defp check_file_mode!(_checker, _id, [], _mode),
    do: raise(CorruptObjectError, why: "truncated in mode")

  defp check_file_mode!(_checker, _id, [?\s | data], mode),
    do: {mode, data}

  defp check_file_mode!(checker, id, [c | data], mode) when c >= ?0 and c <= ?7 do
    if c == ?0 and mode == 0,
      do: report(checker, :zero_padded_filemode, id, "mode starts with '0'")

    check_file_mode!(checker, id, data, mode * 8 + (c - ?0))
  end

  defp check_file_mode!(_checker, _id, _data, _mode),
    do: raise(CorruptObjectError, why: "invalid mode character")

  defp scan_path_segment(%{windows?: windows?} = checker, data, id) do
    {name, data} = Enum.split_while(data, &(&1 != 0))

    Enum.each(name, fn c ->
      if c == ?/,
        do: report(checker, :full_pathname, id, "name contains '/'")

      if windows? and invalid_on_windows?(c),
        do: raise_invalid_on_windows(c)
    end)

    {name, data}
  end

  defp scan_path_segment_with_nil(checker, data, id) do
    case scan_path_segment(checker, data, id) do
      {name, [0 | data]} -> {name, data}
      _ -> raise(CorruptObjectError, why: "truncated in name")
    end
  end

  defp raise_invalid_on_windows(c) when c > 31,
    do:
      raise(CorruptObjectError,
        why: "char '#{List.to_string([c])}' not allowed in Windows filename"
      )

  defp raise_invalid_on_windows(c),
    do:
      raise(CorruptObjectError, why: "byte 0x'#{byte_to_hex(c)}' not allowed in Windows filename")

  # private ObjectId idFor(int objType, byte[] raw) {
  #   PORTING NOTE: This is available as ObjectId.id_for/2.
  # }

  defp id_for(%__MODULE{skiplist: nil}, _obj_type, _raw), do: nil

  defp id_for(_chcker, obj_type, raw) do
    ObjectId.id_for(obj_type, raw)
  rescue
    _ -> nil
  end

  defp match_or_report!(%__MODULE__{} = checker, data,
         prefix: prefix,
         error_type: error_type,
         id: id,
         why: why
       ) do
    case RawParseUtils.match_prefix?(data, prefix) do
      {true, after_match} ->
        after_match

      _ ->
        report(checker, error_type, id, why)
        data
    end
  end

  defp report(
         %__MODULE__{skiplist: skiplist, ignore_error_types: ignore_error_types},
         error_type,
         id,
         why
       ) do
    with false <- ignore_error?(ignore_error_types, error_type),
         false <- skip_object_id?(skiplist, id) do
      if id != nil do
        raise(CorruptObjectError,
          id: id,
          error_type: error_type,
          why: why
        )
      else
        raise(CorruptObjectError, why: why)
      end
    else
      _ -> :ok
    end
  end

  defp ignore_error?(nil, _error_type), do: false

  defp ignore_error?(ignore_error_types, error_type),
    do: Map.get(ignore_error_types, error_type, false)

  defp skip_object_id?(nil, _object_id), do: false
  defp skip_object_id?(skiplist, object_id), do: MapSet.member?(skiplist, object_id)

  @doc ~S"""
  Check tree path entry for validity.

  ## Parameters

  `path` may be either a `String` or a byte list.

  Unlike `check_path_segment!/2`, this version scans a multi-directory path
  string such as `"src/main.c"`.

  ## Return Values

  Returns `:ok` if the path is deemed valid.

  ## Errors

  Raises `Xgit.Errors.CorruptObjectError` if the path is invalid.
  """
  @spec check_path!(checker :: t, path :: String.t() | charlist) :: :ok
  def check_path!(checker, path)

  def check_path!(%__MODULE__{} = checker, path) when is_binary(path),
    do: check_path!(checker, String.to_charlist(path))

  def check_path!(%__MODULE__{} = _checker, []),
    do: raise(CorruptObjectError, why: "empty path")

  def check_path!(%__MODULE__{} = _checker, [?/ | _]),
    do: raise(CorruptObjectError, why: "absolute path")

  def check_path!(%__MODULE__{} = checker, path) when is_list(path) do
    if Enum.any?(path, &(&1 == ?/)) do
      {this, remainder} = Enum.split_while(path, &(&1 != ?/))
      check_path_segment!(checker, this)
      check_path!(checker, Enum.drop(remainder, 1))
    else
      check_path_segment!(checker, path)
    end
  end

  @doc ~S"""
  Check tree path segment for validity.

  ## Parameters

  `path` may be either a `String` or a byte list.

  ## Return Values

  Returns `:ok` if the path is deemed valid.

  ## Errors

  Raises `Xgit.Errors.CorruptObjectError` if the path is invalid.
  """
  @spec check_path_segment!(checker :: t, data :: String.t() | charlist) :: :ok
  def check_path_segment!(%__MODULE__{} = checker, data) when is_list(data) do
    if Enum.any?(data, &(&1 == 0)),
      do: raise(CorruptObjectError, why: "name contains byte 0x00")

    {path, _remainder} = scan_path_segment(checker, data, nil)

    check_path_segment2(checker, path, nil)
    :ok
  end

  defp check_path_segment2(checker, [], id),
    do: report(checker, :empty_name, id, "zero length name")

  defp check_path_segment2(%__MODULE__{macosx?: macosx?, windows?: windows?} = checker, name, id) do
    check_path_segment_with_dot(checker, name, id)

    if macosx? && mac_hfs_git?(checker, name, id) do
      utf8_name = RawParseUtils.decode(name)

      report(
        checker,
        :has_dotgit,
        id,
        "invalid name '#{utf8_name}' contains ignorable Unicode characters"
      )
    end

    if windows? do
      # Windows ignores space and dot at end of file name.
      last_char = List.last(name)

      if last_char == ?\s || last_char == ?. do
        report(
          checker,
          :win32_bad_name,
          id,
          "invalid name ends with '#{<<last_char>>}'"
        )
      end

      lc_name =
        name
        |> Enum.map(&to_lower/1)
        |> Enum.take_while(&(&1 != ?.))

      if windows_device_name?(lc_name),
        do: report(checker, :win32_bad_name, id, "invalid name '#{name}'")
    end
  end

  defp check_path_segment_with_dot(checker, '.', id),
    do: report(checker, :has_dot, id, "invalid name '.'")

  defp check_path_segment_with_dot(checker, '..', id),
    do: report(checker, :has_dotdot, id, "invalid name '..'")

  defp check_path_segment_with_dot(checker, '.git', id),
    do: report(checker, :has_dotgit, id, "invalid name '.git'")

  defp check_path_segment_with_dot(checker, [?. | rem] = name, id) do
    if normalized_git?(rem),
      do: report(checker, :has_dotgit, id, "invalid name '#{name}'")
  end

  defp check_path_segment_with_dot(_checker, _name, _id), do: :ok

  # http://www.utf8-chartable.de/unicode-utf8-table.pl?start=8192
  defp match_mac_hfs_path?(checker, data, match, id, ignorable? \\ false)

  # U+200C 0xe2808c ZERO WIDTH NON-JOINER
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0x8C | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+200D 0xe2808d ZERO WIDTH JOINER
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0x8D | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+200E 0xe2808e LEFT-TO-RIGHT MARK
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0x8E | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+200F 0xe2808f RIGHT-TO-LEFT MARK
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0x8F | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+202A 0xe280aa LEFT-TO-RIGHT EMBEDDING
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0xAA | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+202B 0xe280ab RIGHT-TO-LEFT EMBEDDING
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0xAB | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+202C 0xe280ac POP DIRECTIONAL FORMATTING
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0xAC | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+202D 0xe280ad LEFT-TO-RIGHT OVERRIDE
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0xAD | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+202E 0xe280ae RIGHT-TO-LEFT OVERRIDE
  defp match_mac_hfs_path?(checker, [0xE2, 0x80, 0xAE | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  defp match_mac_hfs_path?(_checker, [0xE2, 0x80, _ | _], _match, _id, _ignorable?), do: false

  # U+206A 0xe281aa INHIBIT SYMMETRIC SWAPPING
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAA | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+206B 0xe281ab ACTIVATE SYMMETRIC SWAPPING
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAB | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+206C 0xe281ac INHIBIT ARABIC FORM SHAPING
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAC | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+206D 0xe281ad ACTIVATE ARABIC FORM SHAPING
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAD | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+206E 0xe281ae NATIONAL DIGIT SHAPES
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAE | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  # U+206F 0xe281af NOMINAL DIGIT SHAPES
  defp match_mac_hfs_path?(checker, [0xE2, 0x81, 0xAF | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  defp match_mac_hfs_path?(_checker, [0xE2, 0x81, _ | _], _match, _id, _ignorable?), do: false

  defp match_mac_hfs_path?(checker, [0xEF, 0xBB, 0xBF | data], match, id, _ignorable?),
    do: match_mac_hfs_path?(checker, data, match, id, true)

  defp match_mac_hfs_path?(_checker, [0xEF, _, _ | _], _match, _id, _ignorable?), do: false

  defp match_mac_hfs_path?(checker, [c | _] = list, _match, id, _ignorable?)
       when c == 0xE2 or c == 0xEF do
    check_truncated_ignorable_utf8(checker, list, id)
    false
  end

  defp match_mac_hfs_path?(checker, [c | data], [m | match], id, ignorable?) do
    if to_lower(c) == m,
      do: match_mac_hfs_path?(checker, data, match, id, ignorable?),
      else: false
  end

  defp match_mac_hfs_path?(_checker, [], [], _id, ignorable?), do: ignorable?
  defp match_mac_hfs_path?(_checker, _data, _match, _id, _ignorable?), do: false

  defp mac_hfs_git?(checker, name, id), do: match_mac_hfs_path?(checker, name, '.git', id)

  # defp mac_hfs_gitmodules?(%__MODULE__{macosx?: true}, name, id) do
  #   TODO
  #   return isMacHFSPath(raw, ptr, end, dotGitmodules, id);
  # end

  defp mac_hfs_gitmodules?(_checker, _name, _id), do: false

  defp check_truncated_ignorable_utf8(checker, data, id) do
    if Enum.drop(data, 3) == [] do
      report(
        checker,
        :bad_utf8,
        id,
        "invalid name contains byte sequence '#{to_hex_string(data)}' which is not a valid UTF-8 character"
      )

      false
    else
      true
    end
  end

  defp to_hex_string(data), do: "0x#{Enum.map_join(data, &byte_to_hex/1)}"

  defp byte_to_hex(b) when b < 16, do: "0" <> integer_to_lc_hex_string(b)
  defp byte_to_hex(b), do: integer_to_lc_hex_string(b)

  defp integer_to_lc_hex_string(b), do: b |> Integer.to_string(16) |> String.downcase()

  defp windows_device_name?('aux'), do: true
  defp windows_device_name?('con'), do: true
  defp windows_device_name?('com' ++ [d]), do: positive_digit?(d)
  defp windows_device_name?('lpt' ++ [d]), do: positive_digit?(d)
  defp windows_device_name?('nul'), do: true
  defp windows_device_name?('prn'), do: true
  defp windows_device_name?(_), do: false

  defp invalid_on_windows?(?"), do: true
  defp invalid_on_windows?(?*), do: true
  defp invalid_on_windows?(?:), do: true
  defp invalid_on_windows?(?<), do: true
  defp invalid_on_windows?(?>), do: true
  defp invalid_on_windows?(??), do: true
  defp invalid_on_windows?(?\\), do: true
  defp invalid_on_windows?(?|), do: true
  defp invalid_on_windows?(c) when c >= 1 and c <= 31, do: true
  defp invalid_on_windows?(_), do: false

  # The simpler approach would be to convert this to a string and use
  # String.downcase/1 on it. But that would create a lot of garbage to collect.
  # This approach is a bit more cumbersome, but more efficient.
  defp git_name_prefix?([?g | it]), do: it_name_prefix?(it)
  defp git_name_prefix?([?G | it]), do: it_name_prefix?(it)
  defp git_name_prefix?(_), do: false

  defp it_name_prefix?([?i | it]), do: t_name_prefix?(it)
  defp it_name_prefix?([?I | it]), do: t_name_prefix?(it)
  defp it_name_prefix?(_), do: false

  defp t_name_prefix?([?t | _]), do: true
  defp t_name_prefix?([?T | _]), do: true
  defp t_name_prefix?(_), do: false

  # Check if the filename contained in buf[start:end] could be read as a
  # .gitmodules file when checked out to the working directory.
  #
  # This ought to be a simple comparison, but some filesystems have peculiar
  # rules for normalizing filenames:
  #
  # NTFS has backward-compatibility support for 8.3 synonyms of long file
  # names (see
  # https://web.archive.org/web/20160318181041/https://usn.pw/blog/gen/2015/06/09/filenames/
  # for details). NTFS is also case-insensitive.
  #
  # MacOS's HFS+ folds away ignorable Unicode characters in addition to case
  # folding.
  defp gitmodules?(_checker, '.gitmodules', _id), do: true

  defp gitmodules?(checker, name, id),
    do: mac_hfs_gitmodules?(checker, name, id) || ntfs_gitmodules?(checker, name)

  defp ntfs_gitmodules?(%__MODULE__{windows?: true}, name) do
    length = Enum.count(name)

    if length == 8 || length == 11,
      do: ntfs_gitmodules?(Enum.map(name, &to_lower(&1))),
      else: false
  end

  defp ntfs_gitmodules?(_checker, _name), do: false

  defp ntfs_gitmodules?('.gitmodules'), do: true
  defp ntfs_gitmodules?('gitmod~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('gi7eba~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('gi7eb~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('gi7e~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('gi7~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('gi~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('g~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?('~' ++ rem), do: ntfs_numeric_suffix?(rem)
  defp ntfs_gitmodules?(_), do: false

  # The first digit of the numeric suffix must not be zero.
  defp ntfs_numeric_suffix?([?0 | _rem]), do: false
  defp ntfs_numeric_suffix?(rem), do: ntfs_numeric_suffix_zero_ok?(rem)

  defp ntfs_numeric_suffix_zero_ok?([c | rem]) when c >= ?0 and c <= ?9,
    do: ntfs_numeric_suffix_zero_ok?(rem)

  defp ntfs_numeric_suffix_zero_ok?([]), do: true
  defp ntfs_numeric_suffix_zero_ok?(_), do: false

  defp normalized_git?(name) do
    if git_name_prefix?(name) do
      name
      |> Enum.drop(3)
      |> valid_git_suffix?()
    else
      false
    end
  end

  defp valid_git_suffix?([]), do: true
  defp valid_git_suffix?(' '), do: true
  defp valid_git_suffix?('.'), do: true
  defp valid_git_suffix?('. '), do: true
  defp valid_git_suffix?(' .'), do: true
  defp valid_git_suffix?(' . '), do: true
  defp valid_git_suffix?(_), do: false

  defp to_lower(b) when b >= ?A and b <= ?Z, do: b + 32
  defp to_lower(b), do: b

  defp positive_digit?(b) when b >= ?1 and b <= ?9, do: true
  defp positive_digit?(_), do: false

  defp normalize(%__MODULE__{macosx?: true}, name) when is_list(name) do
    name
    |> RawParseUtils.decode()
    |> String.downcase()
    |> :unicode.characters_to_nfc_binary()
  end

  defp normalize(_checker, name) when is_list(name), do: Enum.map(name, &to_lower/1)
end
