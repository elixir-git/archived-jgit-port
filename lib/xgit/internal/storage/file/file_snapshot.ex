defmodule Xgit.Internal.Storage.File.FileSnapshot do
  @moduledoc ~S"""
  Caches when a file was last read, making it possible to detect future edits.

  This object tracks the last modified time of a file. Later during an
  invocation of `modified?/2` the object will return true if the file may have
  been modified and should be re-read from disk.

  A snapshot does not "live update" when the underlying filesystem changes.
  Callers must poll for updates by periodically invoking `modified?/2`.

  To work around the "racy git" problem (where a file may be modified multiple
  times within the granularity of the filesystem modification clock) this class
  may return `true` from `modified?/2` if the last modification time of the
  file is less than 3 seconds ago.

  Struct members:
  * `last_modified`: Last observed modification time of the path.
  * `last_read`: When was the modification time last read?
  """

  @enforce_keys [:last_modified, :ref]
  defstruct [:last_modified, :ref]

  @doc ~S"""
  A FileSnapshot that is considered to always be modified.

  This instance is useful for application code that wants to lazily read a
  file, but only after `modified?/2` gets invoked. This snapshot instance
  contains only invalid status information.
  """
  def dirty, do: %__MODULE__{last_modified: :dirty, ref: nil}

  @doc ~S"""
  A FileSnapshot that is clean if the file does not exist.

  This instance is useful if the application wants to consider a missing
  file to be clean. `modified?/2` will return `false` if the file path
  does not exist.
  """
  def missing_file, do: %__MODULE__{last_modified: :missing, ref: nil}

  @doc ~S"""
  Record a snapshot for a specific file path.

  This method should be invoked before the file is accessed.
  """
  def save(path) when is_binary(path) do
    %{mtime: last_modified} = File.stat!(path, time: :posix)

    ref = make_ref()
    record_time_for_ref(ref)

    %__MODULE__{last_modified: last_modified, ref: ref}
  end

  # /**
  #  * Record a snapshot for a file for which the last modification time is
  #  * already known.
  #  * <p>
  #  * This method should be invoked before the file is accessed.
  #  *
  #  * @param modified
  #  *            the last modification time of the file
  #  * @return the snapshot.
  #  */
  # public static FileSnapshot save(long modified) {
  # 	final long read = System.currentTimeMillis();
  # 	return new FileSnapshot(read, modified);
  # }

  # /** True once {@link #lastRead} is far later than {@link #lastModified}. */
  # private boolean cannotBeRacilyClean;

  @doc ~S"""
  Check if the path may have been modified since the snapshot was saved.
  """
  def modified?(%__MODULE__{last_modified: last_modified, ref: ref}, path)
      when is_binary(path) and is_reference(ref) do
    %{mtime: curr_last_modified} = File.stat!(path, time: :posix)
    modified_impl?(curr_last_modified, last_modified, ref)
  end

  def modified?(%__MODULE__{last_modified: :dirty}, _path), do: true
  def modified?(%__MODULE__{last_modified: :missing}, path), do: File.exists?(path)

  # /**
  #  * Update this snapshot when the content hasn't changed.
  #  * <p>
  #  * If the caller gets true from {@link #isModified(File)}, re-reads the
  #  * content, discovers the content is identical, and
  #  * {@link #equals(FileSnapshot)} is true, it can use
  #  * {@link #setClean(FileSnapshot)} to make a future
  #  * {@link #isModified(File)} return false. The logic goes something like
  #  * this:
  #  *
  #  * <pre>
  #  * if (snapshot.isModified(path)) {
  #  *  FileSnapshot other = FileSnapshot.save(path);
  #  *  Content newContent = ...;
  #  *  if (oldContent.equals(newContent) &amp;&amp; snapshot.equals(other))
  #  *      snapshot.setClean(other);
  #  * }
  #  * </pre>
  #  *
  #  * @param other
  #  *            the other snapshot.
  #  */
  # public void setClean(FileSnapshot other) {
  # 	final long now = other.lastRead;
  # 	if (notRacyClean(now))
  # 		cannotBeRacilyClean = true;
  # 	lastRead = now;
  # }

  # /** {@inheritDoc} */
  # @Override
  # public String toString() {
  # 	if (this == DIRTY)
  # 		return "DIRTY"; //$NON-NLS-1$
  # 	if (this == MISSING_FILE)
  # 		return "MISSING_FILE"; //$NON-NLS-1$
  # 	DateFormat f = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", //$NON-NLS-1$
  # 			Locale.US);
  # 	return "FileSnapshot[modified: " + f.format(new Date(lastModified)) //$NON-NLS-1$
  # 			+ ", read: " + f.format(new Date(lastRead)) + "]"; //$NON-NLS-1$ //$NON-NLS-2$
  # }

  defp modified_impl?(file_last_modified, last_modified, ref) do
    last_read_time = ConCache.get(:xgit_file_snapshot, ref)

    if last_modified == file_last_modified,
      do: true,
      else: modified_impl_race?(file_last_modified, last_read_time)
  end

  # There's a potential race condition in which the file was modified at roughly
  # the same time as the last time we read the modification time. If these two
  # events are too close together, we have to assume the file is modified.

  defp modified_impl_race?(_file_last_modified, nil) do
    # We have already determined the last read was far enough
    # after the last modification that any new modifications
    # are certain to change the last modified time.
    false
  end

  defp modified_impl_race?(file_last_modified, last_read_time) do
    if not_racy_clean?(file_last_modified, last_read_time) do
      # Our last read should have marked cannotBeRacilyClean,
      # but this thread may not have seen the change. The read
      # of the volatile field lastRead should have fixed that.
      false
    else
      # We last read this path too close to its last observed
      # modification time. We may have missed a modification.
      # Scan again, to ensure we still see the same state.
      true
    end
  end

  defp not_racy_clean?(last_modified_time, last_read_time) do
    last_read_time - last_modified_time >= 3
    # The last modified time granularity of FAT filesystems is 2 seconds.
    # Using 3 seconds here provides a reasonably high assurance that
    # a modification was not missed.
  end

  defp record_time_for_ref(ref) when is_reference(ref),
    do: ConCache.put(:xgit_file_snapshot, ref, :os.system_time(:second))
end
