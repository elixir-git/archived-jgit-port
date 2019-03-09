defmodule Xgit.Lib.ObjectChecker do
  @moduledoc ~S"""
  Verifies that an object is formatted correctly.

  Verifications made by this module only check that the fields of an object are
  formatted correctly. The ObjectId checksum of the object is not verified, and
  connectivity links between objects are also not verified. Its assumed that
  the caller can provide both of these validations on its own.
  """

  alias Xgit.Errors.CorruptObjectError
  alias Xgit.Lib.Constants
  alias Xgit.Lib.FileMode
  alias Xgit.Lib.ObjectId
  alias Xgit.Util.RawParseUtils

  use EnumType

  defprotocol Strategy do
    @doc ~S"""
    Check a commit for errors.

    Return `:ok` if commit is validated.

    Return `:default` to reuse the default implementation.

    Raise `CorruptObjectError` if the commit is invalid.
    """
    def check_commit!(strategy, commit_data)

    @doc ~S"""
    Check a blob for errors.

    Return `:ok` if blob is validated.

    Return `:default` to reuse the default implementation.

    Raise `CorruptObjectError` if the blob is invalid.
    """
    def check_blob!(strategy, blob_data)
  end

  # Potential issues that can be identified by the checker.
  # These names match git-core so that fsck section keys also match.
  defenum ErrorType do
    value(NULL_SHA1, 0)
    value(DUPLICATE_ENTRIES, 1)
    value(TREE_NOT_SORTED, 2)
    value(ZERO_PADDED_FILEMODE, 3)
    value(EMPTY_NAME, 4)
    value(FULL_PATHNAME, 5)
    value(HAS_DOT, 6)
    value(HAS_DOTDOT, 7)
    value(HAS_DOTGIT, 8)
    value(BAD_OBJECT_SHA1, 9)
    value(BAD_PARENT_SHA1, 10)
    value(BAD_TREE_SHA1, 11)
    value(MISSING_AUTHOR, 12)
    value(MISSING_COMMITTER, 13)
    value(MISSING_OBJECT, 14)
    value(MISSING_TREE, 15)
    value(MISSING_TYPE_ENTRY, 16)
    value(MISSING_TAG_ENTRY, 17)
    value(BAD_DATE, 18)
    value(BAD_EMAIL, 19)
    value(BAD_TIMEZONE, 20)
    value(MISSING_EMAIL, 21)
    value(MISSING_SPACE_BEFORE_DATE, 22)
    value(GITMODULES_BLOB, 23)
    value(GITMODULES_LARGE, 24)
    value(GITMODULES_NAME, 25)
    value(GITMODULES_PARSE, 26)
    value(GITMODULES_PATH, 27)
    value(GITMODULES_SYMLINK, 28)
    value(GITMODULES_URL, 29)
    value(UNKNOWN_TYPE, 30)

    # The following items are unique to xgit.
    value(WIN32_BAD_NAME, 31)
    value(BAD_UTF8, 32)

    # /** @return camelCaseVersion of the name. */
    # public String getMessageId() {
    # 	String n = name();
    # 	StringBuilder r = new StringBuilder(n.length());
    # 	for (int i = 0; i < n.length(); i++) {
    # 		char c = n.charAt(i);
    # 		if (c != '_') {
    # 			r.append(StringUtils.toLowerCase(c));
    # 		} else {
    # 			r.append(n.charAt(++i));
    # 		}
    # 	}
    # 	return r.toString();
    # }
  end

  defstruct strategy: nil,
            skiplist: nil,
            ignore_error_types: nil,
            allow_invalid_person_ident?: false,
            windows?: false,
            macosx?: false

  @doc ~S"""
  Check an object for parsing errors.

  `type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.

  `data` is the raw data which comprises the object. This should be in the
  canonical format (that is the format used to generate the `object_id` of
  the object).

  Raises `Xgit.Errors.CorruptObjectError` if an error is identified.
  """
  def check!(%__MODULE__{} = checker, obj_type, data)
      when is_integer(obj_type) and is_list(data) do
    check!(checker, id_for(checker, obj_type, data), obj_type, data)
  end

  @doc ~S"""
  Check an object for parsing errors.

  Like `check/3` but `id` has already been calculated.
  def
  """
  def check!(checker, id, obj_type, data)

  # def check(%ObjectChecker{} = checker, id, obj_type, data) when is_binary(id) is_integer(obj_type) and is_list(data) do
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
    report(checker, ErrorType.UNKNOWN_TYPE, id, "invalid type #{obj_type}")
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
    do: {ErrorType.MISSING_EMAIL, "missing email"}

  defp error_type_and_message_for_cause(:bad_email),
    do: {ErrorType.MISSING_EMAIL, "bad email"}

  defp error_type_and_message_for_cause(:missing_space_before_date),
    do: {ErrorType.MISSING_SPACE_BEFORE_DATE, "bad date"}

  defp error_type_and_message_for_cause(:bad_date),
    do: {ErrorType.BAD_DATE, "bad date"}

  defp error_type_and_message_for_cause(:bad_timezone),
    do: {ErrorType.BAD_TIMEZONE, "bad time zone"}

  defp check_commit!(%__MODULE__{} = checker, id, data) do
    data =
      match_or_report!(checker, data,
        prefix: 'tree ',
        error_type: ErrorType.MISSING_TREE,
        id: id,
        why: "no tree header"
      )

    data =
      check_id_or_report!(checker, data,
        error_type: ErrorType.BAD_TREE_SHA1,
        id: id,
        why: "invalid tree"
      )

    data = check_commit_parents!(checker, id, data)

    data =
      match_or_report!(checker, data,
        prefix: 'author ',
        error_type: ErrorType.MISSING_AUTHOR,
        id: id,
        why: "no author"
      )

    data = check_person_ident_or_report!(checker, id, data)

    data =
      match_or_report!(checker, data,
        prefix: 'committer ',
        error_type: ErrorType.MISSING_COMMITTER,
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
            error_type: ErrorType.BAD_PARENT_SHA1,
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
        error_type: ErrorType.MISSING_TREE,
        id: id,
        why: "no object header"
      )

    data =
      check_id_or_report!(checker, data,
        error_type: ErrorType.BAD_TREE_SHA1,
        id: id,
        why: "invalid object"
      )

    data =
      match_or_report!(checker, data,
        prefix: 'type ',
        error_type: ErrorType.MISSING_TREE,
        id: id,
        why: "no type header"
      )

    data = RawParseUtils.next_lf(data)

    data =
      match_or_report!(checker, data,
        prefix: 'tag ',
        error_type: ErrorType.MISSING_TAG,
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

  # private static boolean duplicateName(final byte[] raw,
  # 		final int thisNamePos, final int thisNameEnd) {
  # 	final int sz = raw.length;
  # 	int nextPtr = thisNameEnd + 1 + Constants.OBJECT_ID_LENGTH;
  # 	for (;;) {
  # 		int nextMode = 0;
  # 		for (;;) {
  # 			if (nextPtr >= sz)
  # 				return false;
  # 			final byte c = raw[nextPtr++];
  # 			if (' ' == c)
  # 				break;
  # 			nextMode <<= 3;
  # 			nextMode += c - '0';
  # 		}
  #
  # 		final int nextNamePos = nextPtr;
  # 		for (;;) {
  # 			if (nextPtr == sz)
  # 				return false;
  # 			final byte c = raw[nextPtr++];
  # 			if (c == 0)
  # 				break;
  # 		}
  # 		if (nextNamePos + 1 == nextPtr)
  # 			return false;
  #
  # 		int cmp = compareSameName(
  # 				raw, thisNamePos, thisNameEnd,
  # 				raw, nextNamePos, nextPtr - 1, nextMode);
  # 		if (cmp < 0)
  # 			return false;
  # 		else if (cmp == 0)
  # 			return true;
  #
  # 		nextPtr += Constants.OBJECT_ID_LENGTH;
  # 	}
  # }

  defp check_tree!(%__MODULE__{windows?: true} = checker, id, data),
    do: check_tree!(checker, id, data, MapSet.new(), [])

  defp check_tree!(%__MODULE__{macosx?: true} = checker, id, data),
    do: check_tree!(checker, id, data, MapSet.new(), [])

  defp check_tree!(%__MODULE__{} = checker, id, data),
    do: check_tree!(checker, id, data, nil, [])

  defp check_tree!(_checker, _id, [] = _data, _maybe_normalized_paths, _previous_name), do: :ok

  defp check_tree!(%__MODULE__{} = checker, id, data, maybe_normalized_paths, _previous_name) do
    # Scan one entry then recurse to scan remaining entries.

    {file_mode, data} = check_file_mode!(checker, id, data, 0)

    file_mode_type = FileMode.from_bits(file_mode).object_type

    if file_mode_type == Constants.obj_bad(),
      do: raise(CorruptObjectError, why: "invalid mode #{file_mode}")

    # need to port that..
    {this_name, data} = scan_path_segment(checker, data, id)

    unless [0 | data] = data, do: raise(CorruptObjectError, why: "truncated in name")

    check_path_segment2(checker, this_name, id)

    # PORTING NOTE: normalized became maybe_normalized_paths
    # if (normalized != null) {
    # 	if (!normalized.add(normalize(raw, thisNameB, ptr))) {
    # 		report(DUPLICATE_ENTRIES, id,
    # 				JGitText.get().corruptObjectDuplicateEntryNames);
    # 	}
    # } else if (duplicateName(raw, thisNameB, ptr)) {
    # 	report(DUPLICATE_ENTRIES, id,
    # 			JGitText.get().corruptObjectDuplicateEntryNames);
    # }
    #
    # if (lastNameB != 0) {
    # 	int cmp = compare(
    # 			raw, lastNameB, lastNameE, lastMode,
    # 			raw, thisNameB, ptr, thisMode);
    # 	if (cmp > 0) {
    # 		report(TREE_NOT_SORTED, id,
    # 				JGitText.get().corruptObjectIncorrectSorting);
    # 	}
    # }

    {raw_object_id, data} = Enum.split(data, Constants.object_id_length())

    if Enum.count(raw_object_id) != Constants.object_id_length(),
      do: raise(CorruptObjectError, why: "truncated in object id")

    if Enum.all?(raw_object_id, &(&1 == 0)),
      do: report(checker, ErrorType.NULL_SHA1, id, "entry points to null SHA-1")

    # TODO
    # if (id != null && isGitmodules(raw, lastNameB, lastNameE, id)) {
    # 	ObjectId blob = ObjectId.fromRaw(raw, ptr - OBJECT_ID_LENGTH);
    # 	gitsubmodules.add(new GitmoduleEntry(id, blob));
    # }

    check_tree!(checker, id, data, maybe_normalized_paths, this_name)
  end

  defp check_file_mode!(_checker, _id, [], _mode),
    do: raise(CorruptObjectError, why: "truncated in mode")

  defp check_file_mode!(_checker, _id, [?\s | data], mode),
    do: {mode, data}

  defp check_file_mode!(checker, id, [c | data], mode) when c >= ?0 and c <= ?7 do
    if c == ?0 and mode == 0,
      do: report(checker, ErrorType.ZERO_PADDED_FILEMODE, id, "mode starts with '0'")

    check_file_mode!(checker, id, data, mode * 8 + (c - ?0))
  end

  defp check_file_mode!(_checker, _id, _data, _mode),
    do: raise(CorruptObjectError, why: "invalid mode character")

  defp scan_path_segment(%{windows?: windows?} = checker, data, id) do
    {name, data} = Enum.split_while(data, &(&1 != 0))

    Enum.each(name, fn c ->
      if c == ?/, do: report(checker, ErrorType.FULL_PATHNAME, id, "name contains '/'")

      if windows? and invalid_on_windows?(c) do
        if c > 31,
          do:
            raise(CorruptObjectError,
              why: "name contains '#{List.to_string([c])}'",
              else:
                raise(CorruptObjectError,
                  why: "name contains byte 0x'#{Integer.to_string(c, 16)}'"
                )
            )
      end
    end)

    {name, data}
  end

  # private ObjectId idFor(int objType, byte[] raw) {
  #   PORTING NOTE: This is available as ObjectId.id_for/2.
  # }

  defp id_for(%__MODULE{skiplist: nil}, _obj_type, _raw), do: nil

  defp id_for(_chcker, obj_type, raw) do
    try do
      ObjectId.id_for(obj_type, raw)
    rescue
      _ -> nil
    end
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
    do: !MapSet.member?(ignore_error_types, error_type)

  defp skip_object_id?(nil, _object_id), do: false
  defp skip_object_id?(skiplist, object_id), do: MapSet.member?(skiplist, object_id)

  # private void report(@NonNull ErrorType err, @Nullable AnyObjectId id,
  # 		String why) throws CorruptObjectException {
  # 	if (errors.contains(err)
  # 			&& (id == null || skipList == null || !skipList.contains(id))) {
  # 		if (id != null) {
  # 			throw new CorruptObjectException(err, id, why);
  # 		}
  # 		throw new CorruptObjectException(why);
  # 	}
  # }

  # /**
  #  * Check tree path entry for validity.
  #  * <p>
  #  * Unlike {@link #checkPathSegment(byte[], int, int)}, this version scans a
  #  * multi-directory path string such as {@code "src/main.c"}.
  #  *
  #  * @param path
  #  *            path string to scan.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             path is invalid.
  #  * @since 3.6
  #  */
  # public void checkPath(String path) throws CorruptObjectException {
  # 	byte[] buf = Constants.encode(path);
  # 	checkPath(buf, 0, buf.length);
  # }
  #
  # /**
  #  * Check tree path entry for validity.
  #  * <p>
  #  * Unlike {@link #checkPathSegment(byte[], int, int)}, this version scans a
  #  * multi-directory path string such as {@code "src/main.c"}.
  #  *
  #  * @param raw
  #  *            buffer to scan.
  #  * @param ptr
  #  *            offset to first byte of the name.
  #  * @param end
  #  *            offset to one past last byte of name.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             path is invalid.
  #  * @since 3.6
  #  */
  # public void checkPath(byte[] raw, int ptr, int end)
  # 		throws CorruptObjectException {
  # 	int start = ptr;
  # 	for (; ptr < end; ptr++) {
  # 		if (raw[ptr] == '/') {
  # 			checkPathSegment(raw, start, ptr);
  # 			start = ptr + 1;
  # 		}
  # 	}
  # 	checkPathSegment(raw, start, end);
  # }
  #
  # /**
  #  * Check tree path entry for validity.
  #  *
  #  * @param raw
  #  *            buffer to scan.
  #  * @param ptr
  #  *            offset to first byte of the name.
  #  * @param end
  #  *            offset to one past last byte of name.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             name is invalid.
  #  * @since 3.4
  #  */
  # public void checkPathSegment(byte[] raw, int ptr, int end)
  # 		throws CorruptObjectException {
  # 	int e = scanPathSegment(raw, ptr, end, null);
  # 	if (e < end && raw[e] == 0)
  # 		throw new CorruptObjectException(
  # 				JGitText.get().corruptObjectNameContainsNullByte);
  # 	checkPathSegment2(raw, ptr, end, null);
  # }

  defp check_path_segment2(checker, [], id),
    do: report(checker, ErrorType.EMPTY_NAME, id, "zero length name")

  defp check_path_segment2(checker, name, id) do
    check_path_segment_with_dot(checker, name, id)

    # TODO
    # if (macosx && isMacHFSGit(raw, ptr, end, id)) {
    # 	report(HAS_DOTGIT, id, String.format(
    # 			JGitText.get().corruptObjectInvalidNameIgnorableUnicode,
    # 			RawParseUtils.decode(raw, ptr, end)));
    # }
    #
    # if (windows) {
    # 	// Windows ignores space and dot at end of file name.
    # 	if (raw[end - 1] == ' ' || raw[end - 1] == '.') {
    # 		report(WIN32_BAD_NAME, id, String.format(
    # 				JGitText.get().corruptObjectInvalidNameEnd,
    # 				Character.valueOf(((char) raw[end - 1]))));
    # 	}
    # 	if (end - ptr >= 3) {
    # 		checkNotWindowsDevice(raw, ptr, end, id);
    # 	}
    # }
  end

  defp check_path_segment_with_dot(checker, '.', id),
    do: report(checker, ErrorType.HAS_DOT, id, "invalid name '.'")

  defp check_path_segment_with_dot(checker, '..', id),
    do: report(checker, ErrorType.HAS_DOTDOT, id, "invalid name '..'")

  defp check_path_segment_with_dot(checker, '.git', id),
    do: report(checker, ErrorType.HAS_DOTGIT, id, "invalid name '.git'")

  defp check_path_segment_with_dot(checker, [?. | _] = name, id) do
    if normalized_git?(name),
      do: report(checker, ErrorType.HAS_DOTGIT, id, "invalid name '#{name}'")
  end

  defp check_path_segment_with_dot(_checker, _name, _id) do
    # TODO
    # 	} else if (isGitTilde1(raw, ptr, end)) {
    # 		report(HAS_DOTGIT, id, String.format(
    # 				JGitText.get().corruptObjectInvalidName,
    # 				RawParseUtils.decode(raw, ptr, end)));
  end

  # // Mac's HFS+ folds permutations of ".git" and Unicode ignorable characters
  # // to ".git" therefore we should prevent such names
  # private boolean isMacHFSPath(byte[] raw, int ptr, int end, byte[] path,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	boolean ignorable = false;
  # 	int g = 0;
  # 	while (ptr < end) {
  # 		switch (raw[ptr]) {
  # 		case (byte) 0xe2: // http://www.utf8-chartable.de/unicode-utf8-table.pl?start=8192
  # 			if (!checkTruncatedIgnorableUTF8(raw, ptr, end, id)) {
  # 				return false;
  # 			}
  # 			switch (raw[ptr + 1]) {
  # 			case (byte) 0x80:
  # 				switch (raw[ptr + 2]) {
  # 				case (byte) 0x8c:	// U+200C 0xe2808c ZERO WIDTH NON-JOINER
  # 				case (byte) 0x8d:	// U+200D 0xe2808d ZERO WIDTH JOINER
  # 				case (byte) 0x8e:	// U+200E 0xe2808e LEFT-TO-RIGHT MARK
  # 				case (byte) 0x8f:	// U+200F 0xe2808f RIGHT-TO-LEFT MARK
  # 				case (byte) 0xaa:	// U+202A 0xe280aa LEFT-TO-RIGHT EMBEDDING
  # 				case (byte) 0xab:	// U+202B 0xe280ab RIGHT-TO-LEFT EMBEDDING
  # 				case (byte) 0xac:	// U+202C 0xe280ac POP DIRECTIONAL FORMATTING
  # 				case (byte) 0xad:	// U+202D 0xe280ad LEFT-TO-RIGHT OVERRIDE
  # 				case (byte) 0xae:	// U+202E 0xe280ae RIGHT-TO-LEFT OVERRIDE
  # 					ignorable = true;
  # 					ptr += 3;
  # 					continue;
  # 				default:
  # 					return false;
  # 				}
  # 			case (byte) 0x81:
  # 				switch (raw[ptr + 2]) {
  # 				case (byte) 0xaa:	// U+206A 0xe281aa INHIBIT SYMMETRIC SWAPPING
  # 				case (byte) 0xab:	// U+206B 0xe281ab ACTIVATE SYMMETRIC SWAPPING
  # 				case (byte) 0xac:	// U+206C 0xe281ac INHIBIT ARABIC FORM SHAPING
  # 				case (byte) 0xad:	// U+206D 0xe281ad ACTIVATE ARABIC FORM SHAPING
  # 				case (byte) 0xae:	// U+206E 0xe281ae NATIONAL DIGIT SHAPES
  # 				case (byte) 0xaf:	// U+206F 0xe281af NOMINAL DIGIT SHAPES
  # 					ignorable = true;
  # 					ptr += 3;
  # 					continue;
  # 				default:
  # 					return false;
  # 				}
  # 			default:
  # 				return false;
  # 			}
  # 		case (byte) 0xef: // http://www.utf8-chartable.de/unicode-utf8-table.pl?start=65024
  # 			if (!checkTruncatedIgnorableUTF8(raw, ptr, end, id)) {
  # 				return false;
  # 			}
  # 			// U+FEFF 0xefbbbf ZERO WIDTH NO-BREAK SPACE
  # 			if ((raw[ptr + 1] == (byte) 0xbb)
  # 					&& (raw[ptr + 2] == (byte) 0xbf)) {
  # 				ignorable = true;
  # 				ptr += 3;
  # 				continue;
  # 			}
  # 			return false;
  # 		default:
  # 			if (g == path.length) {
  # 				return false;
  # 			}
  # 			if (toLower(raw[ptr++]) != path[g++]) {
  # 				return false;
  # 			}
  # 		}
  # 	}
  # 	if (g == path.length && ignorable) {
  # 		return true;
  # 	}
  # 	return false;
  # }
  #
  # private boolean isMacHFSGit(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	byte[] git = new byte[] { '.', 'g', 'i', 't' };
  # 	return isMacHFSPath(raw, ptr, end, git, id);
  # }
  #
  # private boolean isMacHFSGitmodules(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	return isMacHFSPath(raw, ptr, end, dotGitmodules, id);
  # }
  #
  # private boolean checkTruncatedIgnorableUTF8(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	if ((ptr + 2) >= end) {
  # 		report(BAD_UTF8, id, MessageFormat.format(
  # 				JGitText.get().corruptObjectInvalidNameInvalidUtf8,
  # 				toHexString(raw, ptr, end)));
  # 		return false;
  # 	}
  # 	return true;
  # }
  #
  # private static String toHexString(byte[] raw, int ptr, int end) {
  # 	StringBuilder b = new StringBuilder("0x"); //$NON-NLS-1$
  # 	for (int i = ptr; i < end; i++)
  # 		b.append(String.format("%02x", Byte.valueOf(raw[i]))); //$NON-NLS-1$
  # 	return b.toString();
  # }
  #
  # private void checkNotWindowsDevice(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	switch (toLower(raw[ptr])) {
  # 	case 'a': // AUX
  # 		if (end - ptr >= 3
  # 				&& toLower(raw[ptr + 1]) == 'u'
  # 				&& toLower(raw[ptr + 2]) == 'x'
  # 				&& (end - ptr == 3 || raw[ptr + 3] == '.')) {
  # 			report(WIN32_BAD_NAME, id,
  # 					JGitText.get().corruptObjectInvalidNameAux);
  # 		}
  # 		break;
  #
  # 	case 'c': // CON, COM[1-9]
  # 		if (end - ptr >= 3
  # 				&& toLower(raw[ptr + 2]) == 'n'
  # 				&& toLower(raw[ptr + 1]) == 'o'
  # 				&& (end - ptr == 3 || raw[ptr + 3] == '.')) {
  # 			report(WIN32_BAD_NAME, id,
  # 					JGitText.get().corruptObjectInvalidNameCon);
  # 		}
  # 		if (end - ptr >= 4
  # 				&& toLower(raw[ptr + 2]) == 'm'
  # 				&& toLower(raw[ptr + 1]) == 'o'
  # 				&& isPositiveDigit(raw[ptr + 3])
  # 				&& (end - ptr == 4 || raw[ptr + 4] == '.')) {
  # 			report(WIN32_BAD_NAME, id, String.format(
  # 					JGitText.get().corruptObjectInvalidNameCom,
  # 					Character.valueOf(((char) raw[ptr + 3]))));
  # 		}
  # 		break;
  #
  # 	case 'l': // LPT[1-9]
  # 		if (end - ptr >= 4
  # 				&& toLower(raw[ptr + 1]) == 'p'
  # 				&& toLower(raw[ptr + 2]) == 't'
  # 				&& isPositiveDigit(raw[ptr + 3])
  # 				&& (end - ptr == 4 || raw[ptr + 4] == '.')) {
  # 			report(WIN32_BAD_NAME, id, String.format(
  # 					JGitText.get().corruptObjectInvalidNameLpt,
  # 					Character.valueOf(((char) raw[ptr + 3]))));
  # 		}
  # 		break;
  #
  # 	case 'n': // NUL
  # 		if (end - ptr >= 3
  # 				&& toLower(raw[ptr + 1]) == 'u'
  # 				&& toLower(raw[ptr + 2]) == 'l'
  # 				&& (end - ptr == 3 || raw[ptr + 3] == '.')) {
  # 			report(WIN32_BAD_NAME, id,
  # 					JGitText.get().corruptObjectInvalidNameNul);
  # 		}
  # 		break;
  #
  # 	case 'p': // PRN
  # 		if (end - ptr >= 3
  # 				&& toLower(raw[ptr + 1]) == 'r'
  # 				&& toLower(raw[ptr + 2]) == 'n'
  # 				&& (end - ptr == 3 || raw[ptr + 3] == '.')) {
  # 			report(WIN32_BAD_NAME, id,
  # 					JGitText.get().corruptObjectInvalidNamePrn);
  # 		}
  # 		break;
  # 	}
  # }

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

  # /**
  #  * Check if the filename contained in buf[start:end] could be read as a
  #  * .gitmodules file when checked out to the working directory.
  #  *
  #  * This ought to be a simple comparison, but some filesystems have peculiar
  #  * rules for normalizing filenames:
  #  *
  #  * NTFS has backward-compatibility support for 8.3 synonyms of long file
  #  * names (see
  #  * https://web.archive.org/web/20160318181041/https://usn.pw/blog/gen/2015/06/09/filenames/
  #  * for details). NTFS is also case-insensitive.
  #  *
  #  * MacOS's HFS+ folds away ignorable Unicode characters in addition to case
  #  * folding.
  #  *
  #  * @param buf
  #  *            byte array to decode
  #  * @param start
  #  *            position where a supposed filename is starting
  #  * @param end
  #  *            position where a supposed filename is ending
  #  * @param id
  #  *            object id for error reporting
  #  *
  #  * @return true if the filename in buf could be a ".gitmodules" file
  #  * @throws CorruptObjectException
  #  */
  # private boolean isGitmodules(byte[] buf, int start, int end, @Nullable AnyObjectId id)
  # 		throws CorruptObjectException {
  # 	// Simple cases first.
  # 	if (end - start < 8) {
  # 		return false;
  # 	}
  # 	return (end - start == dotGitmodules.length
  # 			&& RawParseUtils.match(buf, start, dotGitmodules) != -1)
  # 		|| (macosx && isMacHFSGitmodules(buf, start, end, id))
  # 		|| (windows && isNTFSGitmodules(buf, start, end));
  # }
  #
  # private boolean matchLowerCase(byte[] b, int ptr, byte[] src) {
  # 	if (ptr + src.length > b.length) {
  # 		return false;
  # 	}
  # 	for (int i = 0; i < src.length; i++, ptr++) {
  # 		if (toLower(b[ptr]) != src[i]) {
  # 			return false;
  # 		}
  # 	}
  # 	return true;
  # }
  #
  # // .gitmodules, case-insensitive, or an 8.3 abbreviation of the same.
  # private boolean isNTFSGitmodules(byte[] buf, int start, int end) {
  # 	if (end - start == 11) {
  # 		return matchLowerCase(buf, start, dotGitmodules);
  # 	}
  #
  # 	if (end - start != 8) {
  # 		return false;
  # 	}
  #
  # 	// "gitmod" or a prefix of "gi7eba", followed by...
  # 	byte[] gitmod = new byte[]{'g', 'i', 't', 'm', 'o', 'd', '~'};
  # 	if (matchLowerCase(buf, start, gitmod)) {
  # 		start += 6;
  # 	} else {
  # 		byte[] gi7eba = new byte[]{'g', 'i', '7', 'e', 'b', 'a'};
  # 		for (int i = 0; i < gi7eba.length; i++, start++) {
  # 			byte c = (byte) toLower(buf[start]);
  # 			if (c == '~') {
  # 				break;
  # 			}
  # 			if (c != gi7eba[i]) {
  # 				return false;
  # 			}
  # 		}
  # 	}
  #
  # 	// ... ~ and a number
  # 	if (end - start < 2) {
  # 		return false;
  # 	}
  # 	if (buf[start] != '~') {
  # 		return false;
  # 	}
  # 	start++;
  # 	if (buf[start] < '1' || buf[start] > '9') {
  # 		return false;
  # 	}
  # 	start++;
  # 	for (; start != end; start++) {
  # 		if (buf[start] < '0' || buf[start] > '9') {
  # 			return false;
  # 		}
  # 	}
  # 	return true;
  # }
  #
  # private static boolean isGitTilde1(byte[] buf, int p, int end) {
  # 	if (end - p != 5)
  # 		return false;
  # 	return toLower(buf[p]) == 'g' && toLower(buf[p + 1]) == 'i'
  # 			&& toLower(buf[p + 2]) == 't' && buf[p + 3] == '~'
  # 			&& buf[p + 4] == '1';
  # }

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
  defp valid_git_suffix?('.'), do: true
  defp valid_git_suffix?('. '), do: true
  defp valid_git_suffix?(' .'), do: true
  defp valid_git_suffix?(_), do: false

  # private static char toLower(byte b) {
  # 	if ('A' <= b && b <= 'Z')
  # 		return (char) (b + ('a' - 'A'));
  # 	return (char) b;
  # }
  #
  # private static boolean isPositiveDigit(byte b) {
  # 	return '1' <= b && b <= '9';
  # }

  # private String normalize(byte[] raw, int ptr, int end) {
  # 	String n = RawParseUtils.decode(raw, ptr, end).toLowerCase(Locale.US);
  # 	return macosx ? Normalizer.normalize(n, Normalizer.Form.NFC) : n;
  # }
end
