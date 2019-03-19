defmodule Xgit.Lib.BaseRepositoryBuilder do
  @moduledoc ~S"""
  A behaviour module for implementing specialized repository construction.

  An implementation of this behaviour may add custom repository detection methods.

  Struct members:
  * `git_dir`: The `.git` directory storing the repository metadata.
  * `object_dir`: The directory storing the repository's objects.
  * `alternate_object_directories`: List of alternate object directories to search.
  * `bare?`: True only if the caller wants to force bare behavior.
  * `must_exist?`: True if the caller requires the repository to exist.
  * `work_tree`: The top level directory of the working files.
  * `index_file`: The local index file that is caching checked out file status.
  * `ceiling_directories`: A list of directories limiting the search for a Git repository.

  PORTING NOTE: Unlike the jgit implementation, this version has no setters or getters
  for the configuration options. Set up the struct directly and then call the
  functions on this module to set up the repository.
  """

  defstruct git_dir: nil,
            object_dir: nil,
            alternate_object_directories: nil,
            bare?: false,
            must_exist?: false,
            work_tree: nil,
            index_file: nil,
            ceiling_directories: nil

  alias Xgit.Lib.Constants
  alias Xgit.Util.SystemReader

  @doc ~S"""
  Read standard git environment variables and configure from those.

  This method tries to read the standard git environment variables, such as
  `GIT_DIR` and `GIT_WORK_TREE` to configure this builder struct. If a property
  is already set in the struct, the environment variable is not used.

  Returns an updated copy of the builder struct.
  """
  def read_environment(%__MODULE__{} = builder, system_reader \\ nil) do
    builder
    |> maybe_update_git_dir(system_reader)
    |> maybe_update_object_dir(system_reader)
    |> maybe_update_alternate_object_directories(system_reader)
    |> maybe_update_work_tree(system_reader)
    |> maybe_update_index_file(system_reader)
    |> maybe_update_ceiling_directories(system_reader)
  end

  defp maybe_update_git_dir(%__MODULE__{git_dir: nil} = builder, reader),
    do: %{builder | git_dir: SystemReader.get_env(reader, Constants.git_dir_key())}

  defp maybe_update_git_dir(builder, _), do: builder

  defp maybe_update_object_dir(%__MODULE__{object_dir: nil} = builder, reader),
    do: %{
      builder
      | object_dir: SystemReader.get_env(reader, Constants.git_object_directory_key())
    }

  defp maybe_update_object_dir(builder, _), do: builder

  defp maybe_update_alternate_object_directories(
         %__MODULE__{alternate_object_directories: nil} = builder,
         reader
       ) do
    case SystemReader.get_env(reader, Constants.git_alternate_object_directories_key()) do
      nil ->
        builder

      x ->
        %{builder | alternate_object_directories: String.split(x, ":")}
        # WINDOWS PORTING NOTE: Should be ";" for Windows.
    end
  end

  defp maybe_update_alternate_object_directories(builder, _), do: builder

  defp maybe_update_work_tree(%__MODULE__{work_tree: nil} = builder, reader),
    do: %{builder | work_tree: SystemReader.get_env(reader, Constants.git_work_tree_key())}

  defp maybe_update_work_tree(builder, _), do: builder

  defp maybe_update_index_file(%__MODULE__{index_file: nil} = builder, reader),
    do: %{builder | index_file: SystemReader.get_env(reader, Constants.git_index_file_key())}

  defp maybe_update_index_file(builder, _), do: builder

  defp maybe_update_ceiling_directories(%__MODULE__{ceiling_directories: nil} = builder, reader) do
    case SystemReader.get_env(reader, Constants.git_ceiling_directories_key()) do
      nil ->
        builder

      x ->
        %{builder | ceiling_directories: String.split(x, ":")}
        # WINDOWS PORTING NOTE: Should be ";" for Windows.
    end
  end

  defp maybe_update_ceiling_directories(builder, _), do: builder

  # /**
  #  * Configure {@code GIT_DIR} by searching up the file system.
  #  * <p>
  #  * Starts from the current working directory of the JVM and scans up through
  #  * the directory tree until a Git repository is found. Success can be
  #  * determined by checking for {@code getGitDir() != null}.
  #  * <p>
  #  * The search can be limited to specific spaces of the local filesystem by
  #  * {@link #addCeilingDirectory(File)}, or inheriting the list through a
  #  * prior call to {@link #readEnvironment()}.
  #  *
  #  * @return {@code this} (for chaining calls).
  #  */
  # public B findGitDir() {
  #   if (getGitDir() == null)
  #     findGitDir(new File("").getAbsoluteFile()); //$NON-NLS-1$
  #   return self();
  # }
  #
  # /**
  #  * Configure {@code GIT_DIR} by searching up the file system.
  #  * <p>
  #  * Starts from the supplied directory path and scans up through the parent
  #  * directory tree until a Git repository is found. Success can be determined
  #  * by checking for {@code getGitDir() != null}.
  #  * <p>
  #  * The search can be limited to specific spaces of the local filesystem by
  #  * {@link #addCeilingDirectory(File)}, or inheriting the list through a
  #  * prior call to {@link #readEnvironment()}.
  #  *
  #  * @param current
  #  *            directory to begin searching in.
  #  * @return {@code this} (for chaining calls).
  #  */
  # public B findGitDir(File current) {
  #   if (getGitDir() == null) {
  #     FS tryFS = safeFS();
  #     while (current != null) {
  #       File dir = new File(current, DOT_GIT);
  #       if (FileKey.isGitRepository(dir, tryFS)) {
  #         setGitDir(dir);
  #         break;
  #       } else if (dir.isFile()) {
  #         try {
  #           setGitDir(getSymRef(current, dir, tryFS));
  #           break;
  #         } catch (IOException ignored) {
  #           // Continue searching if gitdir ref isn't found
  #         }
  #       } else if (FileKey.isGitRepository(current, tryFS)) {
  #         setGitDir(current);
  #         break;
  #       }
  #
  #       current = current.getParentFile();
  #       if (current != null && ceilingDirectories != null
  #           && ceilingDirectories.contains(current))
  #         break;
  #     }
  #   }
  #   return self();
  # }
  #
  # private static boolean isSymRef(byte[] ref) {
  #   if (ref.length < 9)
  #     return false;
  #   return /**/ref[0] == 'g' //
  #       && ref[1] == 'i' //
  #       && ref[2] == 't' //
  #       && ref[3] == 'd' //
  #       && ref[4] == 'i' //
  #       && ref[5] == 'r' //
  #       && ref[6] == ':' //
  #       && ref[7] == ' ';
  # }
  #
  # private static File getSymRef(File workTree, File dotGit, FS fs)
  #     throws IOException {
  #   byte[] content = IO.readFully(dotGit);
  #   if (!isSymRef(content))
  #     throw new IOException(MessageFormat.format(
  #         JGitText.get().invalidGitdirRef, dotGit.getAbsolutePath()));
  #
  #   int pathStart = 8;
  #   int lineEnd = RawParseUtils.nextLF(content, pathStart);
  #   while (content[lineEnd - 1] == '\n' ||
  #          (content[lineEnd - 1] == '\r' && SystemReader.getInstance().isWindows()))
  #     lineEnd--;
  #   if (lineEnd == pathStart)
  #     throw new IOException(MessageFormat.format(
  #         JGitText.get().invalidGitdirRef, dotGit.getAbsolutePath()));
  #
  #   String gitdirPath = RawParseUtils.decode(content, pathStart, lineEnd);
  #   File gitdirFile = fs.resolve(workTree, gitdirPath);
  #   if (gitdirFile.isAbsolute())
  #     return gitdirFile;
  #   else
  #     return new File(workTree, gitdirPath).getCanonicalFile();
  # }
  #
  # /** Configuration file of target repository, lazily loaded if required. */
  # private Config config;
  #
  # /**
  #  * Guess and populate all parameters not already defined.
  #  * <p>
  #  * If an option was not set, the setup method will try to default the option
  #  * based on other options. If insufficient information is available, an
  #  * exception is thrown to the caller.
  #  *
  #  * @return {@code this}
  #  * @throws java.lang.IllegalArgumentException
  #  *             insufficient parameters were set, or some parameters are
  #  *             incompatible with one another.
  #  * @throws java.io.IOException
  #  *             the repository could not be accessed to configure the rest of
  #  *             the builder's parameters.
  #  */
  # public B setup() throws IllegalArgumentException, IOException {
  #   requireGitDirOrWorkTree();
  #   setupGitDir();
  #   setupWorkTree();
  #   setupInternals();
  #   return self();
  # }
  #
  # /**
  #  * Create a repository matching the configuration in this builder.
  #  * <p>
  #  * If an option was not set, the build method will try to default the option
  #  * based on other options. If insufficient information is available, an
  #  * exception is thrown to the caller.
  #  *
  #  * @return a repository matching this configuration. The caller is
  #  *         responsible to close the repository instance when it is no longer
  #  *         needed.
  #  * @throws java.lang.IllegalArgumentException
  #  *             insufficient parameters were set.
  #  * @throws java.io.IOException
  #  *             the repository could not be accessed to configure the rest of
  #  *             the builder's parameters.
  #  */
  # @SuppressWarnings({ "unchecked", "resource" })
  # public R build() throws IOException {
  #   R repo = (R) new FileRepository(setup());
  #   if (isMustExist() && !repo.getObjectDatabase().exists())
  #     throw new RepositoryNotFoundException(getGitDir());
  #   return repo;
  # }
  #
  # /**
  #  * Require either {@code gitDir} or {@code workTree} to be set.
  #  */
  # protected void requireGitDirOrWorkTree() {
  #   if (getGitDir() == null && getWorkTree() == null)
  #     throw new IllegalArgumentException(
  #         JGitText.get().eitherGitDirOrWorkTreeRequired);
  # }
  #
  # /**
  #  * Perform standard gitDir initialization.
  #  *
  #  * @throws java.io.IOException
  #  *             the repository could not be accessed
  #  */
  # protected void setupGitDir() throws IOException {
  #   // No gitDir? Try to assume its under the workTree or a ref to another
  #   // location
  #   if (getGitDir() == null && getWorkTree() != null) {
  #     File dotGit = new File(getWorkTree(), DOT_GIT);
  #     if (!dotGit.isFile())
  #       setGitDir(dotGit);
  #     else
  #       setGitDir(getSymRef(getWorkTree(), dotGit, safeFS()));
  #   }
  # }
  #
  # /**
  #  * Perform standard work-tree initialization.
  #  * <p>
  #  * This is a method typically invoked inside of {@link #setup()}, near the
  #  * end after the repository has been identified and its configuration is
  #  * available for inspection.
  #  *
  #  * @throws java.io.IOException
  #  *             the repository configuration could not be read.
  #  */
  # protected void setupWorkTree() throws IOException {
  #   if (getFS() == null)
  #     setFS(FS.DETECTED);
  #
  #   // If we aren't bare, we should have a work tree.
  #   //
  #   if (!isBare() && getWorkTree() == null)
  #     setWorkTree(guessWorkTreeOrFail());
  #
  #   if (!isBare()) {
  #     // If after guessing we're still not bare, we must have
  #     // a metadata directory to hold the repository. Assume
  #     // its at the work tree.
  #     //
  #     if (getGitDir() == null)
  #       setGitDir(getWorkTree().getParentFile());
  #     if (getIndexFile() == null)
  #       setIndexFile(new File(getGitDir(), "index")); //$NON-NLS-1$
  #   }
  # }
  #
  # /**
  #  * Configure the internal implementation details of the repository.
  #  *
  #  * @throws java.io.IOException
  #  *             the repository could not be accessed
  #  */
  # protected void setupInternals() throws IOException {
  #   if (getObjectDirectory() == null && getGitDir() != null)
  #     setObjectDirectory(safeFS().resolve(getGitDir(), "objects")); //$NON-NLS-1$
  # }
  #
  # /**
  #  * Get the cached repository configuration, loading if not yet available.
  #  *
  #  * @return the configuration of the repository.
  #  * @throws java.io.IOException
  #  *             the configuration is not available, or is badly formed.
  #  */
  # protected Config getConfig() throws IOException {
  #   if (config == null)
  #     config = loadConfig();
  #   return config;
  # }
  #
  # /**
  #  * Parse and load the repository specific configuration.
  #  * <p>
  #  * The default implementation reads {@code gitDir/config}, or returns an
  #  * empty configuration if gitDir was not set.
  #  *
  #  * @return the repository's configuration.
  #  * @throws java.io.IOException
  #  *             the configuration is not available.
  #  */
  # protected Config loadConfig() throws IOException {
  #   if (getGitDir() != null) {
  #     // We only want the repository's configuration file, and not
  #     // the user file, as these parameters must be unique to this
  #     // repository and not inherited from other files.
  #     //
  #     File path = safeFS().resolve(getGitDir(), Constants.CONFIG);
  #     FileBasedConfig cfg = new FileBasedConfig(path, safeFS());
  #     try {
  #       cfg.load();
  #     } catch (ConfigInvalidException err) {
  #       throw new IllegalArgumentException(MessageFormat.format(
  #           JGitText.get().repositoryConfigFileInvalid, path
  #               .getAbsolutePath(), err.getMessage()));
  #     }
  #     return cfg;
  #   } else {
  #     return new Config();
  #   }
  # }
  #
  # private File guessWorkTreeOrFail() throws IOException {
  #   final Config cfg = getConfig();
  #
  #   // If set, core.worktree wins.
  #   //
  #   String path = cfg.getString(CONFIG_CORE_SECTION, null,
  #       CONFIG_KEY_WORKTREE);
  #   if (path != null)
  #     return safeFS().resolve(getGitDir(), path).getCanonicalFile();
  #
  #   // If core.bare is set, honor its value. Assume workTree is
  #   // the parent directory of the repository.
  #   //
  #   if (cfg.getString(CONFIG_CORE_SECTION, null, CONFIG_KEY_BARE) != null) {
  #     if (cfg.getBoolean(CONFIG_CORE_SECTION, CONFIG_KEY_BARE, true)) {
  #       setBare();
  #       return null;
  #     }
  #     return getGitDir().getParentFile();
  #   }
  #
  #   if (getGitDir().getName().equals(DOT_GIT)) {
  #     // No value for the "bare" flag, but gitDir is named ".git",
  #     // use the parent of the directory
  #     //
  #     return getGitDir().getParentFile();
  #   }
  #
  #   // We have to assume we are bare.
  #   //
  #   setBare();
  #   return null;
  # }
  #

  @doc ~S"""
  blah blah blah
  """
  @callback handle_blah(foo :: term) :: term

  @doc false
  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Xgit.Lib.BaseRepositoryBuilder

      def foo(bar), do: :blah
      defoverridable foo: 1
    end
  end
end
