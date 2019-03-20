defmodule Xgit.Test.LocalDiskRepositoryTestCase do
  @moduledoc ~S"""
  Support for test cases that need a temporary local repository.

  A temporary directory is created for each test, allowing each test to use a
  fresh environment. The temporary directory is cleaned up after the test ends.

  PORTING NOTE: I'm still figuring out a porting strategy for the hierarchy
  of test case classes in jgit. So, for now, I'm keeping this fairlu minimal.
  """

  # /**
  #  * Callers should not use {@link org.eclipse.jgit.lib.RepositoryCache} from
  #  * within these tests as it may wedge file descriptors open past the end of the
  #  * test.
  #  * <p>
  #  * A system property {@code jgit.junit.usemmap} defines whether memory mapping
  #  * is used. Memory mapping has an effect on the file system, in that memory
  #  * mapped files in Java cannot be deleted as long as the mapped arrays have not
  #  * been reclaimed by the garbage collector. The programmer cannot control this
  #  * with precision, so temporary files may hang around longer than desired during
  #  * a test, or tests may fail altogether if there is insufficient file
  #  * descriptors or address space for the test process.
  #  */

  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Test.MockSystemReader

  # private static final boolean useMMAP = "true".equals(System
  #     .getProperty("jgit.junit.usemmap"));
  #
  # /** A fake (but stable) identity for author fields in the test. */
  # protected PersonIdent author;
  #
  # /** A fake (but stable) identity for committer fields in the test. */
  # protected PersonIdent committer;
  #
  # private File tmp;

  @doc ~S"""
  Create a test environment with a temporary test directory.

  Returns a map containing:
  * `mock_system_reader`: A `MockSystemReader` with environment variables set.
  * `tmp`: A temporary directory, which will be deleted after the test is done.
  """
  def setup_test do
    Temp.track!()
    tmp = Temp.mkdir!(prefix: "tmp_")

    user_git_config = FileBasedConfig.config_for_path(Path.join(tmp, "usergitconfig"))

    # We have to set autoDetach to false for tests, because tests expect to be able
    # to clean up by recursively removing the repository, and background GC might be
    # in the middle of writing or deleting files, which would disrupt this.

    Config.set_boolean(


    mock_system_reader = %MockSystemReader{
      user_config: user_git_config
    }

    %{
      mock_system_reader: mock_system_reader,
      tmp: tmp
    }
  end


  # public void setUp() throws Exception {
  #   // We have to set autoDetach to false for tests, because tests expect to be able
  #   // to clean up by recursively removing the repository, and background GC might be
  #   // in the middle of writing or deleting files, which would disrupt this.
  #   mockSystemReader.userGitConfig.setBoolean(ConfigConstants.CONFIG_GC_SECTION,
  #       null, ConfigConstants.CONFIG_KEY_AUTODETACH, false);
  #   mockSystemReader.userGitConfig.save();
  #   ceilTestDirectories(getCeilings());
  #   SystemReader.setInstance(mockSystemReader);
  #
  #   author = new PersonIdent("J. Author", "jauthor@example.com");
  #   committer = new PersonIdent("J. Committer", "jcommitter@example.com");
  #
  #   final WindowCacheConfig c = new WindowCacheConfig();
  #   c.setPackedGitLimit(128 * WindowCacheConfig.KB);
  #   c.setPackedGitWindowSize(8 * WindowCacheConfig.KB);
  #   c.setPackedGitMMAP(useMMAP);
  #   c.setDeltaBaseCacheLimit(8 * WindowCacheConfig.KB);
  #   c.install();
  # }
  #
  # /**
  #  * Get temporary directory.
  #  *
  #  * @return the temporary directory
  #  */
  # protected File getTemporaryDirectory() {
  #   return tmp.getAbsoluteFile();
  # }
  #
  # /**
  #  * Get list of ceiling directories
  #  *
  #  * @return list of ceiling directories
  #  */
  # protected List<File> getCeilings() {
  #   return Collections.singletonList(getTemporaryDirectory());
  # }
  #
  # private void ceilTestDirectories(List<File> ceilings) {
  #   mockSystemReader.setProperty(Constants.GIT_CEILING_DIRECTORIES_KEY, makePath(ceilings));
  # }
  #
  # private static String makePath(List<?> objects) {
  #   final StringBuilder stringBuilder = new StringBuilder();
  #   for (Object object : objects) {
  #     if (stringBuilder.length() > 0)
  #       stringBuilder.append(File.pathSeparatorChar);
  #     stringBuilder.append(object.toString());
  #   }
  #   return stringBuilder.toString();
  # }
  #
  # /**
  #  * Tear down the test
  #  *
  #  * @throws Exception
  #  */
  # @After
  # public void tearDown() throws Exception {
  #   RepositoryCache.clear();
  #   for (Repository r : toClose)
  #     r.close();
  #   toClose.clear();
  #
  #   // Since memory mapping is controlled by the GC we need to
  #   // tell it this is a good time to clean up and unlock
  #   // memory mapped files.
  #   //
  #   if (useMMAP)
  #     System.gc();
  #   if (tmp != null)
  #     recursiveDelete(tmp, false, true);
  #   if (tmp != null && !tmp.exists())
  #     CleanupThread.removed(tmp);
  #
  #   SystemReader.setInstance(null);
  # }
  #
  # /**
  #  * Increment the {@link #author} and {@link #committer} times.
  #  */
  # protected void tick() {
  #   mockSystemReader.tick(5 * 60);
  #   final long now = mockSystemReader.getCurrentTime();
  #   final int tz = mockSystemReader.getTimezone(now);
  #
  #   author = new PersonIdent(author, now, tz);
  #   committer = new PersonIdent(committer, now, tz);
  # }
  #
  # /**
  #  * Recursively delete a directory, failing the test if the delete fails.
  #  *
  #  * @param dir
  #  *            the recursively directory to delete, if present.
  #  */
  # protected void recursiveDelete(File dir) {
  #   recursiveDelete(dir, false, true);
  # }
  #
  # private static boolean recursiveDelete(final File dir,
  #     boolean silent, boolean failOnError) {
  #   assert !(silent && failOnError);
  #   if (!dir.exists())
  #     return silent;
  #   final File[] ls = dir.listFiles();
  #   if (ls != null)
  #     for (int k = 0; k < ls.length; k++) {
  #       final File e = ls[k];
  #       if (e.isDirectory())
  #         silent = recursiveDelete(e, silent, failOnError);
  #       else if (!e.delete()) {
  #         if (!silent)
  #           reportDeleteFailure(failOnError, e);
  #         silent = !failOnError;
  #       }
  #     }
  #   if (!dir.delete()) {
  #     if (!silent)
  #       reportDeleteFailure(failOnError, dir);
  #     silent = !failOnError;
  #   }
  #   return silent;
  # }
  #
  # private static void reportDeleteFailure(boolean failOnError, File e) {
  #   String severity = failOnError ? "ERROR" : "WARNING";
  #   String msg = severity + ": Failed to delete " + e;
  #   if (failOnError)
  #     fail(msg);
  #   else
  #     System.err.println(msg);
  # }
  #
  # /** Constant <code>MOD_TIME=1</code> */
  # public static final int MOD_TIME = 1;
  #
  # /** Constant <code>SMUDGE=2</code> */
  # public static final int SMUDGE = 2;
  #
  # /** Constant <code>LENGTH=4</code> */
  # public static final int LENGTH = 4;
  #
  # /** Constant <code>CONTENT_ID=8</code> */
  # public static final int CONTENT_ID = 8;
  #
  # /** Constant <code>CONTENT=16</code> */
  # public static final int CONTENT = 16;
  #
  # /** Constant <code>ASSUME_UNCHANGED=32</code> */
  # public static final int ASSUME_UNCHANGED = 32;
  #
  # /**
  #  * Represent the state of the index in one String. This representation is
  #  * useful when writing tests which do assertions on the state of the index.
  #  * By default information about path, mode, stage (if different from 0) is
  #  * included. A bitmask controls which additional info about
  #  * modificationTimes, smudge state and length is included.
  #  * <p>
  #  * The format of the returned string is described with this BNF:
  #  *
  #  * <pre>
  #  * result = ( "[" path mode stage? time? smudge? length? sha1? content? "]" )* .
  #  * mode = ", mode:" number .
  #  * stage = ", stage:" number .
  #  * time = ", time:t" timestamp-index .
  #  * smudge = "" | ", smudged" .
  #  * length = ", length:" number .
  #  * sha1 = ", sha1:" hex-sha1 .
  #  * content = ", content:" blob-data .
  #  * </pre>
  #  *
  #  * 'stage' is only presented when the stage is different from 0. All
  #  * reported time stamps are mapped to strings like "t0", "t1", ... "tn". The
  #  * smallest reported time-stamp will be called "t0". This allows to write
  #  * assertions against the string although the concrete value of the time
  #  * stamps is unknown.
  #  *
  #  * @param repo
  #  *            the repository the index state should be determined for
  #  * @param includedOptions
  #  *            a bitmask constructed out of the constants {@link #MOD_TIME},
  #  *            {@link #SMUDGE}, {@link #LENGTH}, {@link #CONTENT_ID} and
  #  *            {@link #CONTENT} controlling which info is present in the
  #  *            resulting string.
  #  * @return a string encoding the index state
  #  * @throws IllegalStateException
  #  * @throws IOException
  #  */
  # public static String indexState(Repository repo, int includedOptions)
  #     throws IllegalStateException, IOException {
  #   DirCache dc = repo.readDirCache();
  #   StringBuilder sb = new StringBuilder();
  #   TreeSet<Long> timeStamps = new TreeSet<>();
  #
  #   // iterate once over the dircache just to collect all time stamps
  #   if (0 != (includedOptions & MOD_TIME)) {
  #     for (int i=0; i<dc.getEntryCount(); ++i)
  #       timeStamps.add(Long.valueOf(dc.getEntry(i).getLastModified()));
  #   }
  #
  #   // iterate again, now produce the result string
  #   for (int i=0; i<dc.getEntryCount(); ++i) {
  #     DirCacheEntry entry = dc.getEntry(i);
  #     sb.append("["+entry.getPathString()+", mode:" + entry.getFileMode());
  #     int stage = entry.getStage();
  #     if (stage != 0)
  #       sb.append(", stage:" + stage);
  #     if (0 != (includedOptions & MOD_TIME)) {
  #       sb.append(", time:t"+
  #           timeStamps.headSet(Long.valueOf(entry.getLastModified())).size());
  #     }
  #     if (0 != (includedOptions & SMUDGE))
  #       if (entry.isSmudged())
  #         sb.append(", smudged");
  #     if (0 != (includedOptions & LENGTH))
  #       sb.append(", length:"
  #           + Integer.toString(entry.getLength()));
  #     if (0 != (includedOptions & CONTENT_ID))
  #       sb.append(", sha1:" + ObjectId.toString(entry.getObjectId()));
  #     if (0 != (includedOptions & CONTENT)) {
  #       sb.append(", content:"
  #           + new String(repo.open(entry.getObjectId(),
  #               Constants.OBJ_BLOB).getCachedBytes(), UTF_8));
  #     }
  #     if (0 != (includedOptions & ASSUME_UNCHANGED))
  #       sb.append(", assume-unchanged:"
  #           + Boolean.toString(entry.isAssumeValid()));
  #     sb.append("]");
  #   }
  #   return sb.toString();
  # }
  #
  #
  # /**
  #  * Creates a new empty bare repository.
  #  *
  #  * @return the newly created repository, opened for access
  #  * @throws IOException
  #  *             the repository could not be created in the temporary area
  #  */
  # protected FileRepository createBareRepository() throws IOException {
  #   return createRepository(true /* bare */);
  # }
  #
  # /**
  #  * Creates a new empty repository within a new empty working directory.
  #  *
  #  * @return the newly created repository, opened for access
  #  * @throws IOException
  #  *             the repository could not be created in the temporary area
  #  */
  # protected FileRepository createWorkRepository() throws IOException {
  #   return createRepository(false /* not bare */);
  # }
  #
  # /**
  #  * Creates a new empty repository.
  #  *
  #  * @param bare
  #  *            true to create a bare repository; false to make a repository
  #  *            within its working directory
  #  * @return the newly created repository, opened for access
  #  * @throws IOException
  #  *             the repository could not be created in the temporary area
  #  * @since 5.3
  #  */
  # protected FileRepository createRepository(boolean bare)
  #     throws IOException {
  #   return createRepository(bare, false /* auto close */);
  # }
  #
  # /**
  #  * Creates a new empty repository.
  #  *
  #  * @param bare
  #  *            true to create a bare repository; false to make a repository
  #  *            within its working directory
  #  * @param autoClose
  #  *            auto close the repository in {@link #tearDown()}
  #  * @return the newly created repository, opened for access
  #  * @throws IOException
  #  *             the repository could not be created in the temporary area
  #  * @deprecated use {@link #createRepository(boolean)} instead
  #  */
  # @Deprecated
  # public FileRepository createRepository(boolean bare, boolean autoClose)
  #     throws IOException {
  #   File gitdir = createUniqueTestGitDir(bare);
  #   FileRepository db = new FileRepository(gitdir);
  #   assertFalse(gitdir.exists());
  #   db.create(bare);
  #   if (autoClose) {
  #     addRepoToClose(db);
  #   }
  #   return db;
  # }
  #
  # /**
  #  * Adds a repository to the list of repositories which is closed at the end
  #  * of the tests
  #  *
  #  * @param r
  #  *            the repository to be closed
  #  */
  # public void addRepoToClose(Repository r) {
  #   toClose.add(r);
  # }
  #
  # /**
  #  * Creates a unique directory for a test
  #  *
  #  * @param name
  #  *            a subdirectory
  #  * @return a unique directory for a test
  #  * @throws IOException
  #  */
  # protected File createTempDirectory(String name) throws IOException {
  #   File directory = new File(createTempFile(), name);
  #   FileUtils.mkdirs(directory);
  #   return directory.getCanonicalFile();
  # }
  #
  # /**
  #  * Creates a new unique directory for a test repository
  #  *
  #  * @param bare
  #  *            true for a bare repository; false for a repository with a
  #  *            working directory
  #  * @return a unique directory for a test repository
  #  * @throws IOException
  #  */
  # protected File createUniqueTestGitDir(boolean bare) throws IOException {
  #   String gitdirName = createTempFile().getPath();
  #   if (!bare)
  #     gitdirName += "/";
  #   return new File(gitdirName + Constants.DOT_GIT);
  # }
  #
  # /**
  #  * Allocates a new unique file path that does not exist.
  #  * <p>
  #  * Unlike the standard {@code File.createTempFile} the returned path does
  #  * not exist, but may be created by another thread in a race with the
  #  * caller. Good luck.
  #  * <p>
  #  * This method is inherently unsafe due to a race condition between creating
  #  * the name and the first use that reserves it.
  #  *
  #  * @return a unique path that does not exist.
  #  * @throws IOException
  #  */
  # protected File createTempFile() throws IOException {
  #   File p = File.createTempFile("tmp_", "", tmp);
  #   if (!p.delete()) {
  #     throw new IOException("Cannot obtain unique path " + tmp);
  #   }
  #   return p;
  # }
  #
  # /**
  #  * Run a hook script in the repository, returning the exit status.
  #  *
  #  * @param db
  #  *            repository the script should see in GIT_DIR environment
  #  * @param hook
  #  *            path of the hook script to execute, must be executable file
  #  *            type on this platform
  #  * @param args
  #  *            arguments to pass to the hook script
  #  * @return exit status code of the invoked hook
  #  * @throws IOException
  #  *             the hook could not be executed
  #  * @throws InterruptedException
  #  *             the caller was interrupted before the hook completed
  #  */
  # protected int runHook(final Repository db, final File hook,
  #     final String... args) throws IOException, InterruptedException {
  #   final String[] argv = new String[1 + args.length];
  #   argv[0] = hook.getAbsolutePath();
  #   System.arraycopy(args, 0, argv, 1, args.length);
  #
  #   final Map<String, String> env = cloneEnv();
  #   env.put("GIT_DIR", db.getDirectory().getAbsolutePath());
  #   putPersonIdent(env, "AUTHOR", author);
  #   putPersonIdent(env, "COMMITTER", committer);
  #
  #   final File cwd = db.getWorkTree();
  #   final Process p = Runtime.getRuntime().exec(argv, toEnvArray(env), cwd);
  #   p.getOutputStream().close();
  #   p.getErrorStream().close();
  #   p.getInputStream().close();
  #   return p.waitFor();
  # }
  #
  # private static void putPersonIdent(final Map<String, String> env,
  #     final String type, final PersonIdent who) {
  #   final String ident = who.toExternalString();
  #   final String date = ident.substring(ident.indexOf("> ") + 2);
  #   env.put("GIT_" + type + "_NAME", who.getName());
  #   env.put("GIT_" + type + "_EMAIL", who.getEmailAddress());
  #   env.put("GIT_" + type + "_DATE", date);
  # }
  #
  # /**
  #  * Create a string to a UTF-8 temporary file and return the path.
  #  *
  #  * @param body
  #  *            complete content to write to the file. If the file should end
  #  *            with a trailing LF, the string should end with an LF.
  #  * @return path of the temporary file created within the trash area.
  #  * @throws IOException
  #  *             the file could not be written.
  #  */
  # protected File write(String body) throws IOException {
  #   final File f = File.createTempFile("temp", "txt", tmp);
  #   try {
  #     write(f, body);
  #     return f;
  #   } catch (Error e) {
  #     f.delete();
  #     throw e;
  #   } catch (RuntimeException e) {
  #     f.delete();
  #     throw e;
  #   } catch (IOException e) {
  #     f.delete();
  #     throw e;
  #   }
  # }
  #
  # /**
  #  * Write a string as a UTF-8 file.
  #  *
  #  * @param f
  #  *            file to write the string to. Caller is responsible for making
  #  *            sure it is in the trash directory or will otherwise be cleaned
  #  *            up at the end of the test. If the parent directory does not
  #  *            exist, the missing parent directories are automatically
  #  *            created.
  #  * @param body
  #  *            content to write to the file.
  #  * @throws IOException
  #  *             the file could not be written.
  #  */
  # protected void write(File f, String body) throws IOException {
  #   JGitTestUtil.write(f, body);
  # }
  #
  # /**
  #  * Read a file's content
  #  *
  #  * @param f
  #  *            the file
  #  * @return the content of the file
  #  * @throws IOException
  #  */
  # protected String read(File f) throws IOException {
  #   return JGitTestUtil.read(f);
  # }
  #
  # private static String[] toEnvArray(Map<String, String> env) {
  #   final String[] envp = new String[env.size()];
  #   int i = 0;
  #   for (Map.Entry<String, String> e : env.entrySet())
  #     envp[i++] = e.getKey() + "=" + e.getValue();
  #   return envp;
  # }
  #
  # private static HashMap<String, String> cloneEnv() {
  #   return new HashMap<>(System.getenv());
  # }
  #
  # private static final class CleanupThread extends Thread {
  #   private static final CleanupThread me;
  #   static {
  #     me = new CleanupThread();
  #     Runtime.getRuntime().addShutdownHook(me);
  #   }
  #
  #   static void deleteOnShutdown(File tmp) {
  #     synchronized (me) {
  #       me.toDelete.add(tmp);
  #     }
  #   }
  #
  #   static void removed(File tmp) {
  #     synchronized (me) {
  #       me.toDelete.remove(tmp);
  #     }
  #   }
  #
  #   private final List<File> toDelete = new ArrayList<>();
  #
  #   @Override
  #   public void run() {
  #     // On windows accidentally open files or memory
  #     // mapped regions may prevent files from being deleted.
  #     // Suggesting a GC increases the likelihood that our
  #     // test repositories actually get removed after the
  #     // tests, even in the case of failure.
  #     System.gc();
  #     synchronized (this) {
  #       boolean silent = false;
  #       boolean failOnError = false;
  #       for (File tmp : toDelete)
  #         recursiveDelete(tmp, silent, failOnError);
  #     }
  #   }
  # }
end
