defmodule Xgit.Storage.File.FileBasedConfig do
  @moduledoc ~S"""
  Implements `Xgit.Lib.Config.Storage` by storing the config data in a file.
  (This is the typical case.)
  """

  # defstruct [:path]

  # private final static Logger LOG = LoggerFactory
  #     .getLogger(FileBasedConfig.class);
  #
  # private final File configFile;
  #
  # private final FS fs;
  #
  # private boolean utf8Bom;
  #
  # private volatile FileSnapshot snapshot;
  #
  # private volatile ObjectId hash;
  #
  # /**
  #  * Create a configuration with no default fallback.
  #  *
  #  * @param cfgLocation
  #  *            the location of the configuration file on the file system
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  */
  # public FileBasedConfig(File cfgLocation, FS fs) {
  #   this(null, cfgLocation, fs);
  # }
  #
  # /**
  #  * The constructor
  #  *
  #  * @param base
  #  *            the base configuration file
  #  * @param cfgLocation
  #  *            the location of the configuration file on the file system
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  */
  # public FileBasedConfig(Config base, File cfgLocation, FS fs) {
  #   super(base);
  #   configFile = cfgLocation;
  #   this.fs = fs;
  #   this.snapshot = FileSnapshot.DIRTY;
  #   this.hash = ObjectId.zeroId();
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # protected boolean notifyUponTransientChanges() {
  #   // we will notify listeners upon save()
  #   return false;
  # }
  #
  # /**
  #  * Get location of the configuration file on disk
  #  *
  #  * @return location of the configuration file on disk
  #  */
  # public final File getFile() {
  #   return configFile;
  # }
  #
  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Load the configuration as a Git text style configuration file.
  #  * <p>
  #  * If the file does not exist, this configuration is cleared, and thus
  #  * behaves the same as though the file exists, but is empty.
  #  */
  # @Override
  # public void load() throws IOException, ConfigInvalidException {
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
  # }
  #
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
  #
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
  def load(%Xgit.Storage.File.FileBasedConfig{}, config) do
    :unimplemented
  end

  def save(%Xgit.Storage.File.FileBasedConfig{}, config) do
    :unimplemented
  end
end
