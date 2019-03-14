defmodule Xgit.Storage.File.FileBasedConfig do
  @moduledoc ~S"""
  Implements `Xgit.Lib.Config.Storage` by storing the config data in a file.
  (This is the typical case.)

  Struct members:
  * `path`: Path to the config file.
  * `snapshot`: An `Xgit.Internal.Storage.File.FileSnapshot` for this path.
  """
  @enforce_keys [:path, :snapshot]
  defstruct [:path, :snapshot]

  alias Xgit.Internal.Storage.File.FileSnapshot
  alias Xgit.Lib.Config

  # private boolean utf8Bom;   ### TODO: Figure out where this lands.
  # private volatile ObjectId hash;  ### TODO: Figure out where this lands.

  @doc ~S"""
  Create a configuration for a file path with no default fallback.

  Options are as for `Xgit.Lib.Config.new/1`.
  """
  def config_for_path(path, options \\ []) when is_binary(path) do
    storage = %__MODULE__{path: path, snapshot: FileSnapshot.save(path)}
    # this.snapshot = FileSnapshot.DIRTY;
    # this.hash = ObjectId.zeroId();

    Config.new(Keyword.put(options, :storage, storage))
  end

  # /** {@inheritDoc} */
  # @Override
  # protected boolean notifyUponTransientChanges() {
  #   // we will notify listeners upon save()
  #   return false;
  # }

  # /** {@inheritDoc} */
  # @Override
  # public void clear() {
  #   hash = hash(new byte[0]);
  #   super.clear();
  # }
  #
  # private static ObjectId hash(byte[] rawText) {
  #   return ObjectId.fromRaw(Constants.newMessageDigest().digest(rawText));
  # }
  #
  # /** {@inheritDoc} */
  # @SuppressWarnings("nls")
  # @Override
  # public String toString() {
  #   return getClass().getSimpleName() + "[" + getFile().getPath() + "]";
  # }
  #
  # /**
  #  * Whether the currently loaded configuration file is outdated
  #  *
  #  * @return returns true if the currently loaded configuration file is older
  #  *         than the file on disk
  #  */
  # public boolean isOutdated() {
  #   return snapshot.isModified(getFile());
  # }
  #
  # /**
  #  * {@inheritDoc}
  #  *
  #  * @since 4.10
  #  */
  # @Override
  # protected byte[] readIncludedConfig(String relPath)
  #     throws ConfigInvalidException {
  #   final File file;
  #   if (relPath.startsWith("~/")) { //$NON-NLS-1$
  #     file = fs.resolve(fs.userHome(), relPath.substring(2));
  #   } else {
  #     file = fs.resolve(configFile.getParentFile(), relPath);
  #   }
  #
  #   if (!file.exists()) {
  #     return null;
  #   }
  #
  #   try {
  #     return IO.readFully(file);
  #   } catch (IOException ioe) {
  #     throw new ConfigInvalidException(MessageFormat
  #         .format(JGitText.get().cannotReadFile, relPath), ioe);
  #   }
  # }
end

defimpl Xgit.Lib.Config.Storage, for: Xgit.Storage.File.FileBasedConfig do
  @doc ~S"""
  Load the configuration as a Git text style configuration file.

  If the file does not exist, this configuration is cleared, and thus
  behaves the same as though the file exists, but is empty.
  """
  def load(%Xgit.Storage.File.FileBasedConfig{}, config) do
    #   final int maxStaleRetries = 5;
    #   int retries = 0;
    #   while (true) {
    #     final FileSnapshot oldSnapshot = snapshot;
    #     final FileSnapshot newSnapshot = FileSnapshot.save(getFile());
    #     try {
    #       final byte[] in = IO.readFully(getFile());
    #       final ObjectId newHash = hash(in);
    #       if (hash.equals(newHash)) {
    #         if (oldSnapshot.equals(newSnapshot)) {
    #           oldSnapshot.setClean(newSnapshot);
    #         } else {
    #           snapshot = newSnapshot;
    #         }
    #       } else {
    #         final String decoded;
    #         if (isUtf8(in)) {
    #           decoded = RawParseUtils.decode(UTF_8,
    #               in, 3, in.length);
    #           utf8Bom = true;
    #         } else {
    #           decoded = RawParseUtils.decode(in);
    #         }
    #         fromText(decoded);
    #         snapshot = newSnapshot;
    #         hash = newHash;
    #       }
    #       return;
    #     } catch (FileNotFoundException noFile) {
    #       if (configFile.exists()) {
    #         throw noFile;
    #       }
    #       clear();
    #       snapshot = newSnapshot;
    #       return;
    #     } catch (IOException e) {
    #       if (FileUtils.isStaleFileHandle(e)
    #           && retries < maxStaleRetries) {
    #         if (LOG.isDebugEnabled()) {
    #           LOG.debug(MessageFormat.format(
    #               JGitText.get().configHandleIsStale,
    #               Integer.valueOf(retries)), e);
    #         }
    #         retries++;
    #         continue;
    #       }
    #       throw new IOException(MessageFormat
    #           .format(JGitText.get().cannotReadFile, getFile()), e);
    #     } catch (ConfigInvalidException e) {
    #       throw new ConfigInvalidException(MessageFormat
    #           .format(JGitText.get().cannotReadFile, getFile()), e);
    #     }
    #   }
    :unimplemented
  end

  def save(%Xgit.Storage.File.FileBasedConfig{}, config) do
    :unimplemented
  end

  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Save the configuration as a Git text style configuration file.
  #  * <p>
  #  * <b>Warning:</b> Although this method uses the traditional Git file
  #  * locking approach to protect against concurrent writes of the
  #  * configuration file, it does not ensure that the file has not been
  #  * modified since the last read, which means updates performed by other
  #  * objects accessing the same backing file may be lost.
  #  */
  # @Override
  # public void save() throws IOException {
  #   final byte[] out;
  #   final String text = toText();
  #   if (utf8Bom) {
  #     final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #     bos.write(0xEF);
  #     bos.write(0xBB);
  #     bos.write(0xBF);
  #     bos.write(text.getBytes(UTF_8));
  #     out = bos.toByteArray();
  #   } else {
  #     out = Constants.encode(text);
  #   }
  #
  #   final LockFile lf = new LockFile(getFile());
  #   if (!lf.lock())
  #     throw new LockFailedException(getFile());
  #   try {
  #     lf.setNeedSnapshot(true);
  #     lf.write(out);
  #     if (!lf.commit())
  #       throw new IOException(MessageFormat.format(JGitText.get().cannotCommitWriteTo, getFile()));
  #   } finally {
  #     lf.unlock();
  #   }
  #   snapshot = lf.getCommitSnapshot();
  #   hash = hash(out);
  #   // notify the listeners
  #   fireConfigChangedEvent();
  # }
end
