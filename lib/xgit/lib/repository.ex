defmodule Xgit.Lib.Repository do
  @moduledoc ~S"""
  Represents a git repository.

  A repository holds all objects and refs used for managing source code. (It could
  be any type of file, but source code is what SCMs are typically used for.)
  """

  require Logger

  alias Xgit.Errors.NoWorkTreeError
  alias Xgit.Util.GenServerUtils

  @type t :: pid

  # /**
  #  * Branch names containing slashes should not have a name component that is
  #  * one of the reserved device names on Windows.
  #  *
  #  * @see #normalizeBranchName(String)
  #  */
  # private static final Pattern FORBIDDEN_BRANCH_NAME_COMPONENTS = Pattern
  #     .compile(
  #         "(^|/)(aux|com[1-9]|con|lpt[1-9]|nul|prn)(\\.[^/]*)?", //$NON-NLS-1$
  #         Pattern.CASE_INSENSITIVE);
  #
  # /**
  #  * Get the global listener list observing all events in this JVM.
  #  *
  #  * @return the global listener list observing all events in this JVM.
  #  */
  # public static ListenerList getGlobalListenerList() {
  #   return globalListeners;
  # }
  #
  # /** Use counter */
  # final AtomicInteger useCnt = new AtomicInteger(1);
  #
  # final AtomicLong closedAt = new AtomicLong();
  #
  # /** Metadata directory holding the repository's critical files. */
  # private final File gitDir;
  #
  # private final ListenerList myListeners = new ListenerList();
  #
  # /** If not bare, the index file caching the working file states. */
  # private final File indexFile;

  @doc """
  Starts a `Repository` process based on settings derived in a `RepositoryBuilder`
  struct.

  This should be called by the `start_link` function for a specific implementation
  module.

  Once the server is started, the `init/1` function of the given `module` is
  called with `args` as its arguments to initialize the stage. To ensure a
  synchronized start-up procedure, this function does not return until `init/1`
  has returned.

  The lifetime of this process is similar to that for `GenServer` or `GenStage`
  processes.
  """
  @spec start_link(module, term, GenServer.options()) :: GenServer.on_start()
  def start_link(module, args, options) when is_atom(module) and is_list(options),
    do: GenServer.start_link(__MODULE__, {module, args}, options)

  @doc false
  def init({mod, args}) do
    case mod.init(args) do
      {:ok, state} -> {:ok, {mod, state}}
      {:stop, reason} -> {:stop, reason}
    end
  end

  # /**
  #  * Get listeners observing only events on this repository.
  #  *
  #  * @return listeners observing only events on this repository.
  #  */
  # @NonNull
  # public ListenerList getListenerList() {
  #   return myListeners;
  # }
  #
  # /**
  #  * Fire an event to all registered listeners.
  #  * <p>
  #  * The source repository of the event is automatically set to this
  #  * repository, before the event is delivered to any listeners.
  #  *
  #  * @param event
  #  *            the event to deliver.
  #  */
  # public void fireEvent(RepositoryEvent<?> event) {
  #   event.setRepository(this);
  #   myListeners.dispatch(event);
  #   globalListeners.dispatch(event);
  # }

  @doc ~S"""
  Creates a new git repository; raises if unable to complete.

  Options (`opts`) are:
  * `bare?`: If `true`, a bare repository (without a working tree) is created.

  Returns `repository` for function chaining; raises an error if not.
  """
  @spec create!(repository :: t, opts :: Keyword.t()) :: t
  def create!(repository, opts \\ []) when is_pid(repository) and is_list(opts),
    do: GenServerUtils.call!(repository, {:create, opts})

  @doc ~S"""
  Invoked when `create/2` is called on this repository.

  Should initialize a new repository at this location.

  May raise `File.Error` or similar if the repository could not be created.

  Should return `:ok`.
  """
  @callback handle_create(state :: term, opts :: Keyword.t()) ::
              {:ok, state :: term} | {:error, reason :: term}

  @doc ~S"""
  Get local metadata directory.

  This is typically the `.git` directory in a local repository.

  Will return `nil` if the repository isn't local.
  """
  def git_dir!(repository) when is_pid(repository),
    do: GenServerUtils.call!(repository, :git_dir)

  @doc ~S"""
  Invoked when `git_dir!/1` is called on this repository.

  Should return the path to the `.git` directory if applicable, or `nil` if not.
  """
  @callback handle_git_dir(state :: term) :: String.t() | nil

  @doc ~S"""
  Get the object database which stores this repository's data.
  """
  def object_database!(repository) when is_pid(repository),
    do: GenServerUtils.call!(repository, :object_database)

  @doc ~S"""
  Invoked when `object_database/1` is called on this repository.

  Must return the PID for the object database or raise if unable.
  """
  @callback handle_object_database(state :: term) :: pid

  # /**
  #  * Create a new inserter to create objects in {@link #getObjectDatabase()}.
  #  *
  #  * @return a new inserter to create objects in {@link #getObjectDatabase()}.
  #  */
  # @NonNull
  # public ObjectInserter newObjectInserter() {
  #   return getObjectDatabase().newInserter();
  # }
  #
  # /**
  #  * Create a new reader to read objects from {@link #getObjectDatabase()}.
  #  *
  #  * @return a new reader to read objects from {@link #getObjectDatabase()}.
  #  */
  # @NonNull
  # public ObjectReader newObjectReader() {
  #   return getObjectDatabase().newReader();
  # }
  #
  # /**
  #  * Get the reference database which stores the reference namespace.
  #  *
  #  * @return the reference database which stores the reference namespace.
  #  */
  # @NonNull
  # public abstract RefDatabase getRefDatabase();
  #
  # /**
  #  * Get the configuration of this repository.
  #  *
  #  * @return the configuration of this repository.
  #  */
  # @NonNull
  # public abstract StoredConfig getConfig();
  #
  # /**
  #  * Create a new {@link org.eclipse.jgit.attributes.AttributesNodeProvider}.
  #  *
  #  * @return a new {@link org.eclipse.jgit.attributes.AttributesNodeProvider}.
  #  *         This {@link org.eclipse.jgit.attributes.AttributesNodeProvider}
  #  *         is lazy loaded only once. It means that it will not be updated
  #  *         after loading. Prefer creating new instance for each use.
  #  * @since 4.2
  #  */
  # @NonNull
  # public abstract AttributesNodeProvider createAttributesNodeProvider();
  #
  # /**
  #  * Whether the specified object is stored in this repo or any of the known
  #  * shared repositories.
  #  *
  #  * @param objectId
  #  *            a {@link org.eclipse.jgit.lib.AnyObjectId} object.
  #  * @return true if the specified object is stored in this repo or any of the
  #  *         known shared repositories.
  #  * @deprecated use {@code getObjectDatabase().has(objectId)}
  #  */
  # @Deprecated
  # public boolean hasObject(AnyObjectId objectId) {
  #   try {
  #     return getObjectDatabase().has(objectId);
  #   } catch (IOException e) {
  #     throw new UncheckedIOException(e);
  #   }
  # }
  #
  # /**
  #  * Open an object from this repository.
  #  * <p>
  #  * This is a one-shot call interface which may be faster than allocating a
  #  * {@link #newObjectReader()} to perform the lookup.
  #  *
  #  * @param objectId
  #  *            identity of the object to open.
  #  * @return a {@link org.eclipse.jgit.lib.ObjectLoader} for accessing the
  #  *         object.
  #  * @throws org.eclipse.jgit.errors.MissingObjectException
  #  *             the object does not exist.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # @NonNull
  # public ObjectLoader open(AnyObjectId objectId)
  #     throws MissingObjectException, IOException {
  #   return getObjectDatabase().open(objectId);
  # }
  #
  # /**
  #  * Open an object from this repository.
  #  * <p>
  #  * This is a one-shot call interface which may be faster than allocating a
  #  * {@link #newObjectReader()} to perform the lookup.
  #  *
  #  * @param objectId
  #  *            identity of the object to open.
  #  * @param typeHint
  #  *            hint about the type of object being requested, e.g.
  #  *            {@link org.eclipse.jgit.lib.Constants#OBJ_BLOB};
  #  *            {@link org.eclipse.jgit.lib.ObjectReader#OBJ_ANY} if the
  #  *            object type is not known, or does not matter to the caller.
  #  * @return a {@link org.eclipse.jgit.lib.ObjectLoader} for accessing the
  #  *         object.
  #  * @throws org.eclipse.jgit.errors.MissingObjectException
  #  *             the object does not exist.
  #  * @throws org.eclipse.jgit.errors.IncorrectObjectTypeException
  #  *             typeHint was not OBJ_ANY, and the object's actual type does
  #  *             not match typeHint.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # @NonNull
  # public ObjectLoader open(AnyObjectId objectId, int typeHint)
  #     throws MissingObjectException, IncorrectObjectTypeException,
  #     IOException {
  #   return getObjectDatabase().open(objectId, typeHint);
  # }
  #
  # /**
  #  * Create a command to update, create or delete a ref in this repository.
  #  *
  #  * @param ref
  #  *            name of the ref the caller wants to modify.
  #  * @return an update command. The caller must finish populating this command
  #  *         and then invoke one of the update methods to actually make a
  #  *         change.
  #  * @throws java.io.IOException
  #  *             a symbolic ref was passed in and could not be resolved back
  #  *             to the base ref, as the symbolic ref could not be read.
  #  */
  # @NonNull
  # public RefUpdate updateRef(String ref) throws IOException {
  #   return updateRef(ref, false);
  # }
  #
  # /**
  #  * Create a command to update, create or delete a ref in this repository.
  #  *
  #  * @param ref
  #  *            name of the ref the caller wants to modify.
  #  * @param detach
  #  *            true to create a detached head
  #  * @return an update command. The caller must finish populating this command
  #  *         and then invoke one of the update methods to actually make a
  #  *         change.
  #  * @throws java.io.IOException
  #  *             a symbolic ref was passed in and could not be resolved back
  #  *             to the base ref, as the symbolic ref could not be read.
  #  */
  # @NonNull
  # public RefUpdate updateRef(String ref, boolean detach) throws IOException {
  #   return getRefDatabase().newUpdate(ref, detach);
  # }
  #
  # /**
  #  * Create a command to rename a ref in this repository
  #  *
  #  * @param fromRef
  #  *            name of ref to rename from
  #  * @param toRef
  #  *            name of ref to rename to
  #  * @return an update command that knows how to rename a branch to another.
  #  * @throws java.io.IOException
  #  *             the rename could not be performed.
  #  */
  # @NonNull
  # public RefRename renameRef(String fromRef, String toRef) throws IOException {
  #   return getRefDatabase().newRename(fromRef, toRef);
  # }
  #
  # /**
  #  * Parse a git revision string and return an object id.
  #  *
  #  * Combinations of these operators are supported:
  #  * <ul>
  #  * <li><b>HEAD</b>, <b>MERGE_HEAD</b>, <b>FETCH_HEAD</b></li>
  #  * <li><b>SHA-1</b>: a complete or abbreviated SHA-1</li>
  #  * <li><b>refs/...</b>: a complete reference name</li>
  #  * <li><b>short-name</b>: a short reference name under {@code refs/heads},
  #  * {@code refs/tags}, or {@code refs/remotes} namespace</li>
  #  * <li><b>tag-NN-gABBREV</b>: output from describe, parsed by treating
  #  * {@code ABBREV} as an abbreviated SHA-1.</li>
  #  * <li><i>id</i><b>^</b>: first parent of commit <i>id</i>, this is the same
  #  * as {@code id^1}</li>
  #  * <li><i>id</i><b>^0</b>: ensure <i>id</i> is a commit</li>
  #  * <li><i>id</i><b>^n</b>: n-th parent of commit <i>id</i></li>
  #  * <li><i>id</i><b>~n</b>: n-th historical ancestor of <i>id</i>, by first
  #  * parent. {@code id~3} is equivalent to {@code id^1^1^1} or {@code id^^^}.</li>
  #  * <li><i>id</i><b>:path</b>: Lookup path under tree named by <i>id</i></li>
  #  * <li><i>id</i><b>^{commit}</b>: ensure <i>id</i> is a commit</li>
  #  * <li><i>id</i><b>^{tree}</b>: ensure <i>id</i> is a tree</li>
  #  * <li><i>id</i><b>^{tag}</b>: ensure <i>id</i> is a tag</li>
  #  * <li><i>id</i><b>^{blob}</b>: ensure <i>id</i> is a blob</li>
  #  * </ul>
  #  *
  #  * <p>
  #  * The following operators are specified by git conventions, but are not
  #  * supported by this method:
  #  * <ul>
  #  * <li><b>ref@{n}</b>: n-th version of ref as given by its reflog</li>
  #  * <li><b>ref@{time}</b>: value of ref at the designated time</li>
  #  * </ul>
  #  *
  #  * @param revstr
  #  *            A git object references expression
  #  * @return an ObjectId or {@code null} if revstr can't be resolved to any
  #  *         ObjectId
  #  * @throws org.eclipse.jgit.errors.AmbiguousObjectException
  #  *             {@code revstr} contains an abbreviated ObjectId and this
  #  *             repository contains more than one object which match to the
  #  *             input abbreviation.
  #  * @throws org.eclipse.jgit.errors.IncorrectObjectTypeException
  #  *             the id parsed does not meet the type required to finish
  #  *             applying the operators in the expression.
  #  * @throws org.eclipse.jgit.errors.RevisionSyntaxException
  #  *             the expression is not supported by this implementation, or
  #  *             does not meet the standard syntax.
  #  * @throws java.io.IOException
  #  *             on serious errors
  #  */
  # @Nullable
  # public ObjectId resolve(String revstr)
  #     throws AmbiguousObjectException, IncorrectObjectTypeException,
  #     RevisionSyntaxException, IOException {
  #   try (RevWalk rw = new RevWalk(this)) {
  #     Object resolved = resolve(rw, revstr);
  #     if (resolved instanceof String) {
  #       final Ref ref = findRef((String) resolved);
  #       return ref != null ? ref.getLeaf().getObjectId() : null;
  #     } else {
  #       return (ObjectId) resolved;
  #     }
  #   }
  # }
  #
  # /**
  #  * Simplify an expression, but unlike {@link #resolve(String)} it will not
  #  * resolve a branch passed or resulting from the expression, such as @{-}.
  #  * Thus this method can be used to process an expression to a method that
  #  * expects a branch or revision id.
  #  *
  #  * @param revstr a {@link java.lang.String} object.
  #  * @return object id or ref name from resolved expression or {@code null} if
  #  *         given expression cannot be resolved
  #  * @throws org.eclipse.jgit.errors.AmbiguousObjectException
  #  * @throws java.io.IOException
  #  */
  # @Nullable
  # public String simplify(String revstr)
  #     throws AmbiguousObjectException, IOException {
  #   try (RevWalk rw = new RevWalk(this)) {
  #     Object resolved = resolve(rw, revstr);
  #     if (resolved != null)
  #       if (resolved instanceof String)
  #         return (String) resolved;
  #       else
  #         return ((AnyObjectId) resolved).getName();
  #     return null;
  #   }
  # }
  #
  # @Nullable
  # private Object resolve(RevWalk rw, String revstr)
  #     throws IOException {
  #   char[] revChars = revstr.toCharArray();
  #   RevObject rev = null;
  #   String name = null;
  #   int done = 0;
  #   for (int i = 0; i < revChars.length; ++i) {
  #     switch (revChars[i]) {
  #     case '^':
  #       if (rev == null) {
  #         if (name == null)
  #           if (done == 0)
  #             name = new String(revChars, done, i);
  #           else {
  #             done = i + 1;
  #             break;
  #           }
  #         rev = parseSimple(rw, name);
  #         name = null;
  #         if (rev == null)
  #           return null;
  #       }
  #       if (i + 1 < revChars.length) {
  #         switch (revChars[i + 1]) {
  #         case '0':
  #         case '1':
  #         case '2':
  #         case '3':
  #         case '4':
  #         case '5':
  #         case '6':
  #         case '7':
  #         case '8':
  #         case '9':
  #           int j;
  #           rev = rw.parseCommit(rev);
  #           for (j = i + 1; j < revChars.length; ++j) {
  #             if (!Character.isDigit(revChars[j]))
  #               break;
  #           }
  #           String parentnum = new String(revChars, i + 1, j - i
  #               - 1);
  #           int pnum;
  #           try {
  #             pnum = Integer.parseInt(parentnum);
  #           } catch (NumberFormatException e) {
  #             throw new RevisionSyntaxException(
  #                 JGitText.get().invalidCommitParentNumber,
  #                 revstr);
  #           }
  #           if (pnum != 0) {
  #             RevCommit commit = (RevCommit) rev;
  #             if (pnum > commit.getParentCount())
  #               rev = null;
  #             else
  #               rev = commit.getParent(pnum - 1);
  #           }
  #           i = j - 1;
  #           done = j;
  #           break;
  #         case '{':
  #           int k;
  #           String item = null;
  #           for (k = i + 2; k < revChars.length; ++k) {
  #             if (revChars[k] == '}') {
  #               item = new String(revChars, i + 2, k - i - 2);
  #               break;
  #             }
  #           }
  #           i = k;
  #           if (item != null)
  #             if (item.equals("tree")) { //$NON-NLS-1$
  #               rev = rw.parseTree(rev);
  #             } else if (item.equals("commit")) { //$NON-NLS-1$
  #               rev = rw.parseCommit(rev);
  #             } else if (item.equals("blob")) { //$NON-NLS-1$
  #               rev = rw.peel(rev);
  #               if (!(rev instanceof RevBlob))
  #                 throw new IncorrectObjectTypeException(rev,
  #                     Constants.TYPE_BLOB);
  #             } else if (item.equals("")) { //$NON-NLS-1$
  #               rev = rw.peel(rev);
  #             } else
  #               throw new RevisionSyntaxException(revstr);
  #           else
  #             throw new RevisionSyntaxException(revstr);
  #           done = k;
  #           break;
  #         default:
  #           rev = rw.peel(rev);
  #           if (rev instanceof RevCommit) {
  #             RevCommit commit = ((RevCommit) rev);
  #             if (commit.getParentCount() == 0)
  #               rev = null;
  #             else
  #               rev = commit.getParent(0);
  #           } else
  #             throw new IncorrectObjectTypeException(rev,
  #                 Constants.TYPE_COMMIT);
  #         }
  #       } else {
  #         rev = rw.peel(rev);
  #         if (rev instanceof RevCommit) {
  #           RevCommit commit = ((RevCommit) rev);
  #           if (commit.getParentCount() == 0)
  #             rev = null;
  #           else
  #             rev = commit.getParent(0);
  #         } else
  #           throw new IncorrectObjectTypeException(rev,
  #               Constants.TYPE_COMMIT);
  #       }
  #       done = i + 1;
  #       break;
  #     case '~':
  #       if (rev == null) {
  #         if (name == null)
  #           if (done == 0)
  #             name = new String(revChars, done, i);
  #           else {
  #             done = i + 1;
  #             break;
  #           }
  #         rev = parseSimple(rw, name);
  #         name = null;
  #         if (rev == null)
  #           return null;
  #       }
  #       rev = rw.peel(rev);
  #       if (!(rev instanceof RevCommit))
  #         throw new IncorrectObjectTypeException(rev,
  #             Constants.TYPE_COMMIT);
  #       int l;
  #       for (l = i + 1; l < revChars.length; ++l) {
  #         if (!Character.isDigit(revChars[l]))
  #           break;
  #       }
  #       int dist;
  #       if (l - i > 1) {
  #         String distnum = new String(revChars, i + 1, l - i - 1);
  #         try {
  #           dist = Integer.parseInt(distnum);
  #         } catch (NumberFormatException e) {
  #           throw new RevisionSyntaxException(
  #               JGitText.get().invalidAncestryLength, revstr);
  #         }
  #       } else
  #         dist = 1;
  #       while (dist > 0) {
  #         RevCommit commit = (RevCommit) rev;
  #         if (commit.getParentCount() == 0) {
  #           rev = null;
  #           break;
  #         }
  #         commit = commit.getParent(0);
  #         rw.parseHeaders(commit);
  #         rev = commit;
  #         --dist;
  #       }
  #       i = l - 1;
  #       done = l;
  #       break;
  #     case '@':
  #       if (rev != null)
  #         throw new RevisionSyntaxException(revstr);
  #       if (i + 1 == revChars.length)
  #         continue;
  #       if (i + 1 < revChars.length && revChars[i + 1] != '{')
  #         continue;
  #       int m;
  #       String time = null;
  #       for (m = i + 2; m < revChars.length; ++m) {
  #         if (revChars[m] == '}') {
  #           time = new String(revChars, i + 2, m - i - 2);
  #           break;
  #         }
  #       }
  #       if (time != null) {
  #         if (time.equals("upstream")) { //$NON-NLS-1$
  #           if (name == null)
  #             name = new String(revChars, done, i);
  #           if (name.equals("")) //$NON-NLS-1$
  #             // Currently checked out branch, HEAD if
  #             // detached
  #             name = Constants.HEAD;
  #           if (!Repository.isValidRefName("x/" + name)) //$NON-NLS-1$
  #             throw new RevisionSyntaxException(MessageFormat
  #                 .format(JGitText.get().invalidRefName,
  #                     name),
  #                 revstr);
  #           Ref ref = findRef(name);
  #           name = null;
  #           if (ref == null)
  #             return null;
  #           if (ref.isSymbolic())
  #             ref = ref.getLeaf();
  #           name = ref.getName();
  #
  #           RemoteConfig remoteConfig;
  #           try {
  #             remoteConfig = new RemoteConfig(getConfig(),
  #                 "origin"); //$NON-NLS-1$
  #           } catch (URISyntaxException e) {
  #             throw new RevisionSyntaxException(revstr);
  #           }
  #           String remoteBranchName = getConfig()
  #               .getString(
  #                   ConfigConstants.CONFIG_BRANCH_SECTION,
  #               Repository.shortenRefName(ref.getName()),
  #                   ConfigConstants.CONFIG_KEY_MERGE);
  #           List<RefSpec> fetchRefSpecs = remoteConfig
  #               .getFetchRefSpecs();
  #           for (RefSpec refSpec : fetchRefSpecs) {
  #             if (refSpec.matchSource(remoteBranchName)) {
  #               RefSpec expandFromSource = refSpec
  #                   .expandFromSource(remoteBranchName);
  #               name = expandFromSource.getDestination();
  #               break;
  #             }
  #           }
  #           if (name == null)
  #             throw new RevisionSyntaxException(revstr);
  #         } else if (time.matches("^-\\d+$")) { //$NON-NLS-1$
  #           if (name != null)
  #             throw new RevisionSyntaxException(revstr);
  #           else {
  #             String previousCheckout = resolveReflogCheckout(-Integer
  #                 .parseInt(time));
  #             if (ObjectId.isId(previousCheckout))
  #               rev = parseSimple(rw, previousCheckout);
  #             else
  #               name = previousCheckout;
  #           }
  #         } else {
  #           if (name == null)
  #             name = new String(revChars, done, i);
  #           if (name.equals("")) //$NON-NLS-1$
  #             name = Constants.HEAD;
  #           if (!Repository.isValidRefName("x/" + name)) //$NON-NLS-1$
  #             throw new RevisionSyntaxException(MessageFormat
  #                 .format(JGitText.get().invalidRefName,
  #                     name),
  #                 revstr);
  #           Ref ref = findRef(name);
  #           name = null;
  #           if (ref == null)
  #             return null;
  #           // @{n} means current branch, not HEAD@{1} unless
  #           // detached
  #           if (ref.isSymbolic())
  #             ref = ref.getLeaf();
  #           rev = resolveReflog(rw, ref, time);
  #         }
  #         i = m;
  #       } else
  #         throw new RevisionSyntaxException(revstr);
  #       break;
  #     case ':': {
  #       RevTree tree;
  #       if (rev == null) {
  #         if (name == null)
  #           name = new String(revChars, done, i);
  #         if (name.equals("")) //$NON-NLS-1$
  #           name = Constants.HEAD;
  #         rev = parseSimple(rw, name);
  #         name = null;
  #       }
  #       if (rev == null)
  #         return null;
  #       tree = rw.parseTree(rev);
  #       if (i == revChars.length - 1)
  #         return tree.copy();
  #
  #       TreeWalk tw = TreeWalk.forPath(rw.getObjectReader(),
  #           new String(revChars, i + 1, revChars.length - i - 1),
  #           tree);
  #       return tw != null ? tw.getObjectId(0) : null;
  #     }
  #     default:
  #       if (rev != null)
  #         throw new RevisionSyntaxException(revstr);
  #     }
  #   }
  #   if (rev != null)
  #     return rev.copy();
  #   if (name != null)
  #     return name;
  #   if (done == revstr.length())
  #     return null;
  #   name = revstr.substring(done);
  #   if (!Repository.isValidRefName("x/" + name)) //$NON-NLS-1$
  #     throw new RevisionSyntaxException(
  #         MessageFormat.format(JGitText.get().invalidRefName, name),
  #         revstr);
  #   if (findRef(name) != null)
  #     return name;
  #   return resolveSimple(name);
  # }
  #
  # private static boolean isHex(char c) {
  #   return ('0' <= c && c <= '9') //
  #       || ('a' <= c && c <= 'f') //
  #       || ('A' <= c && c <= 'F');
  # }
  #
  # private static boolean isAllHex(String str, int ptr) {
  #   while (ptr < str.length()) {
  #     if (!isHex(str.charAt(ptr++)))
  #       return false;
  #   }
  #   return true;
  # }
  #
  # @Nullable
  # private RevObject parseSimple(RevWalk rw, String revstr) throws IOException {
  #   ObjectId id = resolveSimple(revstr);
  #   return id != null ? rw.parseAny(id) : null;
  # }
  #
  # @Nullable
  # private ObjectId resolveSimple(String revstr) throws IOException {
  #   if (ObjectId.isId(revstr))
  #     return ObjectId.fromString(revstr);
  #
  #   if (Repository.isValidRefName("x/" + revstr)) { //$NON-NLS-1$
  #     Ref r = getRefDatabase().findRef(revstr);
  #     if (r != null)
  #       return r.getObjectId();
  #   }
  #
  #   if (AbbreviatedObjectId.isId(revstr))
  #     return resolveAbbreviation(revstr);
  #
  #   int dashg = revstr.indexOf("-g"); //$NON-NLS-1$
  #   if ((dashg + 5) < revstr.length() && 0 <= dashg
  #       && isHex(revstr.charAt(dashg + 2))
  #       && isHex(revstr.charAt(dashg + 3))
  #       && isAllHex(revstr, dashg + 4)) {
  #     // Possibly output from git describe?
  #     String s = revstr.substring(dashg + 2);
  #     if (AbbreviatedObjectId.isId(s))
  #       return resolveAbbreviation(s);
  #   }
  #
  #   return null;
  # }
  #
  # @Nullable
  # private String resolveReflogCheckout(int checkoutNo)
  #     throws IOException {
  #   ReflogReader reader = getReflogReader(Constants.HEAD);
  #   if (reader == null) {
  #     return null;
  #   }
  #   List<ReflogEntry> reflogEntries = reader.getReverseEntries();
  #   for (ReflogEntry entry : reflogEntries) {
  #     CheckoutEntry checkout = entry.parseCheckout();
  #     if (checkout != null)
  #       if (checkoutNo-- == 1)
  #         return checkout.getFromBranch();
  #   }
  #   return null;
  # }
  #
  # private RevCommit resolveReflog(RevWalk rw, Ref ref, String time)
  #     throws IOException {
  #   int number;
  #   try {
  #     number = Integer.parseInt(time);
  #   } catch (NumberFormatException nfe) {
  #     throw new RevisionSyntaxException(MessageFormat.format(
  #         JGitText.get().invalidReflogRevision, time));
  #   }
  #   assert number >= 0;
  #   ReflogReader reader = getReflogReader(ref.getName());
  #   if (reader == null) {
  #     throw new RevisionSyntaxException(
  #         MessageFormat.format(JGitText.get().reflogEntryNotFound,
  #             Integer.valueOf(number), ref.getName()));
  #   }
  #   ReflogEntry entry = reader.getReverseEntry(number);
  #   if (entry == null)
  #     throw new RevisionSyntaxException(MessageFormat.format(
  #         JGitText.get().reflogEntryNotFound,
  #         Integer.valueOf(number), ref.getName()));
  #
  #   return rw.parseCommit(entry.getNewId());
  # }
  #
  # @Nullable
  # private ObjectId resolveAbbreviation(String revstr) throws IOException,
  #     AmbiguousObjectException {
  #   AbbreviatedObjectId id = AbbreviatedObjectId.fromString(revstr);
  #   try (ObjectReader reader = newObjectReader()) {
  #     Collection<ObjectId> matches = reader.resolve(id);
  #     if (matches.size() == 0)
  #       return null;
  #     else if (matches.size() == 1)
  #       return matches.iterator().next();
  #     else
  #       throw new AmbiguousObjectException(id, matches);
  #   }
  # }
  #
  # /**
  #  * Increment the use counter by one, requiring a matched {@link #close()}.
  #  */
  # public void incrementOpen() {
  #   useCnt.incrementAndGet();
  # }
  #
  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Decrement the use count, and maybe close resources.
  #  */
  # @Override
  # public void close() {
  #   int newCount = useCnt.decrementAndGet();
  #   if (newCount == 0) {
  #     if (RepositoryCache.isCached(this)) {
  #       closedAt.set(System.currentTimeMillis());
  #     } else {
  #       doClose();
  #     }
  #   } else if (newCount == -1) {
  #     // should not happen, only log when useCnt became negative to
  #     // minimize number of log entries
  #     String message = MessageFormat.format(JGitText.get().corruptUseCnt,
  #         toString());
  #     if (LOG.isDebugEnabled()) {
  #       LOG.debug(message, new IllegalStateException());
  #     } else {
  #       LOG.warn(message);
  #     }
  #     if (RepositoryCache.isCached(this)) {
  #       closedAt.set(System.currentTimeMillis());
  #     }
  #   }
  # }
  #
  # /**
  #  * Invoked when the use count drops to zero during {@link #close()}.
  #  * <p>
  #  * The default implementation closes the object and ref databases.
  #  */
  # protected void doClose() {
  #   getObjectDatabase().close();
  #   getRefDatabase().close();
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # @NonNull
  # public String toString() {
  #   String desc;
  #   File directory = getDirectory();
  #   if (directory != null)
  #     desc = directory.getPath();
  #   else
  #     desc = getClass().getSimpleName() + "-" //$NON-NLS-1$
  #         + System.identityHashCode(this);
  #   return "Repository[" + desc + "]"; //$NON-NLS-1$ //$NON-NLS-2$
  # }
  #
  # /**
  #  * Get the name of the reference that {@code HEAD} points to.
  #  * <p>
  #  * This is essentially the same as doing:
  #  *
  #  * <pre>
  #  * return exactRef(Constants.HEAD).getTarget().getName()
  #  * </pre>
  #  *
  #  * Except when HEAD is detached, in which case this method returns the
  #  * current ObjectId in hexadecimal string format.
  #  *
  #  * @return name of current branch (for example {@code refs/heads/master}),
  #  *         an ObjectId in hex format if the current branch is detached, or
  #  *         {@code null} if the repository is corrupt and has no HEAD
  #  *         reference.
  #  * @throws java.io.IOException
  #  */
  # @Nullable
  # public String getFullBranch() throws IOException {
  #   Ref head = exactRef(Constants.HEAD);
  #   if (head == null) {
  #     return null;
  #   }
  #   if (head.isSymbolic()) {
  #     return head.getTarget().getName();
  #   }
  #   ObjectId objectId = head.getObjectId();
  #   if (objectId != null) {
  #     return objectId.name();
  #   }
  #   return null;
  # }
  #
  # /**
  #  * Get the short name of the current branch that {@code HEAD} points to.
  #  * <p>
  #  * This is essentially the same as {@link #getFullBranch()}, except the
  #  * leading prefix {@code refs/heads/} is removed from the reference before
  #  * it is returned to the caller.
  #  *
  #  * @return name of current branch (for example {@code master}), an ObjectId
  #  *         in hex format if the current branch is detached, or {@code null}
  #  *         if the repository is corrupt and has no HEAD reference.
  #  * @throws java.io.IOException
  #  */
  # @Nullable
  # public String getBranch() throws IOException {
  #   String name = getFullBranch();
  #   if (name != null)
  #     return shortenRefName(name);
  #   return null;
  # }
  #
  # /**
  #  * Objects known to exist but not expressed by {@link #getAllRefs()}.
  #  * <p>
  #  * When a repository borrows objects from another repository, it can
  #  * advertise that it safely has that other repository's references, without
  #  * exposing any other details about the other repository.  This may help
  #  * a client trying to push changes avoid pushing more than it needs to.
  #  *
  #  * @return unmodifiable collection of other known objects.
  #  */
  # @NonNull
  # public Set<ObjectId> getAdditionalHaves() {
  #   return Collections.emptySet();
  # }
  #
  # /**
  #  * Get a ref by name.
  #  *
  #  * @param name
  #  *            the name of the ref to lookup. Must not be a short-hand
  #  *            form; e.g., "master" is not automatically expanded to
  #  *            "refs/heads/master".
  #  * @return the Ref with the given name, or {@code null} if it does not exist
  #  * @throws java.io.IOException
  #  * @since 4.2
  #  */
  # @Nullable
  # public final Ref exactRef(String name) throws IOException {
  #   return getRefDatabase().exactRef(name);
  # }
  #
  # /**
  #  * Search for a ref by (possibly abbreviated) name.
  #  *
  #  * @param name
  #  *            the name of the ref to lookup. May be a short-hand form, e.g.
  #  *            "master" which is automatically expanded to
  #  *            "refs/heads/master" if "refs/heads/master" already exists.
  #  * @return the Ref with the given name, or {@code null} if it does not exist
  #  * @throws java.io.IOException
  #  * @since 4.2
  #  */
  # @Nullable
  # public final Ref findRef(String name) throws IOException {
  #   return getRefDatabase().findRef(name);
  # }
  #
  # /**
  #  * Get mutable map of all known refs, including symrefs like HEAD that may
  #  * not point to any object yet.
  #  *
  #  * @return mutable map of all known refs (heads, tags, remotes).
  #  * @deprecated use {@code getRefDatabase().getRefs()} instead.
  #  */
  # @Deprecated
  # @NonNull
  # public Map<String, Ref> getAllRefs() {
  #   try {
  #     return getRefDatabase().getRefs(RefDatabase.ALL);
  #   } catch (IOException e) {
  #     throw new UncheckedIOException(e);
  #   }
  # }
  #
  # /**
  #  * Get mutable map of all tags
  #  *
  #  * @return mutable map of all tags; key is short tag name ("v1.0") and value
  #  *         of the entry contains the ref with the full tag name
  #  *         ("refs/tags/v1.0").
  #  * @deprecated use {@code getRefDatabase().getRefsByPrefix(R_TAGS)} instead
  #  */
  # @Deprecated
  # @NonNull
  # public Map<String, Ref> getTags() {
  #   try {
  #     return getRefDatabase().getRefs(Constants.R_TAGS);
  #   } catch (IOException e) {
  #     throw new UncheckedIOException(e);
  #   }
  # }
  #
  # /**
  #  * Peel a possibly unpeeled reference to an annotated tag.
  #  * <p>
  #  * If the ref cannot be peeled (as it does not refer to an annotated tag)
  #  * the peeled id stays null, but {@link org.eclipse.jgit.lib.Ref#isPeeled()}
  #  * will be true.
  #  *
  #  * @param ref
  #  *            The ref to peel
  #  * @return <code>ref</code> if <code>ref.isPeeled()</code> is true; else a
  #  *         new Ref object representing the same data as Ref, but isPeeled()
  #  *         will be true and getPeeledObjectId will contain the peeled object
  #  *         (or null).
  #  * @deprecated use {@code getRefDatabase().peel(ref)} instead.
  #  */
  # @Deprecated
  # @NonNull
  # public Ref peel(Ref ref) {
  #   try {
  #     return getRefDatabase().peel(ref);
  #   } catch (IOException e) {
  #     // Historical accident; if the reference cannot be peeled due
  #     // to some sort of repository access problem we claim that the
  #     // same as if the reference was not an annotated tag.
  #     return ref;
  #   }
  # }
  #
  # /**
  #  * Get a map with all objects referenced by a peeled ref.
  #  *
  #  * @return a map with all objects referenced by a peeled ref.
  #  */
  # @NonNull
  # public Map<AnyObjectId, Set<Ref>> getAllRefsByPeeledObjectId() {
  #   Map<String, Ref> allRefs = getAllRefs();
  #   Map<AnyObjectId, Set<Ref>> ret = new HashMap<>(allRefs.size());
  #   for (Ref ref : allRefs.values()) {
  #     ref = peel(ref);
  #     AnyObjectId target = ref.getPeeledObjectId();
  #     if (target == null)
  #       target = ref.getObjectId();
  #     // We assume most Sets here are singletons
  #     Set<Ref> oset = ret.put(target, Collections.singleton(ref));
  #     if (oset != null) {
  #       // that was not the case (rare)
  #       if (oset.size() == 1) {
  #         // Was a read-only singleton, we must copy to a new Set
  #         oset = new HashSet<>(oset);
  #       }
  #       ret.put(target, oset);
  #       oset.add(ref);
  #     }
  #   }
  #   return ret;
  # }

  @doc ~S"""
  Get the path to the index file or `nil` if repository isn't local.

  Will return `nil` if there is no working tree (i.e. the repository is bare or
  there is no local representation of the repository).
  """
  def index_file!(repository) when is_pid(repository),
    do: GenServerUtils.call!(repository, :index_file)

  @doc ~S"""
  Invoked when `index_file!/1` is called on this repository.

  Should return the path to the index file if applicable, or raise
  `NoWorkTreeError` if not.
  """
  @callback handle_index_file(state :: term) :: String.t()

  # /**
  #  * Locate a reference to a commit and immediately parse its content.
  #  * <p>
  #  * This method only returns successfully if the commit object exists,
  #  * is verified to be a commit, and was parsed without error.
  #  *
  #  * @param id
  #  *            name of the commit object.
  #  * @return reference to the commit object. Never null.
  #  * @throws org.eclipse.jgit.errors.MissingObjectException
  #  *             the supplied commit does not exist.
  #  * @throws org.eclipse.jgit.errors.IncorrectObjectTypeException
  #  *             the supplied id is not a commit or an annotated tag.
  #  * @throws java.io.IOException
  #  *             a pack file or loose object could not be read.
  #  * @since 4.8
  #  */
  # public RevCommit parseCommit(AnyObjectId id) throws IncorrectObjectTypeException,
  #     IOException, MissingObjectException {
  #   if (id instanceof RevCommit && ((RevCommit) id).getRawBuffer() != null) {
  #     return (RevCommit) id;
  #   }
  #   try (RevWalk walk = new RevWalk(this)) {
  #     return walk.parseCommit(id);
  #   }
  # }
  #
  # /**
  #  * Create a new in-core index representation and read an index from disk.
  #  * <p>
  #  * The new index will be read before it is returned to the caller. Read
  #  * failures are reported as exceptions and therefore prevent the method from
  #  * returning a partially populated index.
  #  *
  #  * @return a cache representing the contents of the specified index file (if
  #  *         it exists) or an empty cache if the file does not exist.
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  * @throws java.io.IOException
  #  *             the index file is present but could not be read.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             the index file is using a format or extension that this
  #  *             library does not support.
  #  */
  # @NonNull
  # public DirCache readDirCache() throws NoWorkTreeException,
  #     CorruptObjectException, IOException {
  #   return DirCache.read(this);
  # }
  #
  # /**
  #  * Create a new in-core index representation, lock it, and read from disk.
  #  * <p>
  #  * The new index will be locked and then read before it is returned to the
  #  * caller. Read failures are reported as exceptions and therefore prevent
  #  * the method from returning a partially populated index.
  #  *
  #  * @return a cache representing the contents of the specified index file (if
  #  *         it exists) or an empty cache if the file does not exist.
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  * @throws java.io.IOException
  #  *             the index file is present but could not be read, or the lock
  #  *             could not be obtained.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException
  #  *             the index file is using a format or extension that this
  #  *             library does not support.
  #  */
  # @NonNull
  # public DirCache lockDirCache() throws NoWorkTreeException,
  #     CorruptObjectException, IOException {
  #   // we want DirCache to inform us so that we can inform registered
  #   // listeners about index changes
  #   IndexChangedListener l = new IndexChangedListener() {
  #     @Override
  #     public void onIndexChanged(IndexChangedEvent event) {
  #       notifyIndexChanged(true);
  #     }
  #   };
  #   return DirCache.lock(this, l);
  # }
  #
  # /**
  #  * Get the repository state
  #  *
  #  * @return the repository state
  #  */
  # @NonNull
  # public RepositoryState getRepositoryState() {
  #   if (isBare() || getDirectory() == null)
  #     return RepositoryState.BARE;
  #
  #   // Pre Git-1.6 logic
  #   if (new File(getWorkTree(), ".dotest").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING;
  #   if (new File(getDirectory(), ".dotest-merge").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING_INTERACTIVE;
  #
  #   // From 1.6 onwards
  #   if (new File(getDirectory(),"rebase-apply/rebasing").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING_REBASING;
  #   if (new File(getDirectory(),"rebase-apply/applying").exists()) //$NON-NLS-1$
  #     return RepositoryState.APPLY;
  #   if (new File(getDirectory(),"rebase-apply").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING;
  #
  #   if (new File(getDirectory(),"rebase-merge/interactive").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING_INTERACTIVE;
  #   if (new File(getDirectory(),"rebase-merge").exists()) //$NON-NLS-1$
  #     return RepositoryState.REBASING_MERGE;
  #
  #   // Both versions
  #   if (new File(getDirectory(), Constants.MERGE_HEAD).exists()) {
  #     // we are merging - now check whether we have unmerged paths
  #     try {
  #       if (!readDirCache().hasUnmergedPaths()) {
  #         // no unmerged paths -> return the MERGING_RESOLVED state
  #         return RepositoryState.MERGING_RESOLVED;
  #       }
  #     } catch (IOException e) {
  #       throw new UncheckedIOException(e);
  #     }
  #     return RepositoryState.MERGING;
  #   }
  #
  #   if (new File(getDirectory(), "BISECT_LOG").exists()) //$NON-NLS-1$
  #     return RepositoryState.BISECTING;
  #
  #   if (new File(getDirectory(), Constants.CHERRY_PICK_HEAD).exists()) {
  #     try {
  #       if (!readDirCache().hasUnmergedPaths()) {
  #         // no unmerged paths
  #         return RepositoryState.CHERRY_PICKING_RESOLVED;
  #       }
  #     } catch (IOException e) {
  #       throw new UncheckedIOException(e);
  #     }
  #
  #     return RepositoryState.CHERRY_PICKING;
  #   }
  #
  #   if (new File(getDirectory(), Constants.REVERT_HEAD).exists()) {
  #     try {
  #       if (!readDirCache().hasUnmergedPaths()) {
  #         // no unmerged paths
  #         return RepositoryState.REVERTING_RESOLVED;
  #       }
  #     } catch (IOException e) {
  #       throw new UncheckedIOException(e);
  #     }
  #
  #     return RepositoryState.REVERTING;
  #   }
  #
  #   return RepositoryState.SAFE;
  # }
  #
  # /**
  #  * Check validity of a ref name. It must not contain character that has
  #  * a special meaning in a Git object reference expression. Some other
  #  * dangerous characters are also excluded.
  #  *
  #  * For portability reasons '\' is excluded
  #  *
  #  * @param refName a {@link java.lang.String} object.
  #  * @return true if refName is a valid ref name
  #  */
  # public static boolean isValidRefName(String refName) {
  #   final int len = refName.length();
  #   if (len == 0) {
  #     return false;
  #   }
  #   if (refName.endsWith(LOCK_SUFFIX)) {
  #     return false;
  #   }
  #
  #   // Refs may be stored as loose files so invalid paths
  #   // on the local system must also be invalid refs.
  #   try {
  #     SystemReader.getInstance().checkPath(refName);
  #   } catch (CorruptObjectException e) {
  #     return false;
  #   }
  #
  #   int components = 1;
  #   char p = '\0';
  #   for (int i = 0; i < len; i++) {
  #     final char c = refName.charAt(i);
  #     if (c <= ' ')
  #       return false;
  #     switch (c) {
  #     case '.':
  #       switch (p) {
  #       case '\0': case '/': case '.':
  #         return false;
  #       }
  #       if (i == len -1)
  #         return false;
  #       break;
  #     case '/':
  #       if (i == 0 || i == len - 1)
  #         return false;
  #       if (p == '/')
  #         return false;
  #       components++;
  #       break;
  #     case '{':
  #       if (p == '@')
  #         return false;
  #       break;
  #     case '~': case '^': case ':':
  #     case '?': case '[': case '*':
  #     case '\\':
  #     case '\u007F':
  #       return false;
  #     }
  #     p = c;
  #   }
  #   return components > 1;
  # }
  #
  # /**
  #  * Normalizes the passed branch name into a possible valid branch name. The
  #  * validity of the returned name should be checked by a subsequent call to
  #  * {@link #isValidRefName(String)}.
  #  * <p>
  #  * Future implementations of this method could be more restrictive or more
  #  * lenient about the validity of specific characters in the returned name.
  #  * <p>
  #  * The current implementation returns the trimmed input string if this is
  #  * already a valid branch name. Otherwise it returns a trimmed string with
  #  * special characters not allowed by {@link #isValidRefName(String)}
  #  * replaced by hyphens ('-') and blanks replaced by underscores ('_').
  #  * Leading and trailing slashes, dots, hyphens, and underscores are removed.
  #  *
  #  * @param name
  #  *            to normalize
  #  * @return The normalized name or an empty String if it is {@code null} or
  #  *         empty.
  #  * @since 4.7
  #  * @see #isValidRefName(String)
  #  */
  # public static String normalizeBranchName(String name) {
  #   if (name == null || name.isEmpty()) {
  #     return ""; //$NON-NLS-1$
  #   }
  #   String result = name.trim();
  #   String fullName = result.startsWith(Constants.R_HEADS) ? result
  #       : Constants.R_HEADS + result;
  #   if (isValidRefName(fullName)) {
  #     return result;
  #   }
  #
  #   // All Unicode blanks to underscore
  #   result = result.replaceAll("(?:\\h|\\v)+", "_"); //$NON-NLS-1$ //$NON-NLS-2$
  #   StringBuilder b = new StringBuilder();
  #   char p = '/';
  #   for (int i = 0, len = result.length(); i < len; i++) {
  #     char c = result.charAt(i);
  #     if (c < ' ' || c == 127) {
  #       continue;
  #     }
  #     // Substitute a dash for problematic characters
  #     switch (c) {
  #     case '\\':
  #     case '^':
  #     case '~':
  #     case ':':
  #     case '?':
  #     case '*':
  #     case '[':
  #     case '@':
  #     case '<':
  #     case '>':
  #     case '|':
  #     case '"':
  #       c = '-';
  #       break;
  #     default:
  #       break;
  #     }
  #     // Collapse multiple slashes, dashes, dots, underscores, and omit
  #     // dashes, dots, and underscores following a slash.
  #     switch (c) {
  #     case '/':
  #       if (p == '/') {
  #         continue;
  #       }
  #       p = '/';
  #       break;
  #     case '.':
  #     case '_':
  #     case '-':
  #       if (p == '/' || p == '-') {
  #         continue;
  #       }
  #       p = '-';
  #       break;
  #     default:
  #       p = c;
  #       break;
  #     }
  #     b.append(c);
  #   }
  #   // Strip trailing special characters, and avoid the .lock extension
  #   result = b.toString().replaceFirst("[/_.-]+$", "") //$NON-NLS-1$ //$NON-NLS-2$
  #       .replaceAll("\\.lock($|/)", "_lock$1"); //$NON-NLS-1$ //$NON-NLS-2$
  #   return FORBIDDEN_BRANCH_NAME_COMPONENTS.matcher(result)
  #       .replaceAll("$1+$2$3"); //$NON-NLS-1$
  # }
  #
  # /**
  #  * Strip work dir and return normalized repository path.
  #  *
  #  * @param workDir
  #  *            Work dir
  #  * @param file
  #  *            File whose path shall be stripped of its workdir
  #  * @return normalized repository relative path or the empty string if the
  #  *         file is not relative to the work directory.
  #  */
  # @NonNull
  # public static String stripWorkDir(File workDir, File file) {
  #   final String filePath = file.getPath();
  #   final String workDirPath = workDir.getPath();
  #
  #   if (filePath.length() <= workDirPath.length() ||
  #       filePath.charAt(workDirPath.length()) != File.separatorChar ||
  #       !filePath.startsWith(workDirPath)) {
  #     File absWd = workDir.isAbsolute() ? workDir : workDir.getAbsoluteFile();
  #     File absFile = file.isAbsolute() ? file : file.getAbsoluteFile();
  #     if (absWd == workDir && absFile == file)
  #       return ""; //$NON-NLS-1$
  #     return stripWorkDir(absWd, absFile);
  #   }
  #
  #   String relName = filePath.substring(workDirPath.length() + 1);
  #   if (File.separatorChar != '/')
  #     relName = relName.replace(File.separatorChar, '/');
  #   return relName;
  # }
  #
  # /**
  #  * Whether this repository is bare
  #  *
  #  * @return true if this is bare, which implies it has no working directory.
  #  */
  # public boolean isBare() {
  #   return workTree == null;
  # }

  @doc ~S"""
  Get the root directory of the working tree.

  This is where files are checked out for viewing and editing.

  Will return `nil` if there is no working tree (i.e. the repository is bare or
  there is no local representation of the repository).
  """
  def work_tree!(repository) when is_pid(repository),
    do: GenServerUtils.call!(repository, :work_tree)

  @doc ~S"""
  Invoked when `work_tree!/1` is called on this repository.

  Should return the path to working tree directory if applicable, or `nil` if not.
  """
  @callback handle_work_tree(state :: term) :: String.t() | nil

  # /**
  #  * Force a scan for changed refs. Fires an IndexChangedEvent(false) if
  #  * changes are detected.
  #  *
  #  * @throws java.io.IOException
  #  */
  # public abstract void scanForRepoChanges() throws IOException;
  #
  # /**
  #  * Notify that the index changed by firing an IndexChangedEvent.
  #  *
  #  * @param internal
  #  *                     {@code true} if the index was changed by the same
  #  *                     JGit process
  #  * @since 5.0
  #  */
  # public abstract void notifyIndexChanged(boolean internal);
  #
  # /**
  #  * Get a shortened more user friendly ref name
  #  *
  #  * @param refName
  #  *            a {@link java.lang.String} object.
  #  * @return a more user friendly ref name
  #  */
  # @NonNull
  # public static String shortenRefName(String refName) {
  #   if (refName.startsWith(Constants.R_HEADS))
  #     return refName.substring(Constants.R_HEADS.length());
  #   if (refName.startsWith(Constants.R_TAGS))
  #     return refName.substring(Constants.R_TAGS.length());
  #   if (refName.startsWith(Constants.R_REMOTES))
  #     return refName.substring(Constants.R_REMOTES.length());
  #   return refName;
  # }
  #
  # /**
  #  * Get a shortened more user friendly remote tracking branch name
  #  *
  #  * @param refName
  #  *            a {@link java.lang.String} object.
  #  * @return the remote branch name part of <code>refName</code>, i.e. without
  #  *         the <code>refs/remotes/&lt;remote&gt;</code> prefix, if
  #  *         <code>refName</code> represents a remote tracking branch;
  #  *         otherwise {@code null}.
  #  * @since 3.4
  #  */
  # @Nullable
  # public String shortenRemoteBranchName(String refName) {
  #   for (String remote : getRemoteNames()) {
  #     String remotePrefix = Constants.R_REMOTES + remote + "/"; //$NON-NLS-1$
  #     if (refName.startsWith(remotePrefix))
  #       return refName.substring(remotePrefix.length());
  #   }
  #   return null;
  # }
  #
  # /**
  #  * Get remote name
  #  *
  #  * @param refName
  #  *            a {@link java.lang.String} object.
  #  * @return the remote name part of <code>refName</code>, i.e. without the
  #  *         <code>refs/remotes/&lt;remote&gt;</code> prefix, if
  #  *         <code>refName</code> represents a remote tracking branch;
  #  *         otherwise {@code null}.
  #  * @since 3.4
  #  */
  # @Nullable
  # public String getRemoteName(String refName) {
  #   for (String remote : getRemoteNames()) {
  #     String remotePrefix = Constants.R_REMOTES + remote + "/"; //$NON-NLS-1$
  #     if (refName.startsWith(remotePrefix))
  #       return remote;
  #   }
  #   return null;
  # }
  #
  # /**
  #  * Read the {@code GIT_DIR/description} file for gitweb.
  #  *
  #  * @return description text; null if no description has been configured.
  #  * @throws java.io.IOException
  #  *             description cannot be accessed.
  #  * @since 4.6
  #  */
  # @Nullable
  # public String getGitwebDescription() throws IOException {
  #   return null;
  # }
  #
  # /**
  #  * Set the {@code GIT_DIR/description} file for gitweb.
  #  *
  #  * @param description
  #  *            new description; null to clear the description.
  #  * @throws java.io.IOException
  #  *             description cannot be persisted.
  #  * @since 4.6
  #  */
  # public void setGitwebDescription(@Nullable String description)
  #     throws IOException {
  #   throw new IOException(JGitText.get().unsupportedRepositoryDescription);
  # }
  #
  # /**
  #  * Get the reflog reader
  #  *
  #  * @param refName
  #  *            a {@link java.lang.String} object.
  #  * @return a {@link org.eclipse.jgit.lib.ReflogReader} for the supplied
  #  *         refname, or {@code null} if the named ref does not exist.
  #  * @throws java.io.IOException
  #  *             the ref could not be accessed.
  #  * @since 3.0
  #  */
  # @Nullable
  # public abstract ReflogReader getReflogReader(String refName)
  #     throws IOException;
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/MERGE_MSG. In this
  #  * file operations triggering a merge will store a template for the commit
  #  * message of the merge commit.
  #  *
  #  * @return a String containing the content of the MERGE_MSG file or
  #  *         {@code null} if this file doesn't exist
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public String readMergeCommitMsg() throws IOException, NoWorkTreeException {
  #   return readCommitMsgFile(Constants.MERGE_MSG);
  # }
  #
  # /**
  #  * Write new content to the file $GIT_DIR/MERGE_MSG. In this file operations
  #  * triggering a merge will store a template for the commit message of the
  #  * merge commit. If <code>null</code> is specified as message the file will
  #  * be deleted.
  #  *
  #  * @param msg
  #  *            the message which should be written or <code>null</code> to
  #  *            delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeMergeCommitMsg(String msg) throws IOException {
  #   File mergeMsgFile = new File(gitDir, Constants.MERGE_MSG);
  #   writeCommitMsg(mergeMsgFile, msg);
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/COMMIT_EDITMSG. In
  #  * this file hooks triggered by an operation may read or modify the current
  #  * commit message.
  #  *
  #  * @return a String containing the content of the COMMIT_EDITMSG file or
  #  *         {@code null} if this file doesn't exist
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  * @since 4.0
  #  */
  # @Nullable
  # public String readCommitEditMsg() throws IOException, NoWorkTreeException {
  #   return readCommitMsgFile(Constants.COMMIT_EDITMSG);
  # }
  #
  # /**
  #  * Write new content to the file $GIT_DIR/COMMIT_EDITMSG. In this file hooks
  #  * triggered by an operation may read or modify the current commit message.
  #  * If {@code null} is specified as message the file will be deleted.
  #  *
  #  * @param msg
  #  *            the message which should be written or {@code null} to delete
  #  *            the file
  #  * @throws java.io.IOException
  #  * @since 4.0
  #  */
  # public void writeCommitEditMsg(String msg) throws IOException {
  #   File commiEditMsgFile = new File(gitDir, Constants.COMMIT_EDITMSG);
  #   writeCommitMsg(commiEditMsgFile, msg);
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/MERGE_HEAD. In this
  #  * file operations triggering a merge will store the IDs of all heads which
  #  * should be merged together with HEAD.
  #  *
  #  * @return a list of commits which IDs are listed in the MERGE_HEAD file or
  #  *         {@code null} if this file doesn't exist. Also if the file exists
  #  *         but is empty {@code null} will be returned
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public List<ObjectId> readMergeHeads() throws IOException, NoWorkTreeException {
  #   if (isBare() || getDirectory() == null)
  #     throw new NoWorkTreeException();
  #
  #   byte[] raw = readGitDirectoryFile(Constants.MERGE_HEAD);
  #   if (raw == null)
  #     return null;
  #
  #   LinkedList<ObjectId> heads = new LinkedList<>();
  #   for (int p = 0; p < raw.length;) {
  #     heads.add(ObjectId.fromString(raw, p));
  #     p = RawParseUtils
  #         .nextLF(raw, p + Constants.OBJECT_ID_STRING_LENGTH);
  #   }
  #   return heads;
  # }
  #
  # /**
  #  * Write new merge-heads into $GIT_DIR/MERGE_HEAD. In this file operations
  #  * triggering a merge will store the IDs of all heads which should be merged
  #  * together with HEAD. If <code>null</code> is specified as list of commits
  #  * the file will be deleted
  #  *
  #  * @param heads
  #  *            a list of commits which IDs should be written to
  #  *            $GIT_DIR/MERGE_HEAD or <code>null</code> to delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeMergeHeads(List<? extends ObjectId> heads) throws IOException {
  #   writeHeadsFile(heads, Constants.MERGE_HEAD);
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/CHERRY_PICK_HEAD.
  #  *
  #  * @return object id from CHERRY_PICK_HEAD file or {@code null} if this file
  #  *         doesn't exist. Also if the file exists but is empty {@code null}
  #  *         will be returned
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public ObjectId readCherryPickHead() throws IOException,
  #     NoWorkTreeException {
  #   if (isBare() || getDirectory() == null)
  #     throw new NoWorkTreeException();
  #
  #   byte[] raw = readGitDirectoryFile(Constants.CHERRY_PICK_HEAD);
  #   if (raw == null)
  #     return null;
  #
  #   return ObjectId.fromString(raw, 0);
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/REVERT_HEAD.
  #  *
  #  * @return object id from REVERT_HEAD file or {@code null} if this file
  #  *         doesn't exist. Also if the file exists but is empty {@code null}
  #  *         will be returned
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public ObjectId readRevertHead() throws IOException, NoWorkTreeException {
  #   if (isBare() || getDirectory() == null)
  #     throw new NoWorkTreeException();
  #
  #   byte[] raw = readGitDirectoryFile(Constants.REVERT_HEAD);
  #   if (raw == null)
  #     return null;
  #   return ObjectId.fromString(raw, 0);
  # }
  #
  # /**
  #  * Write cherry pick commit into $GIT_DIR/CHERRY_PICK_HEAD. This is used in
  #  * case of conflicts to store the cherry which was tried to be picked.
  #  *
  #  * @param head
  #  *            an object id of the cherry commit or <code>null</code> to
  #  *            delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeCherryPickHead(ObjectId head) throws IOException {
  #   List<ObjectId> heads = (head != null) ? Collections.singletonList(head)
  #       : null;
  #   writeHeadsFile(heads, Constants.CHERRY_PICK_HEAD);
  # }
  #
  # /**
  #  * Write revert commit into $GIT_DIR/REVERT_HEAD. This is used in case of
  #  * conflicts to store the revert which was tried to be picked.
  #  *
  #  * @param head
  #  *            an object id of the revert commit or <code>null</code> to
  #  *            delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeRevertHead(ObjectId head) throws IOException {
  #   List<ObjectId> heads = (head != null) ? Collections.singletonList(head)
  #       : null;
  #   writeHeadsFile(heads, Constants.REVERT_HEAD);
  # }
  #
  # /**
  #  * Write original HEAD commit into $GIT_DIR/ORIG_HEAD.
  #  *
  #  * @param head
  #  *            an object id of the original HEAD commit or <code>null</code>
  #  *            to delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeOrigHead(ObjectId head) throws IOException {
  #   List<ObjectId> heads = head != null ? Collections.singletonList(head)
  #       : null;
  #   writeHeadsFile(heads, Constants.ORIG_HEAD);
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/ORIG_HEAD.
  #  *
  #  * @return object id from ORIG_HEAD file or {@code null} if this file
  #  *         doesn't exist. Also if the file exists but is empty {@code null}
  #  *         will be returned
  #  * @throws java.io.IOException
  #  * @throws org.eclipse.jgit.errors.NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public ObjectId readOrigHead() throws IOException, NoWorkTreeException {
  #   if (isBare() || getDirectory() == null)
  #     throw new NoWorkTreeException();
  #
  #   byte[] raw = readGitDirectoryFile(Constants.ORIG_HEAD);
  #   return raw != null ? ObjectId.fromString(raw, 0) : null;
  # }
  #
  # /**
  #  * Return the information stored in the file $GIT_DIR/SQUASH_MSG. In this
  #  * file operations triggering a squashed merge will store a template for the
  #  * commit message of the squash commit.
  #  *
  #  * @return a String containing the content of the SQUASH_MSG file or
  #  *         {@code null} if this file doesn't exist
  #  * @throws java.io.IOException
  #  * @throws NoWorkTreeException
  #  *             if this is bare, which implies it has no working directory.
  #  *             See {@link #isBare()}.
  #  */
  # @Nullable
  # public String readSquashCommitMsg() throws IOException {
  #   return readCommitMsgFile(Constants.SQUASH_MSG);
  # }
  #
  # /**
  #  * Write new content to the file $GIT_DIR/SQUASH_MSG. In this file
  #  * operations triggering a squashed merge will store a template for the
  #  * commit message of the squash commit. If <code>null</code> is specified as
  #  * message the file will be deleted.
  #  *
  #  * @param msg
  #  *            the message which should be written or <code>null</code> to
  #  *            delete the file
  #  * @throws java.io.IOException
  #  */
  # public void writeSquashCommitMsg(String msg) throws IOException {
  #   File squashMsgFile = new File(gitDir, Constants.SQUASH_MSG);
  #   writeCommitMsg(squashMsgFile, msg);
  # }
  #
  # @Nullable
  # private String readCommitMsgFile(String msgFilename) throws IOException {
  #   if (isBare() || getDirectory() == null)
  #     throw new NoWorkTreeException();
  #
  #   File mergeMsgFile = new File(getDirectory(), msgFilename);
  #   try {
  #     return RawParseUtils.decode(IO.readFully(mergeMsgFile));
  #   } catch (FileNotFoundException e) {
  #     if (mergeMsgFile.exists()) {
  #       throw e;
  #     }
  #     // the file has disappeared in the meantime ignore it
  #     return null;
  #   }
  # }
  #
  # private void writeCommitMsg(File msgFile, String msg) throws IOException {
  #   if (msg != null) {
  #     try (FileOutputStream fos = new FileOutputStream(msgFile)) {
  #       fos.write(msg.getBytes(UTF_8));
  #     }
  #   } else {
  #     FileUtils.delete(msgFile, FileUtils.SKIP_MISSING);
  #   }
  # }
  #
  # /**
  #  * Read a file from the git directory.
  #  *
  #  * @param filename
  #  * @return the raw contents or {@code null} if the file doesn't exist or is
  #  *         empty
  #  * @throws IOException
  #  */
  # private byte[] readGitDirectoryFile(String filename) throws IOException {
  #   File file = new File(getDirectory(), filename);
  #   try {
  #     byte[] raw = IO.readFully(file);
  #     return raw.length > 0 ? raw : null;
  #   } catch (FileNotFoundException notFound) {
  #     if (file.exists()) {
  #       throw notFound;
  #     }
  #     return null;
  #   }
  # }
  #
  # /**
  #  * Write the given heads to a file in the git directory.
  #  *
  #  * @param heads
  #  *            a list of object ids to write or null if the file should be
  #  *            deleted.
  #  * @param filename
  #  * @throws FileNotFoundException
  #  * @throws IOException
  #  */
  # private void writeHeadsFile(List<? extends ObjectId> heads, String filename)
  #     throws FileNotFoundException, IOException {
  #   File headsFile = new File(getDirectory(), filename);
  #   if (heads != null) {
  #     try (OutputStream bos = new BufferedOutputStream(
  #         new FileOutputStream(headsFile))) {
  #       for (ObjectId id : heads) {
  #         id.copyTo(bos);
  #         bos.write('\n');
  #       }
  #     }
  #   } else {
  #     FileUtils.delete(headsFile, FileUtils.SKIP_MISSING);
  #   }
  # }
  #
  # /**
  #  * Read a file formatted like the git-rebase-todo file. The "done" file is
  #  * also formatted like the git-rebase-todo file. These files can be found in
  #  * .git/rebase-merge/ or .git/rebase-append/ folders.
  #  *
  #  * @param path
  #  *            path to the file relative to the repository's git-dir. E.g.
  #  *            "rebase-merge/git-rebase-todo" or "rebase-append/done"
  #  * @param includeComments
  #  *            <code>true</code> if also comments should be reported
  #  * @return the list of steps
  #  * @throws java.io.IOException
  #  * @since 3.2
  #  */
  # @NonNull
  # public List<RebaseTodoLine> readRebaseTodo(String path,
  #     boolean includeComments)
  #     throws IOException {
  #   return new RebaseTodoFile(this).readRebaseTodo(path, includeComments);
  # }
  #
  # /**
  #  * Write a file formatted like a git-rebase-todo file.
  #  *
  #  * @param path
  #  *            path to the file relative to the repository's git-dir. E.g.
  #  *            "rebase-merge/git-rebase-todo" or "rebase-append/done"
  #  * @param steps
  #  *            the steps to be written
  #  * @param append
  #  *            whether to append to an existing file or to write a new file
  #  * @throws java.io.IOException
  #  * @since 3.2
  #  */
  # public void writeRebaseTodoFile(String path, List<RebaseTodoLine> steps,
  #     boolean append)
  #     throws IOException {
  #   new RebaseTodoFile(this).writeRebaseTodoFile(path, steps, append);
  # }
  #
  # /**
  #  * Get the names of all known remotes
  #  *
  #  * @return the names of all known remotes
  #  * @since 3.4
  #  */
  # @NonNull
  # public Set<String> getRemoteNames() {
  #   return getConfig()
  #       .getSubsections(ConfigConstants.CONFIG_REMOTE_SECTION);
  # }
  #
  # /**
  #  * Check whether any housekeeping is required; if yes, run garbage
  #  * collection; if not, exit without performing any work. Some JGit commands
  #  * run autoGC after performing operations that could create many loose
  #  * objects.
  #  * <p>
  #  * Currently this option is supported for repositories of type
  #  * {@code FileRepository} only. See
  #  * {@link org.eclipse.jgit.internal.storage.file.GC#setAuto(boolean)} for
  #  * configuration details.
  #  *
  #  * @param monitor
  #  *            to report progress
  #  * @since 4.6
  #  */
  # public void autoGC(ProgressMonitor monitor) {
  #   // default does nothing
  # }

  def handle_call({:create, opts}, _from, {mod, mod_state}) when is_list(opts),
    do: GenServerUtils.delegate_call_to(mod, :handle_create, [mod_state, opts], mod_state)

  def handle_call(:git_dir, _from, {mod, mod_state}),
    do: GenServerUtils.delegate_call_to(mod, :handle_git_dir, [mod_state], mod_state)

  def handle_call(:work_tree, _from, {mod, mod_state}),
    do: GenServerUtils.delegate_call_to(mod, :handle_work_tree, [mod_state], mod_state)

  def handle_call(:index_file, _from, {mod, mod_state}),
    do: GenServerUtils.delegate_call_to(mod, :handle_index_file, [mod_state], mod_state)

  def handle_call(:object_database, _from, {mod, mod_state}),
    do: GenServerUtils.delegate_call_to(mod, :handle_object_database, [mod_state], mod_state)

  def handle_call(message, _from, state) do
    Logger.warn("Repository received unrecognized call #{inspect(message)}")
    {:reply, {:error, :unknown_message}, state}
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts

      alias Xgit.Errors.NoWorkTreeError
      alias Xgit.Lib.Repository

      def handle_git_dir(state), do: {:ok, nil, state}
      def handle_work_tree(state), do: {:ok, nil, state}
      def handle_index_file(state), do: raise(NoWorkTreeError, [])
      def handle_object_database(state), do: raise(NoWorkTreeError, [])

      defoverridable handle_git_dir: 1,
                     handle_index_file: 1,
                     handle_work_tree: 1,
                     handle_object_database: 1
    end
  end
end
