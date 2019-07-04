# Copyright (C) 2008-2010, Google Inc.
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# Copyright (C) 2011, Matthias Sohn <matthias.sohn@sap.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/dircache/DirCacheBasicTest.java
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

defmodule Xgit.DirCache do
  @moduledoc ~S"""
  Support for the git dircache (aka index file).

  The index file keeps track of which objects are currently checked out in the
  working directory, and the last modified time of those working files. Changes
  in the working directory can be detected by comparing the modification times
  to the cached modification time within the index file.

  Index files are also used during merges, where the merge happens within the
  index file first, and the working directory is updated as a post-merge step.
  Conflicts are stored in the index file to allow tool (and human) based
  resolutions to be easily performed.
  """

  use GenServer

  # alias Xgit.Errors.IndexReadError
  alias Xgit.Lib.Repository
  # alias Xgit.Storage.File.FileSnapshot
  alias Xgit.Util.GenServerUtils

  # TO DO: Finish porting this module. https://github.com/elixir-git/xgit/issues/164

  # private static final byte[] SIG_DIRC = { 'D', 'I', 'R', 'C' };
  #
  # private static final int EXT_TREE = 0x54524545 /* 'TREE' */;
  #
  # private static final DirCacheEntry[] NO_ENTRIES = {};
  #
  # private static final byte[] NO_CHECKSUM = {};
  #
  # static final Comparator<DirCacheEntry> ENT_CMP = new Comparator<DirCacheEntry>() {
  #   @Override
  #   public int compare(DirCacheEntry o1, DirCacheEntry o2) {
  #     final int cr = cmp(o1, o2);
  #     if (cr != 0)
  #       return cr;
  #     return o1.getStage() - o2.getStage();
  #   }
  # };
  #
  # static int cmp(DirCacheEntry a, DirCacheEntry b) {
  #   return cmp(a.path, a.path.length, b);
  # }
  #
  # static int cmp(byte[] aPath, int aLen, DirCacheEntry b) {
  #   return cmp(aPath, aLen, b.path, b.path.length);
  # }
  #
  # static int cmp(final byte[] aPath, final int aLen, final byte[] bPath,
  #     final int bLen) {
  #   for (int cPos = 0; cPos < aLen && cPos < bLen; cPos++) {
  #     final int cmp = (aPath[cPos] & 0xff) - (bPath[cPos] & 0xff);
  #     if (cmp != 0)
  #       return cmp;
  #   }
  #   return aLen - bLen;
  # }
  #
  # /**
  #  * Create a new empty index which is never stored on disk.
  #  *
  #  * @return an empty cache which has no backing store file. The cache may not
  #  *         be read or written, but it may be queried and updated (in
  #  *         memory).
  #  */
  # public static DirCache newInCore() {
  #   return new DirCache(null, null);
  # }
  #
  # /**
  #  * Create a new in memory index read from the contents of a tree.
  #  *
  #  * @param reader
  #  *            reader to access the tree objects from a repository.
  #  * @param treeId
  #  *            tree to read. Must identify a tree, not a tree-ish.
  #  * @return a new cache which has no backing store file, but contains the
  #  *         contents of {@code treeId}.
  #  * @throws java.io.IOException
  #  *             one or more trees not available from the ObjectReader.
  #  * @since 4.2
  #  */
  # public static DirCache read(ObjectReader reader, AnyObjectId treeId)
  #     throws IOException {
  #   DirCache d = newInCore();
  #   DirCacheBuilder b = d.builder();
  #   b.addTree(null, DirCacheEntry.STAGE_0, reader, treeId);
  #   b.finish();
  #   return d;
  # }

  @doc ~S"""
  Create a new in-core index representation and read an index from disk.

  The new index will be read before it is returned to the caller. Read
  failures are reported as errors and therefore prevent the function from
  returning a partially-populated index.

  ## Parameters

  `repository` is the PID for an `Xgit.Lib.Repository`.

  ## Return Value

  PID for an `Xgit.DirCache` process representing the contents of the specified index
  file (if it exists) or an empty cache if the file does not exist.

  Raises an error if unable to open the index file.
  """
  @spec from_repository!(repository :: pid) :: pid
  def from_repository!(repository) when is_pid(repository) do
    repository
    |> Repository.index_file!()
    |> from_index_file!()

    # |> set_repository(repository)
  end

  @doc ~S"""
  Create a new in-core index representation and read an index from disk.

  The new index will be read before it is returned to the caller. Read
  failures are reported as exceptions and therefore prevent the function from
  returning a partially-populated index.

  ## Parameters

  `path` is the file path for an index file.

  ## Return Value

  PID for an `Xgit.DirCache` process representing the contents of the specified index
  file (if it exists) or an empty cache if the file does not exist.

  Raises an error if unable to open the index file.
  """
  @spec from_index_file!(path :: String.t()) :: pid
  def from_index_file!(path) when is_binary(path) do
    {:ok, pid} = GenServer.start_link(__MODULE__, path)
    read!(pid)
    pid
  end

  # /**
  #  * Create a new in-core index representation, lock it, and read from disk.
  #  * <p>
  #  * The new index will be locked and then read before it is returned to the
  #  * caller. Read failures are reported as exceptions and therefore prevent
  #  * the method from returning a partially populated index. On read failure,
  #  * the lock is released.
  #  *
  #  * @param indexLocation
  #  *            location of the index file on disk.
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  * @return a cache representing the contents of the specified index file (if
  #  *         it exists) or an empty cache if the file does not exist.
  #  * @throws java.io.IOException
  #  *             the index file is present but could not be read, or the lock
  #  *             could not be obtained.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             the index file is using a format or extension that this
  #  *             library does not support.
  #  */
  # public static DirCache lock(File indexLocation, FS fs)
  #     throws CorruptObjectException, IOException {
  #   final DirCache c = new DirCache(indexLocation, fs);
  #   if (!c.lock())
  #     throw new LockFailedException(indexLocation);
  #
  #   try {
  #     c.read();
  #   } catch (IOException | RuntimeException | Error e) {
  #     c.unlock();
  #     throw e;
  #   }
  #
  #   return c;
  # }
  #
  # /**
  #  * Create a new in-core index representation, lock it, and read from disk.
  #  * <p>
  #  * The new index will be locked and then read before it is returned to the
  #  * caller. Read failures are reported as exceptions and therefore prevent
  #  * the method from returning a partially populated index. On read failure,
  #  * the lock is released.
  #  *
  #  * @param repository
  #  *            repository containing the index to lock and read
  #  * @param indexChangedListener
  #  *            listener to be informed when DirCache is committed
  #  * @return a cache representing the contents of the specified index file (if
  #  *         it exists) or an empty cache if the file does not exist.
  #  * @throws java.io.IOException
  #  *             the index file is present but could not be read, or the lock
  #  *             could not be obtained.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             the index file is using a format or extension that this
  #  *             library does not support.
  #  * @since 2.0
  #  */
  # public static DirCache lock(final Repository repository,
  #     final IndexChangedListener indexChangedListener)
  #     throws CorruptObjectException, IOException {
  #   DirCache c = lock(repository.getIndexFile(), repository.getFS(),
  #       indexChangedListener);
  #   c.repository = repository;
  #   return c;
  # }
  #
  # /**
  #  * Create a new in-core index representation, lock it, and read from disk.
  #  * <p>
  #  * The new index will be locked and then read before it is returned to the
  #  * caller. Read failures are reported as exceptions and therefore prevent
  #  * the method from returning a partially populated index. On read failure,
  #  * the lock is released.
  #  *
  #  * @param indexLocation
  #  *            location of the index file on disk.
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  * @param indexChangedListener
  #  *            listener to be informed when DirCache is committed
  #  * @return a cache representing the contents of the specified index file (if
  #  *         it exists) or an empty cache if the file does not exist.
  #  * @throws java.io.IOException
  #  *             the index file is present but could not be read, or the lock
  #  *             could not be obtained.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             the index file is using a format or extension that this
  #  *             library does not support.
  #  */
  # public static DirCache lock(final File indexLocation, final FS fs,
  #     IndexChangedListener indexChangedListener)
  #     throws CorruptObjectException,
  #     IOException {
  #   DirCache c = lock(indexLocation, fs);
  #   c.registerIndexChangedListener(indexChangedListener);
  #   return c;
  # }

  # GenServer state members:
  # `live_file`: (String) Location of the current version of the index file.

  # /** Individual file index entries, sorted by path name. */
  # private DirCacheEntry[] sortedEntries;

  # `entry_count`: (Integer) Number of positions within `sorted_entries` that are valid.

  # /** Cache tree for this index; null if the cache tree is not available. */
  # private DirCacheTree tree;
  #
  # /** Our active lock (if we hold it); null if we don't have it locked. */
  # private LockFile myLock;

  # `snapshot`: (FileSnapshot) Keeps track of whether the index has changed or not

  # /** index checksum when index was read from disk */
  # private byte[] readIndexChecksum;
  #
  # /** index checksum when index was written to disk */
  # private byte[] writeIndexChecksum;
  #
  # /** listener to be informed on commit */
  # private IndexChangedListener indexChangedListener;
  #
  # /** Repository containing this index */
  # private Repository repository;

  @impl GenServer
  def init(index_location) when is_binary(index_location),
    do:
      {:ok,
       %{
         live_file: index_location,
         snapshot: nil,
         sorted_entries: [],
         entry_count: 0,
         tree: nil,
         read_index_checksum: []
       }
       |> clear()}

  @doc ~S"""
  Returns `true` if the argument is a PID representing a valid `Xgit.DirCache` process.
  """
  @spec valid?(dir_cache :: pid) :: boolean
  def valid?(dir_cache) when is_pid(dir_cache) do
    Process.alive?(dir_cache) &&
      GenServer.call(dir_cache, :valid_dir_cache?) == :valid_dir_cache
  end

  def valid?(_), do: false

  # /**
  #  * Create a new builder to update this cache.
  #  * <p>
  #  * Callers should add all entries to the builder, then use
  #  * {@link org.eclipse.jgit.dircache.DirCacheBuilder#finish()} to update this
  #  * instance.
  #  *
  #  * @return a new builder instance for this cache.
  #  */
  # public DirCacheBuilder builder() {
  #   return new DirCacheBuilder(this, entryCnt + 16);
  # }
  #
  # /**
  #  * Create a new editor to recreate this cache.
  #  * <p>
  #  * Callers should add commands to the editor, then use
  #  * {@link org.eclipse.jgit.dircache.DirCacheEditor#finish()} to update this
  #  * instance.
  #  *
  #  * @return a new builder instance for this cache.
  #  */
  # public DirCacheEditor editor() {
  #   return new DirCacheEditor(this, entryCnt + 16);
  # }
  #
  # void replace(DirCacheEntry[] e, int cnt) {
  #   sortedEntries = e;
  #   entryCnt = cnt;
  #   tree = null;
  # }

  @doc ~S"""
  Read the index from disk if it has changed.

  This method tries to avoid loading the index if it has not changed since
  the last time we consulted it. A missing index file will be treated as
  though it were present but had no file entries in it.

  ## Errors

  Raises `File.Error` if the index file is present but could not be read.
  This `DirCache` instance may not be populated correctly.

  Raises `Xgit.Errors.CorruptObjectError` if the index file is using a format or
  extension that this library does not support.
  """
  @spec read!(dir_cache :: pid) :: :ok
  def read!(dir_cache) when is_pid(dir_cache),
    do: GenServerUtils.call!(dir_cache, :read)

  @doc false
  def handle_read(%{live_file: nil}) do
    raise ArgumentError, "DirCache does not have a backing file"
  end

  def handle_read(%{live_file: live_file} = state) do
    if File.exists?(live_file) do
      raise "reading index file UNIMPLEMENTED"
      #    and (snapshot == nil or FileSnapshot.modified?(snapshot, live_file)) do
      # read_index(state)
    else
      {:ok, clear(state)}
    end
  end

  # defp read_index(%{live_file: live_file} = state) do
  #   new_state =
  #     File.open!(live_file, [:read], fn io_device ->
  #       state
  #       |> clear()
  #       |> read_from(io_device)
  #     end)
  #
  #   {:ok, new_state}
  # rescue
  #   File.Error ->
  #     if File.exists?(live_file) do
  #       # Panic: the index file exists but we can't read it.
  #       # credo:disable-for-next-line Credo.Check.Warning.RaiseInsideRescue
  #       raise IndexReadError, "The index file #{live_file} exists but cannot be read"
  #     else
  #       # Someone must have deleted it between our exists test
  #       # and actually opening the path. That's fine, its empty.
  #
  #       {:ok, clear(state)}
  #     end
  # end

  # /**
  #  * Whether the memory state differs from the index file
  #  *
  #  * @return {@code true} if the memory state differs from the index file
  #  * @throws java.io.IOException
  #  */
  # public boolean isOutdated() throws IOException {
  #   if (liveFile == null || !liveFile.exists())
  #     return false;
  #   return snapshot == null || snapshot.isModified(liveFile);
  # }

  # TO DO: Maybe a public version of clear?

  defp clear(state) do
    %{
      state
      | snapshot: nil,
        sorted_entries: [],
        entry_count: 0,
        tree: nil,
        read_index_checksum: []
    }
  end

  # defp read_from(_io_device, %{} = _state) do
  #   raise "UNIMPLEMENTED"

  # final BufferedInputStream in = new BufferedInputStream(inStream);
  # final MessageDigest md = Constants.newMessageDigest();
  #
  # // Read the index header and verify we understand it.
  # //
  # final byte[] hdr = new byte[20];
  # IO.readFully(in, hdr, 0, 12);
  # md.update(hdr, 0, 12);
  # if (!is_DIRC(hdr))
  #   throw new CorruptObjectException(JGitText.get().notADIRCFile);
  # final int ver = NB.decodeInt32(hdr, 4);
  # boolean extended = false;
  # if (ver == 3)
  #   extended = true;
  # else if (ver != 2)
  #   throw new CorruptObjectException(MessageFormat.format(
  #       JGitText.get().unknownDIRCVersion, Integer.valueOf(ver)));
  # entryCnt = NB.decodeInt32(hdr, 8);
  # if (entryCnt < 0)
  #   throw new CorruptObjectException(JGitText.get().DIRCHasTooManyEntries);
  #
  # snapshot = FileSnapshot.save(liveFile);
  # int smudge_s = (int) (snapshot.lastModified() / 1000);
  # int smudge_ns = ((int) (snapshot.lastModified() % 1000)) * 1000000;
  #
  # // Load the individual file entries.
  # //
  # final int infoLength = DirCacheEntry.getMaximumInfoLength(extended);
  # final byte[] infos = new byte[infoLength * entryCnt];
  # sortedEntries = new DirCacheEntry[entryCnt];
  #
  # final MutableInteger infoAt = new MutableInteger();
  # for (int i = 0; i < entryCnt; i++)
  #   sortedEntries[i] = new DirCacheEntry(infos, infoAt, in, md, smudge_s, smudge_ns);
  #
  # // After the file entries are index extensions, and then a footer.
  # //
  # for (;;) {
  #   in.mark(21);
  #   IO.readFully(in, hdr, 0, 20);
  #   if (in.read() < 0) {
  #     // No extensions present; the file ended where we expected.
  #     //
  #     break;
  #   }
  #
  #   in.reset();
  #   md.update(hdr, 0, 8);
  #   IO.skipFully(in, 8);
  #
  #   long sz = NB.decodeUInt32(hdr, 4);
  #   switch (NB.decodeInt32(hdr, 0)) {
  #   case EXT_TREE: {
  #     if (Integer.MAX_VALUE < sz) {
  #       throw new CorruptObjectException(MessageFormat.format(
  #           JGitText.get().DIRCExtensionIsTooLargeAt,
  #           formatExtensionName(hdr), Long.valueOf(sz)));
  #     }
  #     final byte[] raw = new byte[(int) sz];
  #     IO.readFully(in, raw, 0, raw.length);
  #     md.update(raw, 0, raw.length);
  #     tree = new DirCacheTree(raw, new MutableInteger(), null);
  #     break;
  #   }
  #   default:
  #     if (hdr[0] >= 'A' && hdr[0] <= 'Z') {
  #       // The extension is optional and is here only as
  #       // a performance optimization. Since we do not
  #       // understand it, we can safely skip past it, after
  #       // we include its data in our checksum.
  #       //
  #       skipOptionalExtension(in, md, hdr, sz);
  #     } else {
  #       // The extension is not an optimization and is
  #       // _required_ to understand this index format.
  #       // Since we did not trap it above we must abort.
  #       //
  #       throw new CorruptObjectException(MessageFormat.format(JGitText.get().DIRCExtensionNotSupportedByThisVersion
  #           , formatExtensionName(hdr)));
  #     }
  #   }
  # }
  #
  # readIndexChecksum = md.digest();
  # if (!Arrays.equals(readIndexChecksum, hdr)) {
  #   throw new CorruptObjectException(JGitText.get().DIRCChecksumMismatch);
  # }
  # end

  # private void skipOptionalExtension(final InputStream in,
  #     final MessageDigest md, final byte[] hdr, long sz)
  #     throws IOException {
  #   final byte[] b = new byte[4096];
  #   while (0 < sz) {
  #     int n = in.read(b, 0, (int) Math.min(b.length, sz));
  #     if (n < 0) {
  #       throw new EOFException(
  #           MessageFormat.format(
  #               JGitText.get().shortReadOfOptionalDIRCExtensionExpectedAnotherBytes,
  #               formatExtensionName(hdr), Long.valueOf(sz)));
  #     }
  #     md.update(b, 0, n);
  #     sz -= n;
  #   }
  # }
  #
  # private static String formatExtensionName(byte[] hdr) {
  #   return "'" + new String(hdr, 0, 4, ISO_8859_1) + "'"; //$NON-NLS-1$ //$NON-NLS-2$
  # }
  #
  # private static boolean is_DIRC(byte[] hdr) {
  #   if (hdr.length < SIG_DIRC.length)
  #     return false;
  #   for (int i = 0; i < SIG_DIRC.length; i++)
  #     if (hdr[i] != SIG_DIRC[i])
  #       return false;
  #   return true;
  # }
  #
  # /**
  #  * Try to establish an update lock on the cache file.
  #  *
  #  * @return true if the lock is now held by the caller; false if it is held
  #  *         by someone else.
  #  * @throws java.io.IOException
  #  *             the output file could not be created. The caller does not
  #  *             hold the lock.
  #  */
  # public boolean lock() throws IOException {
  #   if (liveFile == null)
  #     throw new IOException(JGitText.get().dirCacheDoesNotHaveABackingFile);
  #   final LockFile tmp = new LockFile(liveFile);
  #   if (tmp.lock()) {
  #     tmp.setNeedStatInformation(true);
  #     myLock = tmp;
  #     return true;
  #   }
  #   return false;
  # }
  #
  # /**
  #  * Write the entry records from memory to disk.
  #  * <p>
  #  * The cache must be locked first by calling {@link #lock()} and receiving
  #  * true as the return value. Applications are encouraged to lock the index,
  #  * then invoke {@link #read()} to ensure the in-memory data is current,
  #  * prior to updating the in-memory entries.
  #  * <p>
  #  * Once written the lock is closed and must be either committed with
  #  * {@link #commit()} or rolled back with {@link #unlock()}.
  #  *
  #  * @throws java.io.IOException
  #  *             the output file could not be created. The caller no longer
  #  *             holds the lock.
  #  */
  # public void write() throws IOException {
  #   final LockFile tmp = myLock;
  #   requireLocked(tmp);
  #   try (OutputStream o = tmp.getOutputStream();
  #       OutputStream bo = new BufferedOutputStream(o)) {
  #     writeTo(liveFile.getParentFile(), bo);
  #   } catch (IOException | RuntimeException | Error err) {
  #     tmp.unlock();
  #     throw err;
  #   }
  # }
  #
  # void writeTo(File dir, OutputStream os) throws IOException {
  #   final MessageDigest foot = Constants.newMessageDigest();
  #   final DigestOutputStream dos = new DigestOutputStream(os, foot);
  #
  #   boolean extended = false;
  #   for (int i = 0; i < entryCnt; i++) {
  #     if (sortedEntries[i].isExtended()) {
  #       extended = true;
  #       break;
  #     }
  #   }
  #
  #   // Write the header.
  #   //
  #   final byte[] tmp = new byte[128];
  #   System.arraycopy(SIG_DIRC, 0, tmp, 0, SIG_DIRC.length);
  #   NB.encodeInt32(tmp, 4, extended ? 3 : 2);
  #   NB.encodeInt32(tmp, 8, entryCnt);
  #   dos.write(tmp, 0, 12);
  #
  #   // Write the individual file entries.
  #
  #   final int smudge_s;
  #   final int smudge_ns;
  #   if (myLock != null) {
  #     // For new files we need to smudge the index entry
  #     // if they have been modified "now". Ideally we'd
  #     // want the timestamp when we're done writing the index,
  #     // so we use the current timestamp as a approximation.
  #     myLock.createCommitSnapshot();
  #     snapshot = myLock.getCommitSnapshot();
  #     smudge_s = (int) (snapshot.lastModified() / 1000);
  #     smudge_ns = ((int) (snapshot.lastModified() % 1000)) * 1000000;
  #   } else {
  #     // Used in unit tests only
  #     smudge_ns = 0;
  #     smudge_s = 0;
  #   }
  #
  #   // Check if tree is non-null here since calling updateSmudgedEntries
  #   // will automatically build it via creating a DirCacheIterator
  #   final boolean writeTree = tree != null;
  #
  #   if (repository != null && entryCnt > 0)
  #     updateSmudgedEntries();
  #
  #   for (int i = 0; i < entryCnt; i++) {
  #     final DirCacheEntry e = sortedEntries[i];
  #     if (e.mightBeRacilyClean(smudge_s, smudge_ns))
  #       e.smudgeRacilyClean();
  #     e.write(dos);
  #   }
  #
  #   if (writeTree) {
  #     @SuppressWarnings("resource") // Explicitly closed in try block, and
  #                     // destroyed in finally
  #     TemporaryBuffer bb = new TemporaryBuffer.LocalFile(dir, 5 << 20);
  #     try {
  #       tree.write(tmp, bb);
  #       bb.close();
  #
  #       NB.encodeInt32(tmp, 0, EXT_TREE);
  #       NB.encodeInt32(tmp, 4, (int) bb.length());
  #       dos.write(tmp, 0, 8);
  #       bb.writeTo(dos, null);
  #     } finally {
  #       bb.destroy();
  #     }
  #   }
  #   writeIndexChecksum = foot.digest();
  #   os.write(writeIndexChecksum);
  #   os.close();
  # }
  #
  # /**
  #  * Commit this change and release the lock.
  #  * <p>
  #  * If this method fails (returns false) the lock is still released.
  #  *
  #  * @return true if the commit was successful and the file contains the new
  #  *         data; false if the commit failed and the file remains with the
  #  *         old data.
  #  * @throws java.lang.IllegalStateException
  #  *             the lock is not held.
  #  */
  # public boolean commit() {
  #   final LockFile tmp = myLock;
  #   requireLocked(tmp);
  #   myLock = null;
  #   if (!tmp.commit()) {
  #     return false;
  #   }
  #   snapshot = tmp.getCommitSnapshot();
  #   if (indexChangedListener != null
  #       && !Arrays.equals(readIndexChecksum, writeIndexChecksum)) {
  #     indexChangedListener.onIndexChanged(new IndexChangedEvent(true));
  #   }
  #   return true;
  # }
  #
  # private void requireLocked(LockFile tmp) {
  #   if (liveFile == null)
  #     throw new IllegalStateException(JGitText.get().dirCacheIsNotLocked);
  #   if (tmp == null)
  #     throw new IllegalStateException(MessageFormat.format(JGitText.get().dirCacheFileIsNotLocked
  #         , liveFile.getAbsolutePath()));
  # }
  #
  # /**
  #  * Unlock this file and abort this change.
  #  * <p>
  #  * The temporary file (if created) is deleted before returning.
  #  */
  # public void unlock() {
  #   final LockFile tmp = myLock;
  #   if (tmp != null) {
  #     myLock = null;
  #     tmp.unlock();
  #   }
  # }
  #
  # /**
  #  * Locate the position a path's entry is at in the index. For details refer
  #  * to #findEntry(byte[], int).
  #  *
  #  * @param path
  #  *            the path to search for.
  #  * @return if &gt;= 0 then the return value is the position of the entry in
  #  *         the index; pass to {@link #getEntry(int)} to obtain the entry
  #  *         information. If &lt; 0 the entry does not exist in the index.
  #  */
  # public int findEntry(String path) {
  #   final byte[] p = Constants.encode(path);
  #   return findEntry(p, p.length);
  # }
  #
  # /**
  #  * Locate the position a path's entry is at in the index.
  #  * <p>
  #  * If there is at least one entry in the index for this path the position of
  #  * the lowest stage is returned. Subsequent stages can be identified by
  #  * testing consecutive entries until the path differs.
  #  * <p>
  #  * If no path matches the entry -(position+1) is returned, where position is
  #  * the location it would have gone within the index.
  #  *
  #  * @param p
  #  *            the byte array starting with the path to search for.
  #  * @param pLen
  #  *            the length of the path in bytes
  #  * @return if &gt;= 0 then the return value is the position of the entry in
  #  *         the index; pass to {@link #getEntry(int)} to obtain the entry
  #  *         information. If &lt; 0 the entry does not exist in the index.
  #  * @since 3.4
  #  */
  # public int findEntry(byte[] p, int pLen) {
  #   return findEntry(0, p, pLen);
  # }
  #
  # int findEntry(int low, byte[] p, int pLen) {
  #   int high = entryCnt;
  #   while (low < high) {
  #     int mid = (low + high) >>> 1;
  #     final int cmp = cmp(p, pLen, sortedEntries[mid]);
  #     if (cmp < 0)
  #       high = mid;
  #     else if (cmp == 0) {
  #       while (mid > 0 && cmp(p, pLen, sortedEntries[mid - 1]) == 0)
  #         mid--;
  #       return mid;
  #     } else
  #       low = mid + 1;
  #   }
  #   return -(low + 1);
  # }
  #
  # /**
  #  * Determine the next index position past all entries with the same name.
  #  * <p>
  #  * As index entries are sorted by path name, then stage number, this method
  #  * advances the supplied position to the first position in the index whose
  #  * path name does not match the path name of the supplied position's entry.
  #  *
  #  * @param position
  #  *            entry position of the path that should be skipped.
  #  * @return position of the next entry whose path is after the input.
  #  */
  # public int nextEntry(int position) {
  #   DirCacheEntry last = sortedEntries[position];
  #   int nextIdx = position + 1;
  #   while (nextIdx < entryCnt) {
  #     final DirCacheEntry next = sortedEntries[nextIdx];
  #     if (cmp(last, next) != 0)
  #       break;
  #     last = next;
  #     nextIdx++;
  #   }
  #   return nextIdx;
  # }
  #
  # int nextEntry(byte[] p, int pLen, int nextIdx) {
  #   while (nextIdx < entryCnt) {
  #     final DirCacheEntry next = sortedEntries[nextIdx];
  #     if (!DirCacheTree.peq(p, next.path, pLen))
  #       break;
  #     nextIdx++;
  #   }
  #   return nextIdx;
  # }

  @doc ~S"""
  Return the total number of file entries stored in the index.

  This count includes unmerged stages for a file entry if the file is currently
  conflicted in a merge. This means the total number of entries in the index may
  be up to 3 times larger than the number of files in the working directory.

  Note that this value counts only _files_.
  """
  @spec entry_count(dir_cache :: pid) :: non_neg_integer
  def entry_count(dir_cache) when is_pid(dir_cache),
    do: GenServerUtils.call!(dir_cache, :entry_count)

  @doc false
  def handle_entry_count(%{entry_count: entry_count} = state), do: {:ok, entry_count, state}

  # /**
  #  * Get a specific entry.
  #  *
  #  * @param i
  #  *            position of the entry to get.
  #  * @return the entry at position <code>i</code>.
  #  */
  # public DirCacheEntry getEntry(int i) {
  #   return sortedEntries[i];
  # }
  #
  # /**
  #  * Get a specific entry.
  #  *
  #  * @param path
  #  *            the path to search for.
  #  * @return the entry for the given <code>path</code>.
  #  */
  # public DirCacheEntry getEntry(String path) {
  #   final int i = findEntry(path);
  #   return i < 0 ? null : sortedEntries[i];
  # }
  #
  # /**
  #  * Recursively get all entries within a subtree.
  #  *
  #  * @param path
  #  *            the subtree path to get all entries within.
  #  * @return all entries recursively contained within the subtree.
  #  */
  # public DirCacheEntry[] getEntriesWithin(String path) {
  #   if (path.length() == 0) {
  #     DirCacheEntry[] r = new DirCacheEntry[entryCnt];
  #     System.arraycopy(sortedEntries, 0, r, 0, entryCnt);
  #     return r;
  #   }
  #   if (!path.endsWith("/")) //$NON-NLS-1$
  #     path += "/"; //$NON-NLS-1$
  #   final byte[] p = Constants.encode(path);
  #   final int pLen = p.length;
  #
  #   int eIdx = findEntry(p, pLen);
  #   if (eIdx < 0)
  #     eIdx = -(eIdx + 1);
  #   final int lastIdx = nextEntry(p, pLen, eIdx);
  #   final DirCacheEntry[] r = new DirCacheEntry[lastIdx - eIdx];
  #   System.arraycopy(sortedEntries, eIdx, r, 0, r.length);
  #   return r;
  # }
  #
  # void toArray(final int i, final DirCacheEntry[] dst, final int off,
  #     final int cnt) {
  #   System.arraycopy(sortedEntries, i, dst, off, cnt);
  # }
  #
  # /**
  #  * Obtain (or build) the current cache tree structure.
  #  * <p>
  #  * This method can optionally recreate the cache tree, without flushing the
  #  * tree objects themselves to disk.
  #  *
  #  * @param build
  #  *            if true and the cache tree is not present in the index it will
  #  *            be generated and returned to the caller.
  #  * @return the cache tree; null if there is no current cache tree available
  #  *         and <code>build</code> was false.
  #  */
  # public DirCacheTree getCacheTree(boolean build) {
  #   if (build) {
  #     if (tree == null)
  #       tree = new DirCacheTree();
  #     tree.validate(sortedEntries, entryCnt, 0, 0);
  #   }
  #   return tree;
  # }
  #
  # /**
  #  * Write all index trees to the object store, returning the root tree.
  #  *
  #  * @param ow
  #  *            the writer to use when serializing to the store. The caller is
  #  *            responsible for flushing the inserter before trying to use the
  #  *            returned tree identity.
  #  * @return identity for the root tree.
  #  * @throws org.eclipse.jgit.errors.UnmergedPathException
  #  *             one or more paths contain higher-order stages (stage &gt; 0),
  #  *             which cannot be stored in a tree object.
  #  * @throws java.lang.IllegalStateException
  #  *             one or more paths contain an invalid mode which should never
  #  *             appear in a tree object.
  #  * @throws java.io.IOException
  #  *             an unexpected error occurred writing to the object store.
  #  */
  # public ObjectId writeTree(ObjectInserter ow)
  #     throws UnmergedPathException, IOException {
  #   return getCacheTree(true).writeTree(sortedEntries, 0, 0, ow);
  # }
  #
  # /**
  #  * Tells whether this index contains unmerged paths.
  #  *
  #  * @return {@code true} if this index contains unmerged paths. Means: at
  #  *         least one entry is of a stage different from 0. {@code false}
  #  *         will be returned if all entries are of stage 0.
  #  */
  # public boolean hasUnmergedPaths() {
  #   for (int i = 0; i < entryCnt; i++) {
  #     if (sortedEntries[i].getStage() > 0) {
  #       return true;
  #     }
  #   }
  #   return false;
  # }
  #
  # private void registerIndexChangedListener(IndexChangedListener listener) {
  #   this.indexChangedListener = listener;
  # }
  #
  # /**
  #  * Update any smudged entries with information from the working tree.
  #  *
  #  * @throws IOException
  #  */
  # private void updateSmudgedEntries() throws IOException {
  #   List<String> paths = new ArrayList<>(128);
  #   try (TreeWalk walk = new TreeWalk(repository)) {
  #     walk.setOperationType(OperationType.CHECKIN_OP);
  #     for (int i = 0; i < entryCnt; i++)
  #       if (sortedEntries[i].isSmudged())
  #         paths.add(sortedEntries[i].getPathString());
  #     if (paths.isEmpty())
  #       return;
  #     walk.setFilter(PathFilterGroup.createFromStrings(paths));
  #
  #     DirCacheIterator iIter = new DirCacheIterator(this);
  #     FileTreeIterator fIter = new FileTreeIterator(repository);
  #     walk.addTree(iIter);
  #     walk.addTree(fIter);
  #     fIter.setDirCacheIterator(walk, 0);
  #     walk.setRecursive(true);
  #     while (walk.next()) {
  #       iIter = walk.getTree(0, DirCacheIterator.class);
  #       if (iIter == null)
  #         continue;
  #       fIter = walk.getTree(1, FileTreeIterator.class);
  #       if (fIter == null)
  #         continue;
  #       DirCacheEntry entry = iIter.getDirCacheEntry();
  #       if (entry.isSmudged() && iIter.idEqual(fIter)) {
  #         entry.setLength(fIter.getEntryLength());
  #         entry.setLastModified(fIter.getEntryLastModified());
  #       }
  #     }
  #   }
  # }

  @impl GenServer
  def handle_call(:valid_dir_cache?, _from, state), do: {:reply, :valid_dir_cache, state}

  def handle_call(:read, _from, state),
    do: GenServerUtils.wrap_call(__MODULE__, :handle_read, [state], state)

  def handle_call(:entry_count, _from, state),
    do: GenServerUtils.wrap_call(__MODULE__, :handle_entry_count, [state], state)
end
