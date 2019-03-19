defmodule Xgit.Lib.RepositoryCache do
  @moduledoc false
  # MOSTLY UNIMPLEMENTED FOR NOW
  # /**
  #  * Cache of active {@link org.eclipse.jgit.lib.Repository} instances.
  #  */
  # private final static Logger LOG = LoggerFactory
  #     .getLogger(RepositoryCache.class);
  #
  # private static final RepositoryCache cache = new RepositoryCache();
  #
  # /**
  #  * Open an existing repository, reusing a cached instance if possible.
  #  * <p>
  #  * When done with the repository, the caller must call
  #  * {@link org.eclipse.jgit.lib.Repository#close()} to decrement the
  #  * repository's usage counter.
  #  *
  #  * @param location
  #  *            where the local repository is. Typically a
  #  *            {@link org.eclipse.jgit.lib.RepositoryCache.FileKey}.
  #  * @return the repository instance requested; caller must close when done.
  #  * @throws java.io.IOException
  #  *             the repository could not be read (likely its core.version
  #  *             property is not supported).
  #  * @throws org.eclipse.jgit.errors.RepositoryNotFoundException
  #  *             there is no repository at the given location.
  #  */
  # public static Repository open(Key location) throws IOException,
  #     RepositoryNotFoundException {
  #   return open(location, true);
  # }
  #
  # /**
  #  * Open a repository, reusing a cached instance if possible.
  #  * <p>
  #  * When done with the repository, the caller must call
  #  * {@link org.eclipse.jgit.lib.Repository#close()} to decrement the
  #  * repository's usage counter.
  #  *
  #  * @param location
  #  *            where the local repository is. Typically a
  #  *            {@link org.eclipse.jgit.lib.RepositoryCache.FileKey}.
  #  * @param mustExist
  #  *            If true, and the repository is not found, throws {@code
  #  *            RepositoryNotFoundException}. If false, a repository instance
  #  *            is created and registered anyway.
  #  * @return the repository instance requested; caller must close when done.
  #  * @throws java.io.IOException
  #  *             the repository could not be read (likely its core.version
  #  *             property is not supported).
  #  * @throws RepositoryNotFoundException
  #  *             There is no repository at the given location, only thrown if
  #  *             {@code mustExist} is true.
  #  */
  # public static Repository open(Key location, boolean mustExist)
  #     throws IOException {
  #   return cache.openRepository(location, mustExist);
  # }
  #
  # /**
  #  * Register one repository into the cache.
  #  * <p>
  #  * During registration the cache automatically increments the usage counter,
  #  * permitting it to retain the reference. A
  #  * {@link org.eclipse.jgit.lib.RepositoryCache.FileKey} for the repository's
  #  * {@link org.eclipse.jgit.lib.Repository#getDirectory()} is used to index
  #  * the repository in the cache.
  #  * <p>
  #  * If another repository already is registered in the cache at this
  #  * location, the other instance is closed.
  #  *
  #  * @param db
  #  *            repository to register.
  #  */
  # public static void register(Repository db) {
  #   if (db.getDirectory() != null) {
  #     FileKey key = FileKey.exact(db.getDirectory(), db.getFS());
  #     cache.registerRepository(key, db);
  #   }
  # }
  #
  # /**
  #  * Close and remove a repository from the cache.
  #  * <p>
  #  * Removes a repository from the cache, if it is still registered here, and
  #  * close it.
  #  *
  #  * @param db
  #  *            repository to unregister.
  #  */
  # public static void close(@NonNull Repository db) {
  #   if (db.getDirectory() != null) {
  #     FileKey key = FileKey.exact(db.getDirectory(), db.getFS());
  #     cache.unregisterAndCloseRepository(key);
  #   }
  # }
  #
  # /**
  #  * Remove a repository from the cache.
  #  * <p>
  #  * Removes a repository from the cache, if it is still registered here. This
  #  * method will not close the repository, only remove it from the cache. See
  #  * {@link org.eclipse.jgit.lib.RepositoryCache#close(Repository)} to remove
  #  * and close the repository.
  #  *
  #  * @param db
  #  *            repository to unregister.
  #  * @since 4.3
  #  */
  # public static void unregister(Repository db) {
  #   if (db.getDirectory() != null) {
  #     unregister(FileKey.exact(db.getDirectory(), db.getFS()));
  #   }
  # }
  #
  # /**
  #  * Remove a repository from the cache.
  #  * <p>
  #  * Removes a repository from the cache, if it is still registered here. This
  #  * method will not close the repository, only remove it from the cache. See
  #  * {@link org.eclipse.jgit.lib.RepositoryCache#close(Repository)} to remove
  #  * and close the repository.
  #  *
  #  * @param location
  #  *            location of the repository to remove.
  #  * @since 4.1
  #  */
  # public static void unregister(Key location) {
  #   cache.unregisterRepository(location);
  # }
  #
  # /**
  #  * Get the locations of all repositories registered in the cache.
  #  *
  #  * @return the locations of all repositories registered in the cache.
  #  * @since 4.1
  #  */
  # public static Collection<Key> getRegisteredKeys() {
  #   return cache.getKeys();
  # }
  #
  # static boolean isCached(@NonNull Repository repo) {
  #   File gitDir = repo.getDirectory();
  #   if (gitDir == null) {
  #     return false;
  #   }
  #   FileKey key = new FileKey(gitDir, repo.getFS());
  #   return cache.cacheMap.get(key) == repo;
  # }
  #
  # /**
  #  * Unregister all repositories from the cache.
  #  */
  # public static void clear() {
  #   cache.clearAll();
  # }
  #
  # static void clearExpired() {
  #   cache.clearAllExpired();
  # }
  #
  # static void reconfigure(RepositoryCacheConfig repositoryCacheConfig) {
  #   cache.configureEviction(repositoryCacheConfig);
  # }
  #
  # private final ConcurrentHashMap<Key, Repository> cacheMap;
  #
  # private final Lock[] openLocks;
  #
  # private ScheduledFuture<?> cleanupTask;
  #
  # private volatile long expireAfter;
  #
  # private RepositoryCache() {
  #   cacheMap = new ConcurrentHashMap<>();
  #   openLocks = new Lock[4];
  #   for (int i = 0; i < openLocks.length; i++) {
  #     openLocks[i] = new Lock();
  #   }
  #   configureEviction(new RepositoryCacheConfig());
  # }
  #
  # private void configureEviction(
  #     RepositoryCacheConfig repositoryCacheConfig) {
  #   expireAfter = repositoryCacheConfig.getExpireAfter();
  #   ScheduledThreadPoolExecutor scheduler = WorkQueue.getExecutor();
  #   synchronized (scheduler) {
  #     if (cleanupTask != null) {
  #       cleanupTask.cancel(false);
  #     }
  #     long delay = repositoryCacheConfig.getCleanupDelay();
  #     if (delay == RepositoryCacheConfig.NO_CLEANUP) {
  #       return;
  #     }
  #     cleanupTask = scheduler.scheduleWithFixedDelay(new Runnable() {
  #       @Override
  #       public void run() {
  #         try {
  #           cache.clearAllExpired();
  #         } catch (Throwable e) {
  #           LOG.error(e.getMessage(), e);
  #         }
  #       }
  #     }, delay, delay, TimeUnit.MILLISECONDS);
  #   }
  # }
  #
  # private Repository openRepository(final Key location,
  #     final boolean mustExist) throws IOException {
  #   Repository db = cacheMap.get(location);
  #   if (db == null) {
  #     synchronized (lockFor(location)) {
  #       db = cacheMap.get(location);
  #       if (db == null) {
  #         db = location.open(mustExist);
  #         cacheMap.put(location, db);
  #       } else {
  #         db.incrementOpen();
  #       }
  #     }
  #   } else {
  #     db.incrementOpen();
  #   }
  #   return db;
  # }
  #
  # private void registerRepository(Key location, Repository db) {
  #   try (Repository oldDb = cacheMap.put(location, db)) {
  #     // oldDb is auto-closed
  #   }
  # }
  #
  # private Repository unregisterRepository(Key location) {
  #   return cacheMap.remove(location);
  # }
  #
  # private boolean isExpired(Repository db) {
  #   return db != null && db.useCnt.get() <= 0
  #     && (System.currentTimeMillis() - db.closedAt.get() > expireAfter);
  # }
  #
  # private void unregisterAndCloseRepository(Key location) {
  #   synchronized (lockFor(location)) {
  #     Repository oldDb = unregisterRepository(location);
  #     if (oldDb != null) {
  #       oldDb.doClose();
  #     }
  #   }
  # }
  #
  # private Collection<Key> getKeys() {
  #   return new ArrayList<>(cacheMap.keySet());
  # }
  #
  # private void clearAllExpired() {
  #   for (Repository db : cacheMap.values()) {
  #     if (isExpired(db)) {
  #       RepositoryCache.close(db);
  #     }
  #   }
  # }
  #
  # private void clearAll() {
  #   for (Key k : cacheMap.keySet()) {
  #     unregisterAndCloseRepository(k);
  #   }
  # }
  #
  # private Lock lockFor(Key location) {
  #   return openLocks[(location.hashCode() >>> 1) % openLocks.length];
  # }
  #
  # private static class Lock {
  #   // Used only for its monitor.
  # }
  #
  # /**
  #  * Abstract hash key for {@link RepositoryCache} entries.
  #  * <p>
  #  * A Key instance should be lightweight, and implement hashCode() and
  #  * equals() such that two Key instances are equal if they represent the same
  #  * Repository location.
  #  */
  # public static interface Key {
  #   /**
  #    * Called by {@link RepositoryCache#open(Key)} if it doesn't exist yet.
  #    * <p>
  #    * If a repository does not exist yet in the cache, the cache will call
  #    * this method to acquire a handle to it.
  #    *
  #    * @param mustExist
  #    *            true if the repository must exist in order to be opened;
  #    *            false if a new non-existent repository is permitted to be
  #    *            created (the caller is responsible for calling create).
  #    * @return the new repository instance.
  #    * @throws IOException
  #    *             the repository could not be read (likely its core.version
  #    *             property is not supported).
  #    * @throws RepositoryNotFoundException
  #    *             There is no repository at the given location, only thrown
  #    *             if {@code mustExist} is true.
  #    */
  #   Repository open(boolean mustExist) throws IOException,
  #       RepositoryNotFoundException;
  # }

  defmodule FileKey do
    @moduledoc false
    # MOSTLY UNIMPLEMENTED FOR NOW
    # /** Location of a Repository, using the standard java.io.File API. */

    alias Xgit.Lib.Constants
    alias Xgit.Lib.ObjectId

    # /**
    #  * Obtain a pointer to an exact location on disk.
    #  * <p>
    #  * No guessing is performed, the given location is exactly the GIT_DIR
    #  * directory of the repository.
    #  *
    #  * @param directory
    #  *            location where the repository database is.
    #  * @param fs
    #  *            the file system abstraction which will be necessary to
    #  *            perform certain file system operations.
    #  * @return a key for the given directory.
    #  * @see #lenient(File, FS)
    #  */
    # public static FileKey exact(File directory, FS fs) {
    #   return new FileKey(directory, fs);
    # }
    #
    # /**
    #  * Obtain a pointer to a location on disk.
    #  * <p>
    #  * The method performs some basic guessing to locate the repository.
    #  * Searched paths are:
    #  * <ol>
    #  * <li>{@code directory} // assume exact match</li>
    #  * <li>{@code directory} + "/.git" // assume working directory</li>
    #  * <li>{@code directory} + ".git" // assume bare</li>
    #  * </ol>
    #  *
    #  * @param directory
    #  *            location where the repository database might be.
    #  * @param fs
    #  *            the file system abstraction which will be necessary to
    #  *            perform certain file system operations.
    #  * @return a key for the given directory.
    #  * @see #exact(File, FS)
    #  */
    # public static FileKey lenient(File directory, FS fs) {
    #   final File gitdir = resolve(directory, fs);
    #   return new FileKey(gitdir != null ? gitdir : directory, fs);
    # }
    #
    # private final File path;
    # private final FS fs;
    #
    # /**
    #  * @param directory
    #  *            exact location of the repository.
    #  * @param fs
    #  *            the file system abstraction which will be necessary to
    #  *            perform certain file system operations.
    #  */
    # protected FileKey(File directory, FS fs) {
    #   path = canonical(directory);
    #   this.fs = fs;
    # }
    #
    # private static File canonical(File path) {
    #   try {
    #     return path.getCanonicalFile();
    #   } catch (IOException e) {
    #     return path.getAbsoluteFile();
    #   }
    # }
    #
    # /** @return location supplied to the constructor. */
    # public final File getFile() {
    #   return path;
    # }
    #
    # @Override
    # public Repository open(boolean mustExist) throws IOException {
    #   if (mustExist && !isGitRepository(path, fs))
    #     throw new RepositoryNotFoundException(path);
    #   return new FileRepository(path);
    # }
    #
    # @Override
    # public int hashCode() {
    #   return path.hashCode();
    # }
    #
    # @Override
    # public boolean equals(Object o) {
    #   return o instanceof FileKey && path.equals(((FileKey) o).path);
    # }
    #
    # @Override
    # public String toString() {
    #   return path.toString();
    # }

    @doc ~S"""
    Guess if a directory contains a Git repository.

    This method guesses by looking for the existence of some key files
    and directories.
    """
    def contains_git_repository?(path) when is_binary(path) do
      File.dir?(Path.join(path, "objects")) &&
        File.dir?(Path.join(path, "refs")) &&
        valid_head?(Path.join(path, Constants.head()))
    end

    defp valid_head?(head) do
      ref = read_first_line(head)

      case ref do
        "ref: refs/" <> _ -> true
        nil -> false
        x -> ObjectId.valid?(x)
      end
    end

    defp read_first_line(head) do
      with {:ok, file} <- File.open(head, [:read]),
           line when is_binary(line) <- IO.read(file, :line),
           :ok <- File.close(file) do
        line
      else
        _ -> nil
      end
    end

    # /**
    #  * Guess the proper path for a Git repository.
    #  * <p>
    #  * The method performs some basic guessing to locate the repository.
    #  * Searched paths are:
    #  * <ol>
    #  * <li>{@code directory} // assume exact match</li>
    #  * <li>{@code directory} + "/.git" // assume working directory</li>
    #  * <li>{@code directory} + ".git" // assume bare</li>
    #  * </ol>
    #  *
    #  * @param directory
    #  *            location to guess from. Several permutations are tried.
    #  * @param fs
    #  *            the file system abstraction which will be necessary to
    #  *            perform certain file system operations.
    #  * @return the actual directory location if a better match is found;
    #  *         null if there is no suitable match.
    #  */
    # public static File resolve(File directory, FS fs) {
    #   if (isGitRepository(directory, fs))
    #     return directory;
    #   if (isGitRepository(new File(directory, Constants.DOT_GIT), fs))
    #     return new File(directory, Constants.DOT_GIT);
    #
    #   final String name = directory.getName();
    #   final File parent = directory.getParentFile();
    #   if (isGitRepository(new File(parent, name + Constants.DOT_GIT_EXT), fs))
    #     return new File(parent, name + Constants.DOT_GIT_EXT);
    #   return null;
    # }
  end
end
