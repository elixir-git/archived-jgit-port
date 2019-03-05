defmodule Xgit.Lib.ObjectChecker do
  @moduledoc ~S"""
  Verifies that an object is formatted correctly.

  Verifications made by this module only check that the fields of an object are
  formatted correctly. The ObjectId checksum of the object is not verified, and
  connectivity links between objects are also not verified. Its assumed that
  the caller can provide both of these validations on its own.
  """

  alias Xgit.Errors.CorruptObjectError
  alias Xgit.Lib.ObjectId

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

    @doc ~S"""
    Create a new `BlobObjectChecker`.

    Can return `nil`.
    """
    def new_blob_object_checker(strategy)
  end

  # PORTING NOTE:
  # The following methods are dynamically overridden in jgit:
  # * checkCommit
  # * checkBlob
  # * newBlobObjectChecker

  # Header strings defined by git object format (uncomment as needed below)
  # @header_tree 'tree '
  # @header_parent 'parent '
  # @header_author 'author '
  # @header_committer 'committer '
  # @header_encoding 'encoding '
  # @header_object 'object '
  # @header_type 'type '
  # @header_tag 'tag '
  # @header_tagger 'tagger '
  # @dot_git_modules '.gitmodules'

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

  # PORTING NOTE: Need to account for configuration vs current state (which probably
  # needs to be passed around, rather than accumulated). Struct is configuration.

  # private final MutableObjectId tempId = new MutableObjectId();
  # private final MutableInteger bufPtr = new MutableInteger();
  # private EnumSet<ErrorType> errors = EnumSet.allOf(ErrorType.class);
  # private final List<GitmoduleEntry> gitsubmodules = new ArrayList<>();

  defstruct strategy: nil,
            skiplist: nil,
            ignore_error_types: nil,
            allow_invalid_person_ident?: false,
            windows?: false,
            macosx?: false

  # /**
  #  * Enable accepting specific malformed (but not horribly broken) objects.
  #  *
  #  * @param objects
  #  *            collection of object names known to be broken in a non-fatal
  #  *            way that should be ignored by the checker.
  #  * @return {@code this}
  #  * @since 4.2
  #  */
  # public ObjectChecker setSkipList(@Nullable ObjectIdSet objects) {
  # 	skipList = objects;
  # 	return this;
  # }
  #
  # /**
  #  * Configure error types to be ignored across all objects.
  #  *
  #  * @param ids
  #  *            error types to ignore. The caller's set is copied.
  #  * @return {@code this}
  #  * @since 4.2
  #  */
  # public ObjectChecker setIgnore(@Nullable Set<ErrorType> ids) {
  # 	errors = EnumSet.allOf(ErrorType.class);
  # 	if (ids != null) {
  # 		errors.removeAll(ids);
  # 	}
  # 	return this;
  # }
  #
  # /**
  #  * Add message type to be ignored across all objects.
  #  *
  #  * @param id
  #  *            error type to ignore.
  #  * @param ignore
  #  *            true to ignore this error; false to treat the error as an
  #  *            error and throw.
  #  * @return {@code this}
  #  * @since 4.2
  #  */
  # public ObjectChecker setIgnore(ErrorType id, boolean ignore) {
  # 	if (ignore) {
  # 		errors.remove(id);
  # 	} else {
  # 		errors.add(id);
  # 	}
  # 	return this;
  # }
  #
  # /**
  #  * Enable accepting leading zero mode in tree entries.
  #  * <p>
  #  * Some broken Git libraries generated leading zeros in the mode part of
  #  * tree entries. This is technically incorrect but gracefully allowed by
  #  * git-core. JGit rejects such trees by default, but may need to accept
  #  * them on broken histories.
  #  * <p>
  #  * Same as {@code setIgnore(ZERO_PADDED_FILEMODE, allow)}.
  #  *
  #  * @param allow allow leading zero mode.
  #  * @return {@code this}.
  #  * @since 3.4
  #  */
  # public ObjectChecker setAllowLeadingZeroFileMode(boolean allow) {
  # 	return setIgnore(ZERO_PADDED_FILEMODE, allow);
  # }
  #
  # /**
  #  * Enable accepting invalid author, committer and tagger identities.
  #  * <p>
  #  * Some broken Git versions/libraries allowed users to create commits and
  #  * tags with invalid formatting between the name, email and timestamp.
  #  *
  #  * @param allow
  #  *            if true accept invalid person identity strings.
  #  * @return {@code this}.
  #  * @since 4.0
  #  */
  # public ObjectChecker setAllowInvalidPersonIdent(boolean allow) {
  # 	allowInvalidPersonIdent = allow;
  # 	return this;
  # }
  #
  # /**
  #  * Restrict trees to only names legal on Windows platforms.
  #  * <p>
  #  * Also rejects any mixed case forms of reserved names ({@code .git}).
  #  *
  #  * @param win true if Windows name checking should be performed.
  #  * @return {@code this}.
  #  * @since 3.4
  #  */
  # public ObjectChecker setSafeForWindows(boolean win) {
  # 	windows = win;
  # 	return this;
  # }
  #
  # /**
  #  * Restrict trees to only names legal on Mac OS X platforms.
  #  * <p>
  #  * Rejects any mixed case forms of reserved names ({@code .git})
  #  * for users working on HFS+ in case-insensitive (default) mode.
  #  *
  #  * @param mac true if Mac OS X name checking should be performed.
  #  * @return {@code this}.
  #  * @since 3.4
  #  */
  # public ObjectChecker setSafeForMacOS(boolean mac) {
  # 	macosx = mac;
  # 	return this;
  # }

  @doc ~S"""
  Check an object for parsing errors.

  `type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.

  `data` is the raw data which comprises the object. This should be in the
  canonical format (that is the format used to generate the `object_id` of
  the object).

  Raises `Xgit.Errors.CorruptObjectError` if an error is identified.
  """
  def check(%__MODULE__{} = checker, obj_type, data)
      when is_integer(obj_type) and is_list(data),
      do: check(checker, id_for(checker, obj_type, data), obj_type, data)

  @doc ~S"""
  Check an object for parsing errors.

  Like `check/3` but `id` has already been calculated.
  def
  """
  def check(checker, id, obj_type, data)

  # def check(%ObjectChecker{} = checker, id, obj_type, data) when is_binary(id) is_integer(obj_type) and is_list(data) do
  # switch (objType) {
  # case OBJ_COMMIT:
  # 	checkCommit(id, raw);
  # 	break;
  # case OBJ_TAG:
  # 	checkTag(id, raw);
  # 	break;
  # case OBJ_TREE:
  # 	checkTree(id, raw);
  # 	break;

  def check(%__MODULE__{strategy: nil} = _checker, _id, 3, _data), do: :ok

  def check(%__MODULE__{strategy: strategy} = _checker, _id, 3, blob_data) do
    # ^^ type 3 == Constants.obj_blob()

    Strategy.check_blob!(strategy, blob_data)

    # BlobObjectChecker checker = newBlobObjectChecker();
    # if (checker == null) {
    # 	checkBlob(raw);
    # } else {
    # 	checker.update(raw, 0, raw.length);
    # 	checker.endBlob(id);
    # }
  end

  def check(%__MODULE__{} = checker, id, obj_type, _data),
    do: report(checker, ErrorType.UNKNOWN_TYPE, id, "invalid type #{obj_type}")

  # private boolean checkId(byte[] raw) {
  # 	int p = bufPtr.value;
  # 	try {
  # 		tempId.fromString(raw, p);
  # 	} catch (IllegalArgumentException e) {
  # 		bufPtr.value = nextLF(raw, p);
  # 		return false;
  # 	}
  #
  # 	p += OBJECT_ID_STRING_LENGTH;
  # 	if (raw[p] == '\n') {
  # 		bufPtr.value = p + 1;
  # 		return true;
  # 	}
  # 	bufPtr.value = nextLF(raw, p);
  # 	return false;
  # }
  #
  # private void checkPersonIdent(byte[] raw, @Nullable AnyObjectId id)
  # 		throws CorruptObjectException {
  # 	if (allowInvalidPersonIdent) {
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  #
  # 	final int emailB = nextLF(raw, bufPtr.value, '<');
  # 	if (emailB == bufPtr.value || raw[emailB - 1] != '<') {
  # 		report(MISSING_EMAIL, id, JGitText.get().corruptObjectMissingEmail);
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  #
  # 	final int emailE = nextLF(raw, emailB, '>');
  # 	if (emailE == emailB || raw[emailE - 1] != '>') {
  # 		report(BAD_EMAIL, id, JGitText.get().corruptObjectBadEmail);
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  # 	if (emailE == raw.length || raw[emailE] != ' ') {
  # 		report(MISSING_SPACE_BEFORE_DATE, id,
  # 				JGitText.get().corruptObjectBadDate);
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  #
  # 	parseBase10(raw, emailE + 1, bufPtr); // when
  # 	if (emailE + 1 == bufPtr.value || bufPtr.value == raw.length
  # 			|| raw[bufPtr.value] != ' ') {
  # 		report(BAD_DATE, id, JGitText.get().corruptObjectBadDate);
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  #
  # 	int p = bufPtr.value + 1;
  # 	parseBase10(raw, p, bufPtr); // tz offset
  # 	if (p == bufPtr.value) {
  # 		report(BAD_TIMEZONE, id, JGitText.get().corruptObjectBadTimezone);
  # 		bufPtr.value = nextLF(raw, bufPtr.value);
  # 		return;
  # 	}
  #
  # 	p = bufPtr.value;
  # 	if (raw[p] == '\n') {
  # 		bufPtr.value = p + 1;
  # 	} else {
  # 		report(BAD_TIMEZONE, id, JGitText.get().corruptObjectBadTimezone);
  # 		bufPtr.value = nextLF(raw, p);
  # 	}
  # }
  #
  # /**
  #  * Check a commit for errors.
  #  *
  #  * @param raw
  #  *            the commit data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  */
  # public void checkCommit(byte[] raw) throws CorruptObjectException {
  #   NOTE: Remember to check strategy.
  # 	checkCommit(idFor(OBJ_COMMIT, raw), raw);
  # }
  #
  # /**
  #  * Check a commit for errors.
  #  *
  #  * @param id
  #  *            identity of the object being checked.
  #  * @param raw
  #  *            the commit data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  * @since 4.2
  #  */
  # public void checkCommit(@Nullable AnyObjectId id, byte[] raw)
  # 		throws CorruptObjectException {
  #   NOTE: Remember to check strategy.
  # 	bufPtr.value = 0;
  #
  # 	if (!match(raw, tree)) {
  # 		report(MISSING_TREE, id, JGitText.get().corruptObjectNotreeHeader);
  # 	} else if (!checkId(raw)) {
  # 		report(BAD_TREE_SHA1, id, JGitText.get().corruptObjectInvalidTree);
  # 	}
  #
  # 	while (match(raw, parent)) {
  # 		if (!checkId(raw)) {
  # 			report(BAD_PARENT_SHA1, id,
  # 					JGitText.get().corruptObjectInvalidParent);
  # 		}
  # 	}
  #
  # 	if (match(raw, author)) {
  # 		checkPersonIdent(raw, id);
  # 	} else {
  # 		report(MISSING_AUTHOR, id, JGitText.get().corruptObjectNoAuthor);
  # 	}
  #
  # 	if (match(raw, committer)) {
  # 		checkPersonIdent(raw, id);
  # 	} else {
  # 		report(MISSING_COMMITTER, id,
  # 				JGitText.get().corruptObjectNoCommitter);
  # 	}
  # }
  #
  # /**
  #  * Check an annotated tag for errors.
  #  *
  #  * @param raw
  #  *            the tag data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  */
  # public void checkTag(byte[] raw) throws CorruptObjectException {
  # 	checkTag(idFor(OBJ_TAG, raw), raw);
  # }
  #
  # /**
  #  * Check an annotated tag for errors.
  #  *
  #  * @param id
  #  *            identity of the object being checked.
  #  * @param raw
  #  *            the tag data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  * @since 4.2
  #  */
  # public void checkTag(@Nullable AnyObjectId id, byte[] raw)
  # 		throws CorruptObjectException {
  # 	bufPtr.value = 0;
  # 	if (!match(raw, object)) {
  # 		report(MISSING_OBJECT, id,
  # 				JGitText.get().corruptObjectNoObjectHeader);
  # 	} else if (!checkId(raw)) {
  # 		report(BAD_OBJECT_SHA1, id,
  # 				JGitText.get().corruptObjectInvalidObject);
  # 	}
  #
  # 	if (!match(raw, type)) {
  # 		report(MISSING_TYPE_ENTRY, id,
  # 				JGitText.get().corruptObjectNoTypeHeader);
  # 	}
  # 	bufPtr.value = nextLF(raw, bufPtr.value);
  #
  # 	if (!match(raw, tag)) {
  # 		report(MISSING_TAG_ENTRY, id,
  # 				JGitText.get().corruptObjectNoTagHeader);
  # 	}
  # 	bufPtr.value = nextLF(raw, bufPtr.value);
  #
  # 	if (match(raw, tagger)) {
  # 		checkPersonIdent(raw, id);
  # 	}
  # }
  #
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
  #
  # /**
  #  * Check a canonical formatted tree for errors.
  #  *
  #  * @param raw
  #  *            the raw tree data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  */
  # public void checkTree(byte[] raw) throws CorruptObjectException {
  # 	checkTree(idFor(OBJ_TREE, raw), raw);
  # }
  #
  # /**
  #  * Check a canonical formatted tree for errors.
  #  *
  #  * @param id
  #  *            identity of the object being checked.
  #  * @param raw
  #  *            the raw tree data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  * @since 4.2
  #  */
  # public void checkTree(@Nullable AnyObjectId id, byte[] raw)
  # 		throws CorruptObjectException {
  # 	final int sz = raw.length;
  # 	int ptr = 0;
  # 	int lastNameB = 0, lastNameE = 0, lastMode = 0;
  # 	Set<String> normalized = windows || macosx
  # 			? new HashSet<>()
  # 			: null;
  #
  # 	while (ptr < sz) {
  # 		int thisMode = 0;
  # 		for (;;) {
  # 			if (ptr == sz) {
  # 				throw new CorruptObjectException(
  # 						JGitText.get().corruptObjectTruncatedInMode);
  # 			}
  # 			final byte c = raw[ptr++];
  # 			if (' ' == c)
  # 				break;
  # 			if (c < '0' || c > '7') {
  # 				throw new CorruptObjectException(
  # 						JGitText.get().corruptObjectInvalidModeChar);
  # 			}
  # 			if (thisMode == 0 && c == '0') {
  # 				report(ZERO_PADDED_FILEMODE, id,
  # 						JGitText.get().corruptObjectInvalidModeStartsZero);
  # 			}
  # 			thisMode <<= 3;
  # 			thisMode += c - '0';
  # 		}
  #
  # 		if (FileMode.fromBits(thisMode).getObjectType() == OBJ_BAD) {
  # 			throw new CorruptObjectException(MessageFormat.format(
  # 					JGitText.get().corruptObjectInvalidMode2,
  # 					Integer.valueOf(thisMode)));
  # 		}
  #
  # 		final int thisNameB = ptr;
  # 		ptr = scanPathSegment(raw, ptr, sz, id);
  # 		if (ptr == sz || raw[ptr] != 0) {
  # 			throw new CorruptObjectException(
  # 					JGitText.get().corruptObjectTruncatedInName);
  # 		}
  # 		checkPathSegment2(raw, thisNameB, ptr, id);
  # 		if (normalized != null) {
  # 			if (!normalized.add(normalize(raw, thisNameB, ptr))) {
  # 				report(DUPLICATE_ENTRIES, id,
  # 						JGitText.get().corruptObjectDuplicateEntryNames);
  # 			}
  # 		} else if (duplicateName(raw, thisNameB, ptr)) {
  # 			report(DUPLICATE_ENTRIES, id,
  # 					JGitText.get().corruptObjectDuplicateEntryNames);
  # 		}
  #
  # 		if (lastNameB != 0) {
  # 			int cmp = compare(
  # 					raw, lastNameB, lastNameE, lastMode,
  # 					raw, thisNameB, ptr, thisMode);
  # 			if (cmp > 0) {
  # 				report(TREE_NOT_SORTED, id,
  # 						JGitText.get().corruptObjectIncorrectSorting);
  # 			}
  # 		}
  #
  # 		lastNameB = thisNameB;
  # 		lastNameE = ptr;
  # 		lastMode = thisMode;
  #
  # 		ptr += 1 + OBJECT_ID_LENGTH;
  # 		if (ptr > sz) {
  # 			throw new CorruptObjectException(
  # 					JGitText.get().corruptObjectTruncatedInObjectId);
  # 		}
  #
  # 		if (ObjectId.zeroId().compareTo(raw, ptr - OBJECT_ID_LENGTH) == 0) {
  # 			report(NULL_SHA1, id, JGitText.get().corruptObjectZeroId);
  # 		}
  #
  # 		if (id != null && isGitmodules(raw, lastNameB, lastNameE, id)) {
  # 			ObjectId blob = ObjectId.fromRaw(raw, ptr - OBJECT_ID_LENGTH);
  # 			gitsubmodules.add(new GitmoduleEntry(id, blob));
  # 		}
  # 	}
  # }
  #
  # private int scanPathSegment(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	for (; ptr < end; ptr++) {
  # 		byte c = raw[ptr];
  # 		if (c == 0) {
  # 			return ptr;
  # 		}
  # 		if (c == '/') {
  # 			report(FULL_PATHNAME, id,
  # 					JGitText.get().corruptObjectNameContainsSlash);
  # 		}
  # 		if (windows && isInvalidOnWindows(c)) {
  # 			if (c > 31) {
  # 				throw new CorruptObjectException(String.format(
  # 						JGitText.get().corruptObjectNameContainsChar,
  # 						Byte.valueOf(c)));
  # 			}
  # 			throw new CorruptObjectException(String.format(
  # 					JGitText.get().corruptObjectNameContainsByte,
  # 					Integer.valueOf(c & 0xff)));
  # 		}
  # 	}
  # 	return ptr;
  # }

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
  #
  # private void checkPathSegment2(byte[] raw, int ptr, int end,
  # 		@Nullable AnyObjectId id) throws CorruptObjectException {
  # 	if (ptr == end) {
  # 		report(EMPTY_NAME, id, JGitText.get().corruptObjectNameZeroLength);
  # 		return;
  # 	}
  #
  # 	if (raw[ptr] == '.') {
  # 		switch (end - ptr) {
  # 		case 1:
  # 			report(HAS_DOT, id, JGitText.get().corruptObjectNameDot);
  # 			break;
  # 		case 2:
  # 			if (raw[ptr + 1] == '.') {
  # 				report(HAS_DOTDOT, id,
  # 						JGitText.get().corruptObjectNameDotDot);
  # 			}
  # 			break;
  # 		case 4:
  # 			if (isGit(raw, ptr + 1)) {
  # 				report(HAS_DOTGIT, id, String.format(
  # 						JGitText.get().corruptObjectInvalidName,
  # 						RawParseUtils.decode(raw, ptr, end)));
  # 			}
  # 			break;
  # 		default:
  # 			if (end - ptr > 4 && isNormalizedGit(raw, ptr + 1, end)) {
  # 				report(HAS_DOTGIT, id, String.format(
  # 						JGitText.get().corruptObjectInvalidName,
  # 						RawParseUtils.decode(raw, ptr, end)));
  # 			}
  # 		}
  # 	} else if (isGitTilde1(raw, ptr, end)) {
  # 		report(HAS_DOTGIT, id, String.format(
  # 				JGitText.get().corruptObjectInvalidName,
  # 				RawParseUtils.decode(raw, ptr, end)));
  # 	}
  # 	if (macosx && isMacHFSGit(raw, ptr, end, id)) {
  # 		report(HAS_DOTGIT, id, String.format(
  # 				JGitText.get().corruptObjectInvalidNameIgnorableUnicode,
  # 				RawParseUtils.decode(raw, ptr, end)));
  # 	}
  #
  # 	if (windows) {
  # 		// Windows ignores space and dot at end of file name.
  # 		if (raw[end - 1] == ' ' || raw[end - 1] == '.') {
  # 			report(WIN32_BAD_NAME, id, String.format(
  # 					JGitText.get().corruptObjectInvalidNameEnd,
  # 					Character.valueOf(((char) raw[end - 1]))));
  # 		}
  # 		if (end - ptr >= 3) {
  # 			checkNotWindowsDevice(raw, ptr, end, id);
  # 		}
  # 	}
  # }
  #
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
  #
  # private static boolean isInvalidOnWindows(byte c) {
  # 	// Windows disallows "special" characters in a path component.
  # 	switch (c) {
  # 	case '"':
  # 	case '*':
  # 	case ':':
  # 	case '<':
  # 	case '>':
  # 	case '?':
  # 	case '\\':
  # 	case '|':
  # 		return true;
  # 	}
  # 	return 1 <= c && c <= 31;
  # }
  #
  # private static boolean isGit(byte[] buf, int p) {
  # 	return toLower(buf[p]) == 'g'
  # 			&& toLower(buf[p + 1]) == 'i'
  # 			&& toLower(buf[p + 2]) == 't';
  # }
  #
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
  #
  # private static boolean isNormalizedGit(byte[] raw, int ptr, int end) {
  # 	if (isGit(raw, ptr)) {
  # 		int dots = 0;
  # 		boolean space = false;
  # 		int p = end - 1;
  # 		for (; (ptr + 2) < p; p--) {
  # 			if (raw[p] == '.')
  # 				dots++;
  # 			else if (raw[p] == ' ')
  # 				space = true;
  # 			else
  # 				break;
  # 		}
  # 		return p == ptr + 2 && (dots == 1 || space);
  # 	}
  # 	return false;
  # }
  #
  # private boolean match(byte[] b, byte[] src) {
  # 	int r = RawParseUtils.match(b, bufPtr.value, src);
  # 	if (r < 0) {
  # 		return false;
  # 	}
  # 	bufPtr.value = r;
  # 	return true;
  # }
  #
  # private static char toLower(byte b) {
  # 	if ('A' <= b && b <= 'Z')
  # 		return (char) (b + ('a' - 'A'));
  # 	return (char) b;
  # }
  #
  # private static boolean isPositiveDigit(byte b) {
  # 	return '1' <= b && b <= '9';
  # }
  #
  # /**
  #  * Create a new {@link org.eclipse.jgit.lib.BlobObjectChecker}.
  #  *
  #  * @return new BlobObjectChecker or null if it's not provided.
  #  * @since 4.9
  #  */
  # @Nullable
  # public BlobObjectChecker newBlobObjectChecker() {
  #   NOTE: Remember to check strategy.
  # 	return null;
  # }
  #
  # /**
  #  * Check a blob for errors.
  #  *
  #  * <p>
  #  * This may not be called from PackParser in some cases. Use
  #  * {@link #newBlobObjectChecker} instead.
  #  *
  #  * @param raw
  #  *            the blob data. The array is never modified.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             if any error was detected.
  #  */
  # public void checkBlob(byte[] raw) throws CorruptObjectException {
  #   NOTE: Remember to check strategy.
  # 	// We can always assume the blob is valid.
  # }
  #
  # private String normalize(byte[] raw, int ptr, int end) {
  # 	String n = RawParseUtils.decode(raw, ptr, end).toLowerCase(Locale.US);
  # 	return macosx ? Normalizer.normalize(n, Normalizer.Form.NFC) : n;
  # }
  #
  # /**
  #  * Get the list of ".gitmodules" files found in the pack. For each, report
  #  * its blob id (e.g. to validate its contents) and the tree where it was
  #  * found (e.g. to check if it is in the root)
  #  *
  #  * @return List of pairs of ids {@literal <tree, blob>}.
  #  *
  #  * @since 4.7.5
  #  */
  # public List<GitmoduleEntry> getGitsubmodules() {
  # 	return gitsubmodules;
  # }
  #
  # /**
  #  * Reset the invocation-specific state from this instance. Specifically this
  #  * clears the list of .gitmodules files encountered (see
  #  * {@link #getGitsubmodules()})
  #  *
  #  * Configurations like errors to filter, skip lists or the specified O.S.
  #  * (set via {@link #setSafeForMacOS(boolean)} or
  #  * {@link #setSafeForWindows(boolean)}) are NOT cleared.
  #  *
  #  * @since 5.2
  #  */
  # public void reset() {
  # 	gitsubmodules.clear();
  # }
end
