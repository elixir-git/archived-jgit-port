# Copyright (C) 2008-2009, Google Inc.
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2010, Matthias Sohn <matthias.sohn@sap.com>
# Copyright (C) 2010, Christian Halstrick <christian.halstrick@sap.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/dircache/DirCacheEntry.java
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

defmodule Xgit.DirCache.DirCacheEntry do
  @moduledoc ~S"""
  A single file (or stage of a file) in a `DirCache`.

  An entry represents exactly one stage of a file. If a file path is unmerged
  then multiple `DirCacheEntry` instances may appear for the same path name.

  Struct members:
  * `info`: (binary, not UTF-8 encoded) header information
  * `info_offset`: (integer) byte offset within `info` where our header starts.
  * `path`: (charlist) our encoded path name, from the root of the repository.
  * `in_core_flags`: (integer, bit flags) flags which are never stored to disk.
  """

  @enforce_keys [:info, :info_offset, :path, :in_core_flags]
  defstruct [:path, :in_core_flags, info: '', info_offset: 0]

  use Bitwise

  alias Xgit.Errors.InvalidPathError
  alias Xgit.Lib.FileMode
  alias Xgit.Lib.ObjectChecker
  alias Xgit.Util.NB

  # The following are offsets into the `info` binary for various fields:
  @p_ctime 0
  # 32-bit integer (seconds since Unix epoch)
  # @p_ctime_ns 4 (nanoseconds since @ctime)

  # private static final int P_MTIME = 8;
  #
  # // private static final int P_MTIME_NSEC = 12;
  #
  # // private static final int P_DEV = 16;
  #
  # // private static final int P_INO = 20;

  @p_mode 24
  # 32-bit integer (file mode)

  # // private static final int P_UID = 28;
  #
  # // private static final int P_GID = 32;
  #
  # private static final int P_SIZE = 36;
  #
  # private static final int P_OBJECTID = 40;

  @p_flags 60
  # 16-bit integer flags | name length

  # private static final int P_FLAGS2 = 62;

  # Mask applied to data in `p_flags` to get the name length.
  @name_mask 0xFFF

  # private static final int INTENT_TO_ADD = 0x20000000;
  # private static final int SKIP_WORKTREE = 0x40000000;
  # private static final int EXTENDED_FLAGS = (INTENT_TO_ADD | SKIP_WORKTREE);
  #
  # private static final int INFO_LEN = 62;
  # private static final int INFO_LEN_EXTENDED = 64;
  #
  # private static final int EXTENDED = 0x40;
  @assume_valid 0x80

  # /** In-core flag signaling that the entry should be considered as modified. */
  # private static final int UPDATE_NEEDED = 0x1;

  # DirCacheEntry(final byte[] sharedInfo, final MutableInteger infoAt,
  #     final InputStream in, final MessageDigest md, final int smudge_s,
  #     final int smudge_ns) throws IOException {
  #   info = sharedInfo;
  #   infoOffset = infoAt.value;
  #
  #   IO.readFully(in, info, infoOffset, INFO_LEN);
  #
  #   final int len;
  #   if (isExtended()) {
  #     len = INFO_LEN_EXTENDED;
  #     IO.readFully(in, info, infoOffset + INFO_LEN, INFO_LEN_EXTENDED - INFO_LEN);
  #
  #     if ((getExtendedFlags() & ~EXTENDED_FLAGS) != 0)
  #       throw new IOException(MessageFormat.format(JGitText.get()
  #           .DIRCUnrecognizedExtendedFlags, String.valueOf(getExtendedFlags())));
  #   } else
  #     len = INFO_LEN;
  #
  #   infoAt.value += len;
  #   md.update(info, infoOffset, len);
  #
  #   int pathLen = NB.decodeUInt16(info, infoOffset + P_FLAGS) & NAME_MASK;
  #   int skipped = 0;
  #   if (pathLen < NAME_MASK) {
  #     path = new byte[pathLen];
  #     IO.readFully(in, path, 0, pathLen);
  #     md.update(path, 0, pathLen);
  #   } else {
  #     final ByteArrayOutputStream tmp = new ByteArrayOutputStream();
  #     {
  #       final byte[] buf = new byte[NAME_MASK];
  #       IO.readFully(in, buf, 0, NAME_MASK);
  #       tmp.write(buf);
  #     }
  #     for (;;) {
  #       final int c = in.read();
  #       if (c < 0)
  #         throw new EOFException(JGitText.get().shortReadOfBlock);
  #       if (c == 0)
  #         break;
  #       tmp.write(c);
  #     }
  #     path = tmp.toByteArray();
  #     pathLen = path.length;
  #     skipped = 1; // we already skipped 1 '\0' above to break the loop.
  #     md.update(path, 0, pathLen);
  #     md.update((byte) 0);
  #   }
  #
  #   try {
  #     checkPath(path);
  #   } catch (InvalidPathException e) {
  #     CorruptObjectException p =
  #       new CorruptObjectException(e.getMessage());
  #     if (e.getCause() != null)
  #       p.initCause(e.getCause());
  #     throw p;
  #   }
  #
  #   // Index records are padded out to the next 8 byte alignment
  #   // for historical reasons related to how C Git read the files.
  #   //
  #   final int actLen = len + pathLen;
  #   final int expLen = (actLen + 8) & ~7;
  #   final int padLen = expLen - actLen - skipped;
  #   if (padLen > 0) {
  #     IO.skipFully(in, padLen);
  #     md.update(nullpad, 0, padLen);
  #   }
  #
  #   if (mightBeRacilyClean(smudge_s, smudge_ns))
  #     smudgeRacilyClean();
  # }

  @doc ~S"""
  Create an empty entry at the specified stage.

  `path` is the name of the cache entry. It may be either a String or a byte list.

  `stage` is the stage index of the new entry (must be an integer in the range 0..3, default 0).

  Raises `ArgumentError` if the path starts or ends with `"/"`, or contains `"//"`
  or `"\0"`. These sequences are not permitted in a git tree object or `DirCache` file.
  """
  def new(path, stage \\ 0)

  def new(path, stage)
      when is_binary(path) and is_integer(stage) and stage >= 0 and stage <= 3,
      do: new(:binary.bin_to_list(path), stage)

  def new(path, stage)
      when is_list(path) and is_integer(stage) and stage >= 0 and stage <= 3 do
    check_path(path)

    info =
      stage
      |> shift_left12()
      |> add_path_length(path)
      |> NB.encode_int16()
      |> prepend(List.duplicate(0, @p_flags))
      |> :binary.list_to_bin()

    %__MODULE__{info: info, info_offset: 0, path: path, in_core_flags: 0}
  end

  defp shift_left12(n), do: n <<< 12

  defp add_path_length(n, path) when length(path) >= @name_mask, do: n + @name_mask
  defp add_path_length(n, path), do: n + length(path)

  defp prepend(l1, l2), do: Enum.concat(l2, l1)

  # void write(OutputStream os) throws IOException {
  #   final int len = isExtended() ? INFO_LEN_EXTENDED : INFO_LEN;
  #   final int pathLen = path.length;
  #   os.write(info, infoOffset, len);
  #   os.write(path, 0, pathLen);
  #
  #   // Index records are padded out to the next 8 byte alignment
  #   // for historical reasons related to how C Git read the files.
  #   //
  #   final int actLen = len + pathLen;
  #   final int expLen = (actLen + 8) & ~7;
  #   if (actLen != expLen)
  #     os.write(nullpad, 0, expLen - actLen);
  # }
  #
  # /**
  #  * Is it possible for this entry to be accidentally assumed clean?
  #  * <p>
  #  * The "racy git" problem happens when a work file can be updated faster
  #  * than the filesystem records file modification timestamps. It is possible
  #  * for an application to edit a work file, update the index, then edit it
  #  * again before the filesystem will give the work file a new modification
  #  * timestamp. This method tests to see if file was written out at the same
  #  * time as the index.
  #  *
  #  * @param smudge_s
  #  *            seconds component of the index's last modified time.
  #  * @param smudge_ns
  #  *            nanoseconds component of the index's last modified time.
  #  * @return true if extra careful checks should be used.
  #  */
  # public final boolean mightBeRacilyClean(int smudge_s, int smudge_ns) {
  #   // If the index has a modification time then it came from disk
  #   // and was not generated from scratch in memory. In such cases
  #   // the entry is 'racily clean' if the entry's cached modification
  #   // time is equal to or later than the index modification time. In
  #   // such cases the work file is too close to the index to tell if
  #   // it is clean or not based on the modification time alone.
  #   //
  #   final int base = infoOffset + P_MTIME;
  #   final int mtime = NB.decodeInt32(info, base);
  #   if (smudge_s == mtime)
  #     return smudge_ns <= NB.decodeInt32(info, base + 4);
  #   return false;
  # }
  #
  # /**
  #  * Force this entry to no longer match its working tree file.
  #  * <p>
  #  * This avoids the "racy git" problem by making this index entry no longer
  #  * match the file in the working directory. Later git will be forced to
  #  * compare the file content to ensure the file matches the working tree.
  #  */
  # public final void smudgeRacilyClean() {
  #   // To mark an entry racily clean we set its length to 0 (like native git
  #   // does). Entries which are not racily clean and have zero length can be
  #   // distinguished from racily clean entries by checking P_OBJECTID
  #   // against the SHA1 of empty content. When length is 0 and P_OBJECTID is
  #   // different from SHA1 of empty content we know the entry is marked
  #   // racily clean
  #   final int base = infoOffset + P_SIZE;
  #   Arrays.fill(info, base, base + 4, (byte) 0);
  # }
  #
  # /**
  #  * Check whether this entry has been smudged or not
  #  * <p>
  #  * If a blob has length 0 we know its id, see
  #  * {@link org.eclipse.jgit.lib.Constants#EMPTY_BLOB_ID}. If an entry has
  #  * length 0 and an ID different from the one for empty blob we know this
  #  * entry was smudged.
  #  *
  #  * @return <code>true</code> if the entry is smudged, <code>false</code>
  #  *         otherwise
  #  */
  # public final boolean isSmudged() {
  #   final int base = infoOffset + P_OBJECTID;
  #   return (getLength() == 0) && (Constants.EMPTY_BLOB_ID.compareTo(info, base) != 0);
  # }
  #
  # final byte[] idBuffer() {
  #   return info;
  # }
  #
  # final int idOffset() {
  #   return infoOffset + P_OBJECTID;
  # }

  @doc ~S"""
  Is this entry always thought to be unmodified?

  Most entries in the index do not have this flag set. Users may however enable
  this flag if the file system `stat()` costs are too high on this working
  directory, such as on NFS or SMB volumes.
  """
  def assume_valid?(%__MODULE__{} = entry) do
    entry
    |> flags_byte()
    |> boolean_from_flag(@assume_valid)
  end

  defp flags_byte(%__MODULE__{info: info, info_offset: info_offset}),
    do: :binary.at(info, info_offset + @p_flags)

  defp boolean_from_flag(flags_byte, mask), do: (flags_byte &&& mask) != 0

  @doc ~S"""
  Return a new entry, replacing the assume-valid flag from this entry.

  `assume?` should be `true` to ignore apparent modifications or `false` to
  look at last modified to detect file modifications.
  """
  def set_assume_valid(%__MODULE__{info: info, info_offset: info_offset} = entry, assume?)
      when is_boolean(assume?) do
    new_flags_byte =
      entry
      |> flags_byte()
      |> set_assume_valid_bit(assume?)

    %{
      entry
      | info: replace_info_bytes(info, info_offset + @p_flags, [new_flags_byte])
    }
  end

  defp set_assume_valid_bit(flags_byte, true), do: flags_byte ||| @assume_valid
  defp set_assume_valid_bit(flags_byte, false), do: flags_byte &&& ~~~@assume_valid

  # /**
  #  * Whether this entry should be checked for changes
  #  *
  #  * @return {@code true} if this entry should be checked for changes
  #  */
  # public boolean isUpdateNeeded() {
  #   return (inCoreFlags & UPDATE_NEEDED) != 0;
  # }
  #
  # /**
  #  * Set whether this entry must be checked for changes
  #  *
  #  * @param updateNeeded
  #  *            whether this entry must be checked for changes
  #  */
  # public void setUpdateNeeded(boolean updateNeeded) {
  #   if (updateNeeded)
  #     inCoreFlags |= UPDATE_NEEDED;
  #   else
  #     inCoreFlags &= ~UPDATE_NEEDED;
  # }

  @doc ~S"""
  Get the stage of this entry.

  This will be an integer in the range 0..3.
  """
  def stage(%__MODULE__{} = entry) do
    entry
    |> flags_byte()
    |> stage_from_flags_byte()
  end

  defp stage_from_flags_byte(b), do: b >>> 4 &&& 0x3

  # /**
  #  * Returns whether this entry should be skipped from the working tree.
  #  *
  #  * @return true if this entry should be skipepd.
  #  */
  # public boolean isSkipWorkTree() {
  #   return (getExtendedFlags() & SKIP_WORKTREE) != 0;
  # }
  #
  # /**
  #  * Returns whether this entry is intent to be added to the Index.
  #  *
  #  * @return true if this entry is intent to add.
  #  */
  # public boolean isIntentToAdd() {
  #   return (getExtendedFlags() & INTENT_TO_ADD) != 0;
  # }
  #
  # /**
  #  * Returns whether this entry is in the fully-merged stage (0).
  #  *
  #  * @return true if this entry is merged
  #  * @since 2.2
  #  */
  # public boolean isMerged() {
  #   return getStage() == STAGE_0;
  # }

  @doc ~S"""
  Obtain the raw `FileMode` bits for this entry.
  """
  def raw_file_mode_bits(%__MODULE__{info: info, info_offset: info_offset}) do
    info
    |> :binary.bin_to_list(info_offset + @p_mode, 4)
    |> NB.decode_int32()
    |> elem(0)
  end

  @doc ~S"""
  Obtain the `FileMode` for this entry.
  """
  def file_mode(%__MODULE__{} = entry) do
    entry
    |> raw_file_mode_bits()
    |> FileMode.from_bits()
  end

  @type_tree FileMode.type_tree()
  @type_missing FileMode.type_missing()

  @doc ~S"""
  Return a new entry, replacing the file mode setting from this entry.

  Will raise `ArgumentError` if `mode` represents "missing", "tree", or any
  other code that is not permitted in a tree object.
  """
  def set_file_mode(%__MODULE__{} = entry, %FileMode{mode_bits: mode_bits} = mode) do
    unless valid_file_mode?(mode_bits &&& FileMode.type_mask()) do
      raise ArgumentError, "Invalid mode #{inspect(mode)} for path #{path(entry)}"
    end

    set_raw_file_mode(entry, mode_bits)
  end

  defp valid_file_mode?(@type_tree), do: false
  defp valid_file_mode?(@type_missing), do: false
  defp valid_file_mode?(_), do: true

  defp set_raw_file_mode(%__MODULE__{info: info, info_offset: info_offset} = entry, mode_bits),
    do: %{
      entry
      | info: replace_info_bytes(info, info_offset + @p_mode, NB.encode_int32(mode_bits))
    }

  defp replace_info_bytes(info, offset, new_bytes)
       when is_binary(info) and is_integer(offset) and is_list(new_bytes) do
    replace_length = length(new_bytes)

    prefix = :binary.part(info, 0, offset)

    suffix =
      :binary.part(info, offset + replace_length, byte_size(info) - (offset + replace_length))

    :erlang.iolist_to_binary([prefix, new_bytes, suffix])
  end

  @doc ~S"""
  Get the cached creation time of this file.

  The timestamp is interpreted as milliseconds since the Unix/Java epoch
  (midnight Jan 1, 1970 UTC).
  """
  def creation_time(%__MODULE__{} = entry), do: decode_ts(entry, @p_ctime)

  @doc ~S"""
  Return a new entry, replacing the cached creation time from this entry.

  The timestamp must be expressed as milliseconds since the Unix/Java epoch
  (midnight Jan 1, 1970 UTC).
  """
  def set_creation_time(%__MODULE__{} = entry, new_ts) when is_integer(new_ts),
    do: entry_with_new_ts(entry, @p_ctime, new_ts)

  # /**
  #  * Get the cached last modification date of this file, in milliseconds.
  #  * <p>
  #  * One of the indicators that the file has been modified by an application
  #  * changing the working tree is if the last modification time for the file
  #  * differs from the time stored in this entry.
  #  *
  #  * @return last modification time of this file, in milliseconds since the
  #  *         Java epoch (midnight Jan 1, 1970 UTC).
  #  */
  # public long getLastModified() {
  #   return decodeTS(P_MTIME);
  # }
  #
  # /**
  #  * Set the cached last modification date of this file, using milliseconds.
  #  *
  #  * @param when
  #  *            new cached modification date of the file, in milliseconds.
  #  */
  # public void setLastModified(long when) {
  #   encodeTS(P_MTIME, when);
  # }
  #
  # /**
  #  * Get the cached size (mod 4 GB) (in bytes) of this file.
  #  * <p>
  #  * One of the indicators that the file has been modified by an application
  #  * changing the working tree is if the size of the file (in bytes) differs
  #  * from the size stored in this entry.
  #  * <p>
  #  * Note that this is the length of the file in the working directory, which
  #  * may differ from the size of the decompressed blob if work tree filters
  #  * are being used, such as LF&lt;-&gt;CRLF conversion.
  #  * <p>
  #  * Note also that for very large files, this is the size of the on-disk file
  #  * truncated to 32 bits, i.e. modulo 4294967296. If that value is larger
  #  * than 2GB, it will appear negative.
  #  *
  #  * @return cached size of the working directory file, in bytes.
  #  */
  # public int getLength() {
  #   return NB.decodeInt32(info, infoOffset + P_SIZE);
  # }
  #
  # /**
  #  * Set the cached size (in bytes) of this file.
  #  *
  #  * @param sz
  #  *            new cached size of the file, as bytes. If the file is larger
  #  *            than 2G, cast it to (int) before calling this method.
  #  */
  # public void setLength(int sz) {
  #   NB.encodeInt32(info, infoOffset + P_SIZE, sz);
  # }
  #
  # /**
  #  * Set the cached size (in bytes) of this file.
  #  *
  #  * @param sz
  #  *            new cached size of the file, as bytes.
  #  */
  # public void setLength(long sz) {
  #   setLength((int) sz);
  # }
  #
  # /**
  #  * Obtain the ObjectId for the entry.
  #  * <p>
  #  * Using this method to compare ObjectId values between entries is
  #  * inefficient as it causes memory allocation.
  #  *
  #  * @return object identifier for the entry.
  #  */
  # public ObjectId getObjectId() {
  #   return ObjectId.fromRaw(idBuffer(), idOffset());
  # }
  #
  # /**
  #  * Set the ObjectId for the entry.
  #  *
  #  * @param id
  #  *            new object identifier for the entry. May be
  #  *            {@link org.eclipse.jgit.lib.ObjectId#zeroId()} to remove the
  #  *            current identifier.
  #  */
  # public void setObjectId(AnyObjectId id) {
  #   id.copyRawTo(idBuffer(), idOffset());
  # }
  #
  # /**
  #  * Set the ObjectId for the entry from the raw binary representation.
  #  *
  #  * @param bs
  #  *            the raw byte buffer to read from. At least 20 bytes after p
  #  *            must be available within this byte array.
  #  * @param p
  #  *            position to read the first byte of data from.
  #  */
  # public void setObjectIdFromRaw(byte[] bs, int p) {
  #   final int n = Constants.OBJECT_ID_LENGTH;
  #   System.arraycopy(bs, p, idBuffer(), idOffset(), n);
  # }

  @doc ~S"""
  Get the entry's complete path.

  This method is not very efficient and is primarily meant for debugging
  and final output generation. Applications should try to avoid calling it,
  and if invoked do so only once per interesting entry, where the name is
  absolutely required for correct function.

  Returns the complete path of the entry, from the root of the repository.
  If the entry is in a subtree there will be at least one '/' in the returned
  string.
  """
  def path(%__MODULE__{path: path}), do: to_string(path)

  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Use for debugging only !
  #  */
  # @SuppressWarnings("nls")
  # @Override
  # public String toString() {
  #   return getFileMode() + " " + getLength() + " " + getLastModified()
  #       + " " + getObjectId() + " " + getStage() + " "
  #       + getPathString() + "\n";
  # }
  #
  # /**
  #  * Copy the ObjectId and other meta fields from an existing entry.
  #  * <p>
  #  * This method copies everything except the path from one entry to another,
  #  * supporting renaming.
  #  *
  #  * @param src
  #  *            the entry to copy ObjectId and meta fields from.
  #  */
  # public void copyMetaData(DirCacheEntry src) {
  #   copyMetaData(src, false);
  # }
  #
  # /**
  #  * Copy the ObjectId and other meta fields from an existing entry.
  #  * <p>
  #  * This method copies everything except the path and possibly stage from one
  #  * entry to another, supporting renaming.
  #  *
  #  * @param src
  #  *            the entry to copy ObjectId and meta fields from.
  #  * @param keepStage
  #  *            if true, the stage attribute will not be copied
  #  */
  # void copyMetaData(DirCacheEntry src, boolean keepStage) {
  #   int origflags = NB.decodeUInt16(info, infoOffset + P_FLAGS);
  #   int newflags = NB.decodeUInt16(src.info, src.infoOffset + P_FLAGS);
  #   System.arraycopy(src.info, src.infoOffset, info, infoOffset, INFO_LEN);
  #   final int pLen = origflags & NAME_MASK;
  #   final int SHIFTED_STAGE_MASK = 0x3 << 12;
  #   final int pStageShifted;
  #   if (keepStage)
  #     pStageShifted = origflags & SHIFTED_STAGE_MASK;
  #   else
  #     pStageShifted = newflags & SHIFTED_STAGE_MASK;
  #   NB.encodeInt16(info, infoOffset + P_FLAGS, pStageShifted | pLen
  #       | (newflags & ~NAME_MASK & ~SHIFTED_STAGE_MASK));
  # }
  #
  # /**
  #  * @return true if the entry contains extended flags.
  #  */
  # boolean isExtended() {
  #   return (info[infoOffset + P_FLAGS] & EXTENDED) != 0;
  # }

  defp decode_ts(%{info: info, info_offset: info_offset}, offset) do
    {sec, ms_to_decode} =
      info
      |> :binary.bin_to_list(info_offset + offset, 8)
      |> NB.decode_int32()

    {ms, _} = NB.decode_int32(ms_to_decode)

    sec * 1000 + div(ms, 1_000_000)
  end

  defp entry_with_new_ts(
         %__MODULE__{info: info, info_offset: info_offset} = entry,
         offset,
         new_ts
       ) do
    sec = NB.encode_int32(div(new_ts, 1000))
    ms = NB.encode_int32(Integer.mod(new_ts, 1000) * 1_000_000)

    %{
      entry
      | info: replace_info_bytes(info, info_offset + offset, [sec ++ ms])
    }
  end

  # private int getExtendedFlags() {
  #   if (isExtended())
  #     return NB.decodeUInt16(info, infoOffset + P_FLAGS2) << 16;
  #   else
  #     return 0;
  # }

  defp check_path(path) do
    try do
      ObjectChecker.check_path!(%ObjectChecker{}, path)
    rescue
      # credo:disable-for-next-line Credo.Check.Warning.RaiseInsideRescue
      _ -> raise InvalidPathError, path: List.to_string(path)
    end
  end

  # static String toString(byte[] path) {
  #   return UTF_8.decode(ByteBuffer.wrap(path)).toString();
  # }
  #
  # static int getMaximumInfoLength(boolean extended) {
  #   return extended ? INFO_LEN_EXTENDED : INFO_LEN;
  # }
end
