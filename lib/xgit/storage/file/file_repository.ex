defmodule Xgit.Storage.File.FileRepository do
  @moduledoc ~S"""
   Represents a git repository.

   A repository holds all objects and refs used for managing source code (could be
   any type of file, but source code is what SCMs are typically used for).

   In git terms all data is stored in `GIT_DIR`, typically a directory called
   `.git`. A work tree is maintained unless the repository is a bare repository.
   Typically the `.git` directory is located at the root of the work dir.

   * `GIT_DIR`
     * `objects/`
     * `refs/` - tags and heads
     * `config` - configuration
     * `info/` - more configurations

  This class is thread-safe.

  This implementation only handles a subtly undocumented subset of git features.

  Struct members:
  * `system_reader`: The `SystemReader` instance used by this repository.
    (Typically `nil`; sometimes used for testing.)
  * `git_dir`: The `.git` directory storing the repository metadata.
  * `object_dir`: The directory storing the repository's objects.
  * `alternate_object_directories`: List of alternate object directories to search.
  * `bare?`: True only if the caller wants to force bare behavior.
  * `must_exist?`: True if the caller requires the repository to exist.
  * `work_tree`: The top level directory of the working files.
  * `index_file`: The local index file that is caching checked out file status.
  * `ceiling_directories`: A list of directories limiting the search for a Git repository.
  """

  defstruct system_reader: nil,
            git_dir: nil,
            object_dir: nil,
            # alternate_object_directories: nil,
            bare?: false,
            # must_exist?: false,
            work_tree: nil,
            index_file: nil,
            # ceiling_directories: nil
            system_config: nil,
            user_config: nil,
            repo_config: nil

  alias Xgit.Lib.Config
  alias Xgit.Lib.Constants
  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Util.StringUtils
  alias Xgit.Util.SystemReader

  # private static final String UNNAMED = "Unnamed repository; edit this file to name it for gitweb."; //$NON-NLS-1$
  #
  # private final RefDatabase refs;
  # private final ObjectDirectory objectDatabase;
  #
  # private final Object snapshotLock = new Object();
  #
  # // protected by snapshotLock
  # private FileSnapshot snapshot;

  @doc ~S"""
  Construct a representation of a git repository.

  The work tree, object directory, alternate object directories and index
  file locations are deduced from the given git directory and the default
  rules by running `FileRepositoryBuilder`.

  Options:
  * `system_reader`: Override the default `SystemReader` instance. (Used mostly for testing.)

  Returns an instance of `FileRepository`.
  """
  def from_git_dir!(git_dir, options \\ []) when is_binary(git_dir) and is_list(options) do
    %FileRepositoryBuilder{git_dir: git_dir}
    |> FileRepositoryBuilder.setup!()
    |> build!(options)
  end

  @doc ~S"""
  Create a repository from the specification of a `FileRepositoryBuilder`.
  """
  def build!(
        %FileRepositoryBuilder{
          git_dir: git_dir,
          work_tree: work_tree,
          index_file: index_file
        },
        options \\ []
      ) do
    system_reader = Keyword.get(options, :system_reader)

    system_config = open_system_config(system_reader) |> load_config()
    user_config = SystemReader.user_config(system_reader, system_config) |> load_config()

    repo_config =
      FileBasedConfig.config_for_path(Path.join(git_dir, Constants.config())) |> load_config()

    # repoConfig.addChangeListener(new ConfigChangedListener() {
    #   @Override
    #   public void onConfigChanged(ConfigChangedEvent event) {
    #     fireEvent(event);
    #   }
    # });
    #
    # final long repositoryFormatVersion = getConfig().getLong(
    #     ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_REPO_FORMAT_VERSION, 0);
    #
    # String reftype = repoConfig.getString(
    #     "extensions", null, "refStorage"); //$NON-NLS-1$ //$NON-NLS-2$
    # if (repositoryFormatVersion >= 1 && reftype != null) {
    #   if (StringUtils.equalsIgnoreCase(reftype, "reftree")) { //$NON-NLS-1$
    #     refs = new RefTreeDatabase(this, new RefDirectory(this));
    #   } else {
    #     throw new IOException(JGitText.get().unknownRepositoryFormat);
    #   }
    # } else {
    #   refs = new RefDirectory(this);
    # }
    #
    # objectDatabase = new ObjectDirectory(repoConfig, //
    #     options.getObjectDirectory(), //
    #     options.getAlternateObjectDirectories(), //
    #     getFS(), //
    #     new File(getDirectory(), Constants.SHALLOW));
    #
    # if (objectDatabase.exists()) {
    #   if (repositoryFormatVersion > 1)
    #     throw new IOException(MessageFormat.format(
    #         JGitText.get().unknownRepositoryFormat2,
    #         Long.valueOf(repositoryFormatVersion)));
    # }
    #
    # if (!isBare()) {
    #   snapshot = FileSnapshot.save(getIndexFile());
    # }

    %__MODULE__{
      git_dir: git_dir,
      work_tree: work_tree,
      index_file: index_file,
      system_config: system_config,
      user_config: user_config,
      repo_config: repo_config
    }
  end

  defp open_system_config(system_reader) do
    bypass_system_config? =
      system_reader
      |> SystemReader.get_env(Constants.git_config_nosystem_key())
      |> StringUtils.empty_or_nil?()

    if bypass_system_config?,
      do: SystemReader.system_config(system_reader, nil),
      else: Config.new()
  end

  defp load_config(%Config{storage: nil} = config), do: config
  defp load_config(config), do: Config.load(config)

  # /**
  #  * Get the directory containing the objects owned by this repository
  #  *
  #  * @return the directory containing the objects owned by this repository.
  #  */
  # public File getObjectsDirectory() {
  #   return objectDatabase.getDirectory();
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public ObjectDirectory getObjectDatabase() {
  #   return objectDatabase;
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public RefDatabase getRefDatabase() {
  #   return refs;
  # }

  def config(%__MODULE__{}) do
    # /** {@inheritDoc} */
    # @Override
    # public FileBasedConfig getConfig() {
    #   if (systemConfig.isOutdated()) {
    #     try {
    #       loadSystemConfig();
    #     } catch (IOException e) {
    #       throw new RuntimeException(e);
    #     }
    #   }
    #   if (userConfig.isOutdated()) {
    #     try {
    #       loadUserConfig();
    #     } catch (IOException e) {
    #       throw new RuntimeException(e);
    #     }
    #   }
    #   if (repoConfig.isOutdated()) {
    #       try {
    #         loadRepoConfig();
    #       } catch (IOException e) {
    #         throw new RuntimeException(e);
    #       }
    #   }
    #   return repoConfig;
    # }
  end

  #
  # /** {@inheritDoc} */
  # @Override
  # @Nullable
  # public String getGitwebDescription() throws IOException {
  #   String d;
  #   try {
  #     d = RawParseUtils.decode(IO.readFully(descriptionFile()));
  #   } catch (FileNotFoundException err) {
  #     return null;
  #   }
  #   if (d != null) {
  #     d = d.trim();
  #     if (d.isEmpty() || UNNAMED.equals(d)) {
  #       return null;
  #     }
  #   }
  #   return d;
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public void setGitwebDescription(@Nullable String description)
  #     throws IOException {
  #   String old = getGitwebDescription();
  #   if (Objects.equals(old, description)) {
  #     return;
  #   }
  #
  #   File path = descriptionFile();
  #   LockFile lock = new LockFile(path);
  #   if (!lock.lock()) {
  #     throw new IOException(MessageFormat.format(JGitText.get().lockError,
  #         path.getAbsolutePath()));
  #   }
  #   try {
  #     String d = description;
  #     if (d != null) {
  #       d = d.trim();
  #       if (!d.isEmpty()) {
  #         d += '\n';
  #       }
  #     } else {
  #       d = ""; //$NON-NLS-1$
  #     }
  #     lock.write(Constants.encode(d));
  #     lock.commit();
  #   } finally {
  #     lock.unlock();
  #   }
  # }
  #
  # private File descriptionFile() {
  #   return new File(getDirectory(), "description"); //$NON-NLS-1$
  # }
  #
  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Objects known to exist but not expressed by {@code #getAllRefs()}.
  #  * <p>
  #  * When a repository borrows objects from another repository, it can
  #  * advertise that it safely has that other repository's references, without
  #  * exposing any other details about the other repository. This may help a
  #  * client trying to push changes avoid pushing more than it needs to.
  #  */
  # @Override
  # public Set<ObjectId> getAdditionalHaves() {
  #   return getAdditionalHaves(null);
  # }
  #
  # /**
  #  * Objects known to exist but not expressed by {@code #getAllRefs()}.
  #  * <p>
  #  * When a repository borrows objects from another repository, it can
  #  * advertise that it safely has that other repository's references, without
  #  * exposing any other details about the other repository. This may help a
  #  * client trying to push changes avoid pushing more than it needs to.
  #  *
  #  * @param skips
  #  *            Set of AlternateHandle Ids already seen
  #  *
  #  * @return unmodifiable collection of other known objects.
  #  */
  # private Set<ObjectId> getAdditionalHaves(Set<AlternateHandle.Id> skips) {
  #   HashSet<ObjectId> r = new HashSet<>();
  #   skips = objectDatabase.addMe(skips);
  #   for (AlternateHandle d : objectDatabase.myAlternates()) {
  #     if (d instanceof AlternateRepository && !skips.contains(d.getId())) {
  #       FileRepository repo;
  #
  #       repo = ((AlternateRepository) d).repository;
  #       for (Ref ref : repo.getAllRefs().values()) {
  #         if (ref.getObjectId() != null)
  #           r.add(ref.getObjectId());
  #         if (ref.getPeeledObjectId() != null)
  #           r.add(ref.getPeeledObjectId());
  #       }
  #       r.addAll(repo.getAdditionalHaves(skips));
  #     }
  #   }
  #   return r;
  # }
  #
  # /**
  #  * Add a single existing pack to the list of available pack files.
  #  *
  #  * @param pack
  #  *            path of the pack file to open.
  #  * @throws java.io.IOException
  #  *             index file could not be opened, read, or is not recognized as
  #  *             a Git pack file index.
  #  */
  # public void openPack(File pack) throws IOException {
  #   objectDatabase.openPack(pack);
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public void scanForRepoChanges() throws IOException {
  #   getRefDatabase().getRefs(); // This will look for changes to refs
  #   detectIndexChanges();
  # }
  #
  # /** Detect index changes. */
  # private void detectIndexChanges() {
  #   if (isBare()) {
  #     return;
  #   }
  #
  #   File indexFile = getIndexFile();
  #   synchronized (snapshotLock) {
  #     if (snapshot == null) {
  #       snapshot = FileSnapshot.save(indexFile);
  #       return;
  #     }
  #     if (!snapshot.isModified(indexFile)) {
  #       return;
  #     }
  #   }
  #   notifyIndexChanged(false);
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public void notifyIndexChanged(boolean internal) {
  #   synchronized (snapshotLock) {
  #     snapshot = FileSnapshot.save(getIndexFile());
  #   }
  #   fireEvent(new IndexChangedEvent(internal));
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public ReflogReader getReflogReader(String refName) throws IOException {
  #   Ref ref = findRef(refName);
  #   if (ref != null)
  #     return new ReflogReaderImpl(this, ref.getName());
  #   return null;
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public AttributesNodeProvider createAttributesNodeProvider() {
  #   return new AttributesNodeProviderImpl(this);
  # }
  #
  # /**
  #  * Implementation a {@link AttributesNodeProvider} for a
  #  * {@link FileRepository}.
  #  *
  #  * @author <a href="mailto:arthur.daussy@obeo.fr">Arthur Daussy</a>
  #  *
  #  */
  # static class AttributesNodeProviderImpl implements
  #     AttributesNodeProvider {
  #
  #   private AttributesNode infoAttributesNode;
  #
  #   private AttributesNode globalAttributesNode;
  #
  #   /**
  #    * Constructor.
  #    *
  #    * @param repo
  #    *            {@link Repository} that will provide the attribute nodes.
  #    */
  #   protected AttributesNodeProviderImpl(Repository repo) {
  #     infoAttributesNode = new InfoAttributesNode(repo);
  #     globalAttributesNode = new GlobalAttributesNode(repo);
  #   }
  #
  #   @Override
  #   public AttributesNode getInfoAttributesNode() throws IOException {
  #     if (infoAttributesNode instanceof InfoAttributesNode)
  #       infoAttributesNode = ((InfoAttributesNode) infoAttributesNode)
  #           .load();
  #     return infoAttributesNode;
  #   }
  #
  #   @Override
  #   public AttributesNode getGlobalAttributesNode() throws IOException {
  #     if (globalAttributesNode instanceof GlobalAttributesNode)
  #       globalAttributesNode = ((GlobalAttributesNode) globalAttributesNode)
  #           .load();
  #     return globalAttributesNode;
  #   }
  #
  #   static void loadRulesFromFile(AttributesNode r, File attrs)
  #       throws FileNotFoundException, IOException {
  #     if (attrs.exists()) {
  #       try (FileInputStream in = new FileInputStream(attrs)) {
  #         r.parse(in);
  #       }
  #     }
  #   }
  #
  # }
  #
  # private boolean shouldAutoDetach() {
  #   return getConfig().getBoolean(ConfigConstants.CONFIG_GC_SECTION,
  #       ConfigConstants.CONFIG_KEY_AUTODETACH, true);
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public void autoGC(ProgressMonitor monitor) {
  #   GC gc = new GC(this);
  #   gc.setPackConfig(new PackConfig(this));
  #   gc.setProgressMonitor(monitor);
  #   gc.setAuto(true);
  #   gc.setBackground(shouldAutoDetach());
  #   try {
  #     gc.gc();
  #   } catch (ParseException | IOException e) {
  #     throw new JGitInternalException(JGitText.get().gcFailed, e);
  #   }
  # }
end

defimpl Xgit.Lib.Repository.Strategy, for: Xgit.Storage.File.FileRepository do
  alias Xgit.Storage.File.FileRepository

  def create!(%FileRepository{}, options) when is_list(options) do
    raise "create! not yet implemented for FileRepository"
    # final FileBasedConfig cfg = getConfig();
    # if (cfg.getFile().exists()) {
    #   throw new IllegalStateException(MessageFormat.format(
    #       JGitText.get().repositoryAlreadyExists, getDirectory()));
    # }
    # FileUtils.mkdirs(getDirectory(), true);
    # HideDotFiles hideDotFiles = getConfig().getEnum(
    #     ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_HIDEDOTFILES,
    #     HideDotFiles.DOTGITONLY);
    # if (hideDotFiles != HideDotFiles.FALSE && !isBare()
    #     && getDirectory().getName().startsWith(".")) //$NON-NLS-1$
    #   getFS().setHidden(getDirectory(), true);
    # refs.create();
    # objectDatabase.create();
    #
    # FileUtils.mkdir(new File(getDirectory(), "branches")); //$NON-NLS-1$
    # FileUtils.mkdir(new File(getDirectory(), "hooks")); //$NON-NLS-1$
    #
    # RefUpdate head = updateRef(Constants.HEAD);
    # head.disableRefLog();
    # head.link(Constants.R_HEADS + Constants.MASTER);
    #
    # final boolean fileMode;
    # if (getFS().supportsExecute()) {
    #   File tmp = File.createTempFile("try", "execute", getDirectory()); //$NON-NLS-1$ //$NON-NLS-2$
    #
    #   getFS().setExecute(tmp, true);
    #   final boolean on = getFS().canExecute(tmp);
    #
    #   getFS().setExecute(tmp, false);
    #   final boolean off = getFS().canExecute(tmp);
    #   FileUtils.delete(tmp);
    #
    #   fileMode = on && !off;
    # } else {
    #   fileMode = false;
    # }
    #
    # SymLinks symLinks = SymLinks.FALSE;
    # if (getFS().supportsSymlinks()) {
    #   File tmp = new File(getDirectory(), "tmplink"); //$NON-NLS-1$
    #   try {
    #     getFS().createSymLink(tmp, "target"); //$NON-NLS-1$
    #     symLinks = null;
    #     FileUtils.delete(tmp);
    #   } catch (IOException e) {
    #     // Normally a java.nio.file.FileSystemException
    #   }
    # }
    # if (symLinks != null)
    #   cfg.setString(ConfigConstants.CONFIG_CORE_SECTION, null,
    #       ConfigConstants.CONFIG_KEY_SYMLINKS, symLinks.name()
    #           .toLowerCase(Locale.ROOT));
    # cfg.setInt(ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_REPO_FORMAT_VERSION, 0);
    # cfg.setBoolean(ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_FILEMODE, fileMode);
    # if (bare)
    #   cfg.setBoolean(ConfigConstants.CONFIG_CORE_SECTION, null,
    #       ConfigConstants.CONFIG_KEY_BARE, true);
    # cfg.setBoolean(ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_LOGALLREFUPDATES, !bare);
    # if (SystemReader.getInstance().isMacOS())
    #   // Java has no other way
    #   cfg.setBoolean(ConfigConstants.CONFIG_CORE_SECTION, null,
    #       ConfigConstants.CONFIG_KEY_PRECOMPOSEUNICODE, true);
    # if (!bare) {
    #   File workTree = getWorkTree();
    #   if (!getDirectory().getParentFile().equals(workTree)) {
    #     cfg.setString(ConfigConstants.CONFIG_CORE_SECTION, null,
    #         ConfigConstants.CONFIG_KEY_WORKTREE, getWorkTree()
    #             .getAbsolutePath());
    #     LockFile dotGitLockFile = new LockFile(new File(workTree,
    #         Constants.DOT_GIT));
    #     try {
    #       if (dotGitLockFile.lock()) {
    #         dotGitLockFile.write(Constants.encode(Constants.GITDIR
    #             + getDirectory().getAbsolutePath()));
    #         dotGitLockFile.commit();
    #       }
    #     } finally {
    #       dotGitLockFile.unlock();
    #     }
    #   }
    # }
    # cfg.save();
  end

  defdelegate config(repository), to: FileRepository
end
