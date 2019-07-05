# Copyright (C) 2007, Dave Watson <dwatson@mimvista.com>
# Copyright (C) 2008-2010, Google Inc.
# Copyright (C) 2006-2010, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/FileRepository.java
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

defmodule Xgit.Storage.File.FileRepository do
  @moduledoc ~S"""
  Implements `Xgit.Lib.Repository` for an on-disk (local) file-based repositority.

  Use `Xgit.Storage.File.FileRepositoryBuilder` to describe the repository with
  the desired options and then call `start_link/3` to spawn the respository process.

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

  This implementation only handles a subtly undocumented subset of git features.
  """

  # The `state` value for this module is a map containing:
  # * `system_reader`: The `SystemReader` instance used by this repository.
  #   (Typically `nil`; sometimes used for testing.)
  # * `git_dir`: The `.git` directory storing the repository metadata.
  # * `object_dir`: The directory storing the repository's objects.
  # * `alternate_object_directories`: List of alternate object directories to search.
  # * `bare?`: True only if the caller wants to force bare behavior.
  # * `must_exist?`: True if the caller requires the repository to exist.
  # * `work_tree`: The top level directory of the working files.
  # * `index_file`: The local index file that is caching checked out file status.
  # * `ceiling_directories`: A list of directories limiting the search for a git repository.

  use Xgit.Lib.Repository

  alias Xgit.Storage.File.Internal.ObjectDirectory
  alias Xgit.Storage.File.Internal.RefDirectory
  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants
  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectDatabase
  alias Xgit.Lib.RefDatabase
  alias Xgit.Lib.RefDatabase
  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Util.StringUtils
  alias Xgit.Util.SystemReader

  @doc ~S"""
  Start an on-disk git repository.

  ## Parameters

  `builder` should be a `FileRepositoryBuilder` which has been fully configured
  (typically by calling `FileRepositoryBuilder.setup!/1`.

  ## Options

  * `:system_reader`: An `Xgit.Lib.SystemReader` struct which will overrides
    default system behavior (mostly used for testing).

  Any other options are passed through to `GenServer.start_link/3`.

  ## Return Value

  See `GenServer.start_link/3`.

  Use the functions in `Xgit.Lib.Repository` to interact with this repository process.
  """
  @spec start_link(builder :: FileRepositoryBuilder.t(), opts :: Keyword.t()) ::
          GenServer.on_start()
  def start_link(%FileRepositoryBuilder{} = builder, opts \\ []),
    do: Repository.start_link(__MODULE__, {builder, opts}, opts)

  # actually called by Xgit.Lib.Repository.init/1
  @impl true
  def init(
        {%FileRepositoryBuilder{
           git_dir: git_dir,
           object_dir: object_dir,
           alternate_object_directories: alternate_object_directories,
           bare?: bare?,
           must_exist?: must_exist?,
           work_tree: work_tree,
           index_file: index_file,
           ceiling_directories: ceiling_directories
         }, opts}
      )
      when is_list(opts) do
    system_reader = Keyword.get(opts, :system_reader)

    system_config =
      system_reader
      |> open_system_config()
      |> load_config()

    user_config =
      system_reader
      |> SystemReader.user_config(system_config)
      |> load_config()

    repo_config =
      git_dir
      |> Path.join(Constants.config())
      |> FileBasedConfig.config_for_path()
      |> load_config()

    # TO DO: Shouldn't this fall back to user_config?
    # https://github.com/elixir-git/xgit/issues/139

    # repoConfig.addChangeListener(new ConfigChangedListener() {
    #   @Override
    #   public void onConfigChanged(ConfigChangedEvent event) {
    #     fireEvent(event);
    #   }
    # });

    repository_format_version =
      Config.get_int(
        repo_config,
        ConfigConstants.config_core_section(),
        ConfigConstants.config_key_repo_format_version(),
        0
      )

    reftype =
      repo_config
      |> Config.get_string("extensions", "refStorage")
      |> downcase_if_not_nil()

    {:ok, ref_database_pid} =
      cond do
        repository_format_version >= 1 and reftype == "reftree" ->
          raise ArgumentError, "RefTreeDatabase not yet implemented"

        # new RefTreeDatabase(this, new RefDirectory(this));

        repository_format_version >= 1 ->
          raise ArgumentError, "Unknown repository format"

        true ->
          RefDirectory.start_link(git_dir)
      end

    {:ok, object_database_pid} =
      ObjectDirectory.start_link(config: Config.new(), objects: object_dir)

    # TO DO: Pass additional options (repoConfig, alternateObjectDirectories, Constants.SHALLOW)
    # through to ObjectDirectory. https://github.com/elixir-git/xgit/issues/139

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

    {:ok,
     %{
       system_reader: system_reader,
       git_dir: git_dir,
       ref_database: ref_database_pid,
       object_database: object_database_pid,
       alternate_object_directories: alternate_object_directories,
       bare?: bare?,
       must_exist?: must_exist?,
       work_tree: work_tree,
       index_file: index_file,
       ceiling_directories: ceiling_directories,
       system_config: system_config,
       user_config: user_config,
       repo_config: repo_config
     }}
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

  defp load_config(config) when not is_nil(config) do
    Config.load(config)
    config
  end

  defp downcase_if_not_nil(nil), do: nil
  defp downcase_if_not_nil(s), do: String.downcase(s)

  # TO DO: https://github.com/elixir-git/xgit/issues/139

  # private static final String UNNAMED = "Unnamed repository; edit this file to name it for gitweb."; //$NON-NLS-1$
  #
  # private final Object snapshotLock = new Object();
  #
  # // protected by snapshotLock
  # private FileSnapshot snapshot;

  # /** {@inheritDoc} */
  # @Override
  # public RefDatabase getRefDatabase() {
  #   return refs;
  # }

  # @doc false
  @impl true
  def handle_create(
        %{
          git_dir: git_dir,
          ref_database: ref_database_pid,
          object_database: object_database_pid,
          repo_config: %{storage: %{path: repo_config_path}}
        } = state,
        options
      )
      when is_list(options) do
    if File.exists?(repo_config_path) do
      raise RuntimeError, "Repository already exists: #{git_dir}"
    end

    File.mkdir_p!(git_dir)

    # WINDOWS PORTING NOTE: Skipping this for now since there isn't really a
    # distinct "hidden" attribute for files on most Posix file systems.
    # HideDotFiles hideDotFiles = getConfig().getEnum(
    #     ConfigConstants.CONFIG_CORE_SECTION, null,
    #     ConfigConstants.CONFIG_KEY_HIDEDOTFILES,
    #     HideDotFiles.DOTGITONLY);
    # if (hideDotFiles != HideDotFiles.FALSE && !isBare()
    #     && getDirectory().getName().startsWith(".")) //$NON-NLS-1$
    #   getFS().setHidden(getDirectory(), true);

    RefDatabase.create!(ref_database_pid)
    ObjectDatabase.create!(object_database_pid)

    File.mkdir_p!(Path.join(git_dir, "branches"))
    File.mkdir_p!(Path.join(git_dir, "hooks"))

    # TEMPORARY / BOOTSTRAPPING: Remove the File.write! and replace with the
    # RefUpdate code below. Porting RefUpdate draws in a few too many things just yet.
    File.write!(Path.join(git_dir, "HEAD"), "ref: refs/heads/master")

    # TO DO: https://github.com/elixir-git/xgit/issues/139

    # RefUpdate head = updateRef(Constants.HEAD);
    # head.disableRefLog();
    # head.link(Constants.R_HEADS + Constants.MASTER);
    # --- end replacement for File.write!

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

    {:ok, state}
  end

  @impl true
  def handle_git_dir(%{git_dir: git_dir} = state), do: {:ok, git_dir, state}

  @impl true
  def handle_bare?(%{bare?: bare?} = state), do: {:ok, bare?, state}

  @impl true
  def handle_work_tree(%{work_tree: work_tree} = state), do: {:ok, work_tree, state}

  @impl true
  def handle_index_file(%{index_file: index_file} = state), do: {:ok, index_file, state}

  @impl true
  def handle_object_database(%{object_database: object_database} = state),
    do: {:ok, object_database, state}

  @impl true
  def handle_config(%{repo_config: repo_config} = state),
    do: {:ok, repo_config, state}

  # TO DO: Should this call through to update_config?
  # https://github.com/elixir-git/xgit/issues/139

  # defp update_config(%{repo_config: repo_config}) do
  #   # TO DO: Port the part that updates the configs if needed.
  #   # Trick will be managing the snapshot currently in FileBasedConfig.
  #   # Punting on that for now.
  #
  #   # if (systemConfig.isOutdated()) {
  #   #   try {
  #   #     loadSystemConfig();
  #   #   } catch (IOException e) {
  #   #     throw new RuntimeException(e);
  #   #   }
  #   # }
  #   # if (userConfig.isOutdated()) {
  #   #   try {
  #   #     loadUserConfig();
  #   #   } catch (IOException e) {
  #   #     throw new RuntimeException(e);
  #   #   }
  #   # }
  #   # if (repoConfig.isOutdated()) {
  #   #     try {
  #   #       loadRepoConfig();
  #   #     } catch (IOException e) {
  #   #       throw new RuntimeException(e);
  #   #     }
  #   # }
  #
  #   repo_config
  # end

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
