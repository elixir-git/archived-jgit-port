defmodule Xgit.Storage.File.FileBasedConfig do
  @moduledoc ~S"""
  Implements `Xgit.Lib.Config.Storage` by storing the config data in a file.
  (This is the typical case.)

  Struct members:
  * `path`: Path to the config file.
  * `snapshot`: An `Xgit.Internal.Storage.File.FileSnapshot` for this path.
  """
  @enforce_keys [:path]
  defstruct [:path]

  alias Xgit.Lib.Config

  # private boolean utf8Bom;   ### TODO: Figure out where this lands.

  @doc ~S"""
  Create a configuration for a file path with no default fallback.

  Options are as for `Xgit.Lib.Config.new/1`.
  """
  def config_for_path(path, options \\ []) when is_binary(path),
    do: Config.new(Keyword.put(options, :storage, %__MODULE__{path: path}))

  # /** {@inheritDoc} */
  # @Override
  # protected boolean notifyUponTransientChanges() {
  #   // we will notify listeners upon save()
  #   return false;
  # }

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
  alias Xgit.Lib.Config

  @doc ~S"""
  Load the configuration as a Git text style configuration file.

  If the file does not exist, this configuration is cleared, and thus
  behaves the same as though the file exists, but is empty.
  """
  def load(%Xgit.Storage.File.FileBasedConfig{path: path}, config) do
    # PORTING NOTE: jgit's implementation contains a lot of logic to handle
    # cases where the file has moved, becomes stale, retrying in the event
    # of failure, etc. For now, I am not porting those cases. Consider revisiting
    # this later.

    if File.exists?(path) do
      contents = File.read!(path)
      Config.from_text(config, contents)
    else
      Config.clear(config)
    end

    :ok
  end

  def save(%Xgit.Storage.File.FileBasedConfig{}, _config) do
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
