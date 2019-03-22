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

  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants
  alias Xgit.Lib.PersonIdent
  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Util.SystemReader
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
  * `author`: A `PersonIdent` for a fake author.
  * `committer`: A `PersonIdent` for a fake committer.
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
      user_git_config,
      ConfigConstants.config_gc_section(),
      ConfigConstants.config_key_autodetach(),
      false
    )

    Config.save(user_git_config)

    mock_system_reader = %MockSystemReader{
      user_config: user_git_config,
      env: %{"GIT_CEILING_DIRECTORIES" => tmp}
    }

    time = SystemReader.current_time(mock_system_reader)
    timezone = SystemReader.timezone_at_time(mock_system_reader, time)

    author = %PersonIdent{
      name: "J. Author",
      email: "jauthor@example.com",
      when: time,
      tz_offset: timezone
    }

    committer = %PersonIdent{
      name: "J. Committer",
      email: "jcommitter@example.com",
      when: time,
      tz_offset: timezone
    }

    # final WindowCacheConfig c = new WindowCacheConfig();
    # c.setPackedGitLimit(128 * WindowCacheConfig.KB);
    # c.setPackedGitWindowSize(8 * WindowCacheConfig.KB);
    # c.setPackedGitMMAP(useMMAP);
    # c.setDeltaBaseCacheLimit(8 * WindowCacheConfig.KB);
    # c.install();

    %{
      mock_system_reader: mock_system_reader,
      author: author,
      committer: committer,
      tmp: tmp
    }
  end

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
end
