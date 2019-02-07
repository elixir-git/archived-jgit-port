defmodule Xgit.Lib.Constants do
  @moduledoc ~S"""
  Miscellaneous constants used throughout Xgit.
  """

  @doc ~S"""
  A Git object hash is 160 bits, i.e. 20 bytes.

  Changing this assumption is not going to be as easy as changing this declaration.
  """
  def object_id_length, do: 20

  @doc ~S"""
  A Git object can be expressed as a 40 character string of hexadecimal digits.
  """
  def object_id_string_length, do: object_id_length() * 2

  @doc "Special name for the \"HEAD\" symbolic-ref."
  def head, do: "HEAD"

  @doc "Special name for the \"FETCH_HEAD\" symbolic-ref."
  def fetch_head, do: "FETCH_HEAD"

  @doc ~S"""
  Text string that identifies an object as a commit.

  Commits connect trees into a string of project histories, where each
  commit is an assertion that the best way to continue is to use this other
  tree (set of files).
  """
  def type_commit, do: "commit"

  @doc ~S"""
  Text string that identifies an object as a blob.

  Blobs store whole file revisions. They are used for any user file, as
  well as for symlinks. Blobs form the bulk of any project's storage space.
  """
  def type_blob, do: "blob"

  @doc ~S"""
  Text string that identifies an object as a tree.

  Trees attach object ids (hashes) to names and file modes. The normal use
  for a tree is to store a version of a directory and its contents.
  """
  def type_tree, do: "tree"

  @doc ~S"""
  Text string that identifies an object as an annotated tag.

  Annotated tags store a pointer to any other object, and an additional
  message. It is most commonly used to record a stable release of the
  project.
  """
  def type_tag, do: "tag"

  @doc "An unknown or invalid object type code."
  def obj_bad, do: -1

  @doc ~S"""
  In-pack object type: extended types.

  This header code is reserved for future expansion. It is currently
  undefined/unsupported.
  """
  def obj_ext, do: 0

  @doc ~S"""
  In-pack object type: commit.

  Indicates the associated object is a commit.

  *This constant is fixed and is defined by the Git packfile format.*

  See `type_commit/0`.
  """
  def obj_commit, do: 1

  @doc ~S"""
  In-pack object type: tree.

  Indicates the associated object is a tree.

  *This constant is fixed and is defined by the Git packfile format.*

  See `type_tree/0`.
  """
  def obj_tree, do: 2

  @doc ~S"""
  In-pack object type: blob.

  Indicates the associated object is a blob.

  *This constant is fixed and is defined by the Git packfile format.*

  See `type_blob/0`.
  """
  def obj_blob, do: 3

  @doc ~S"""
  In-pack object type: annotated tag.

  Indicates the associated object is an annotated tag.

  *This constant is fixed and is defined by the Git packfile format.*

  See `type_tag/0`.
  """
  def obj_tag, do: 4

  @doc "In-pack object type: reserved for future use."
  def obj_type_5, do: 5

  @doc ~S"""
  In-pack object type: offset delta

  Objects stored with this type actually have a different type which must
  be obtained from their delta base object. Delta objects store only the
  changes needed to apply to the base object in order to recover the
  original object.

  An offset delta uses a negative offset from the start of this object to
  refer to its delta base. The base object must exist in this packfile
  (even in the case of a thin pack).

  *This constant is fixed and is defined by the Git packfile format.*
  """
  def obj_ofs_delta, do: 6

  @doc ~S"""
  In-pack object type: reference delta

  Objects stored with this type actually have a different type which must
  be obtained from their delta base object. Delta objects store only the
  changes needed to apply to the base object in order to recover the
  original object.

  A reference delta uses a full object id (hash) to reference the delta
  base. The base object is allowed to be omitted from the packfile, but
  only in the case of a thin pack being transferred over the network.

  *This constant is fixed and is defined by the Git packfile format.*
  """
  def obj_ref_delta, do: 7

  @doc ~S"""
  Pack file signature that occurs at file header - identifies file as Git
  packfile formatted.

  *This constant is fixed and is defined by the Git packfile format.*
  """
  def pack_signature, do: 'PACK'

  @doc "Default main branch name."
  def master, do: "master"

  @doc "Default stash branch name."
  def stash, do: "stash"

  @doc "Prefix for branch refs."
  def r_heads, do: "refs/heads/"

  @doc "Prefix for remotes refs."
  def r_remotes, do: "refs/remotes/"

  @doc "Prefix for tag refs."
  def r_tags, do: "refs/tags/"

  @doc "Prefix for notes refs."
  def r_notes, do: "refs/notes/"

  @doc "Standard notes ref."
  def r_notes_commits, do: "#{r_notes()}commits"

  @doc "Prefix for any ref."
  def r_refs, do: "refs/"

  @doc "Standard stash ref."
  def r_stash, do: "#{r_refs()}#{stash()}"

  @doc "Logs folder name."
  def logs, do: "logs"

  @doc "Info refs folder."
  def info_refs, do: "info/refs"

  @doc "Packed refs file."
  def packed_refs, do: "packed-refs"

  @doc "Excludes-file."
  def info_exclude, do: "info/exclude"

  @doc "Attributes-override-file."
  def info_attributes, do: "info/attributes"

  # /**
  #  * The system property that contains the system user name
  #  *
  #  * @since 3.6
  #  */
  # public static final String OS_USER_DIR = "user.dir";
  #
  # /** The system property that contains the system user name */
  # public static final String OS_USER_NAME_KEY = "user.name";

  @doc "The environment variable that contains the author's name."
  def git_author_name_key, do: "GIT_AUTHOR_NAME"

  @doc "The environment variable that contains the author's email."
  def git_author_email_key, do: "GIT_AUTHOR_EMAIL"

  @doc "The environment variable that contains the commiter's name."
  def git_committer_name_key, do: "GIT_COMMITTER_NAME"

  @doc "The environment variable that contains the commiter's email."
  def git_committer_email_key, do: "GIT_COMMITTER_EMAIL"

  @doc "The environment variable that blocks use of the system config file."
  def git_config_nosystem_key, do: "GIT_CONFIG_NOSYSTEM"

  @doc ~S"""
  The environment variable that limits how close to the root of the file
  systems JGit will traverse when looking for a repository root.
  """
  def git_ceiling_directories_key, do: "GIT_CEILING_DIRECTORIES"

  @doc ~S"""
  The environment variable that tells us which directory is the `".git"`
  directory.
  """
  def git_dir_key, do: "GIT_DIR"

  @doc ~S"""
  The environment variable that tells us which directory is the working
  directory.
  """
  def git_work_tree_key, do: "GIT_WORK_TREE"

  @doc "The environment variable that tells us which file holds the Git index."
  def git_index_file_key, do: "GIT_INDEX_FILE"

  @doc "The environment variable that tells us where objects are stored."
  def git_object_directory_key, do: "GIT_OBJECT_DIRECTORY"

  @doc ~S"""
  The environment variable that tells us where to look for objects, besides
  the default objects directory.
  """
  def git_alternate_object_directories_key, do: "GIT_ALTERNATE_OBJECT_DIRECTORIES"

  @doc "Default value for the user name if no other information is available."
  def unknown_user_default, do: "unknown-user"

  @doc "Beginning of the common \"Signed-off-by: \" commit message line."
  def signed_off_by_tag, do: "Signed-off-by: "

  @doc "A gitignore file name."
  def gitignore_filename, do: ".gitignore"

  @doc "Default remote name used by clone, push and fetch operations."
  def default_remote_name, do: "origin"

  @doc "Default name for the Git repository directory."
  def dot_git, do: ".git"

  @doc "Default name for the Git repository configuration."
  def config, do: "config"

  @doc "A bare repository typically ends with this string."
  def dot_git_ext, do: ".git"

  @doc "Name of the attributes file."
  def dot_git_attributes, do: ".gitattributes"

  @doc "Key for filters in .gitattributes."
  def attr_filter, do: "filter"

  @doc "`clean` command name; used to call filter driver."
  def attr_filter_type_clean, do: "clean"

  @doc "`smudge` command name; used to call filter driver."
  def attr_filter_type_smudge, do: "smudge"

  # /**
  #  * Builtin filter commands start with this prefix
  #  *
  #  * @since 4.6
  #  */
  # public static final String BUILTIN_FILTER_PREFIX = "jgit://builtin/";

  @doc "Name of the ignore file."
  def dot_git_ignore, do: ".gitignore"

  @doc "Name of the submodules file."
  def dot_git_modules, do: ".gitmodules"

  @doc "Name of the .git/shallow file."
  def shallow, do: "shallow"

  @doc "Prefix of the first line in a `.git` file."
  def gitdir, do: "gitdir: "

  @doc "Name of the folder (inside gitdir) where submodules are stored."
  def modules, do: "modules"

  @doc "Name of the folder (inside gitdir) where the hooks are stored."
  def hooks, do: "hooks"

  @doc "Merge attribute."
  def attr_merge, do: "merge"

  @doc "Diff attribute."
  def attr_diff, do: "diff"

  @doc "Binary value for custom merger."
  def attr_built_in_binary_merger, do: "binary"

  # /**
  #  * Create a new digest function for objects.
  #  *
  #  * @return a new digest object.
  #  * @throws java.lang.RuntimeException
  #  *             this Java virtual machine does not support the required hash
  #  *             function. Very unlikely given that JGit uses a hash function
  #  *             that is in the Java reference specification.
  #  */
  # public static MessageDigest newMessageDigest() {
  # 	try {
  # 		return MessageDigest.getInstance(HASH_FUNCTION);
  # 	} catch (NoSuchAlgorithmException nsae) {
  # 		throw new RuntimeException(MessageFormat.format(
  # 				JGitText.get().requiredHashFunctionNotAvailable, HASH_FUNCTION), nsae);
  # 	}
  # }

  @doc ~S"""
  Convert an `obj_*` (numeric) type constant to the canonical string name for that type.
  """
  def type_string(type_code)

  def type_string(1), do: type_commit()
  def type_string(2), do: type_tree()
  def type_string(3), do: type_blob()
  def type_string(4), do: type_tag()

  @doc ~S"""
  Convert an `obj_*` (numeric) type constant to an ASCII-encoded charlist constant.

  The ASCII encoded string is often the canonical representation of
  the type within a loose object header, or within a tag header.
  """
  def encoded_type_string(type_code) do
    type_code
    |> type_string()
    |> to_charlist()
  end

  @doc ~S"""
  Parse an encoded type string into a type constant.

  `id` is the object ID this type string came from; may be `nil` if that is not
  known at the time the parse is occurring.

  `type_string` is the string version of the type code.

  `end_mark` is the character immediately following the type string. Usually
  `' '` (space) or `'\n'` (line feed).

  Returns `{type, remainder}` where `type` is one of `obj_blob/0`, `obj_commit/0`,
  `obj_tag/0`, or `obj_tree/0` and `remainder` is what remains of `type_string`
  following what was parsed.

  Raises `Xgit.Errors.CorruptObjectError` if there is no valid type identified
  by `type_string`.
  """
  def decode_type_string(id, type_string, end_mark)

  def decode_type_string(_id, [?b, ?l, ?o, ?b, end_mark | r], end_mark), do: {obj_blob(), r}

  def decode_type_string(_id, [?c, ?o, ?m, ?m, ?i, ?t, end_mark | r], end_mark),
    do: {obj_commit(), r}

  def decode_type_string(_id, [?t, ?a, ?g, end_mark | r], end_mark), do: {obj_tag(), r}
  def decode_type_string(_id, [?t, ?r, ?e, ?e, end_mark | r], end_mark), do: {obj_tree(), r}

  def decode_type_string(id, _type_string, _end_mark),
    do: raise(Xgit.Errors.CorruptObjectError, id: id, why: "invalid type")

  @doc ~S"""
  Convert a string or integer into its US-ASCII (charlist) representation.

  If `value` is a string containing non-ASCII characters, raises `ArgumentError`.
  """
  def encode_ascii(value)

  def encode_ascii(n) when is_integer(n), do: Integer.to_charlist(n)

  def encode_ascii(s) when is_binary(s) do
    if String.match?(s, ~r/^[\x00-\x7F]+$/) do
      to_charlist(s)
    else
      raise ArgumentError, message: "Not ASCII string: #{s}"
    end
  end

  @doc "Name of the file containing the commit message for a merge commit."
  def merge_msg, do: "MERGE_MSG"

  @doc "Name of the file containing the IDs of the parents of a merge commit."
  def merge_head, do: "MERGE_HEAD"

  @doc "Name of the file containing the ID of a cherry pick commit in case of conflicts."
  def cherry_pick_head, do: "CHERRY_PICK_HEAD"

  @doc "Name of the file containing the commit message for a squash commit."
  def squash_msg, do: "SQUASH_MSG"

  @doc "Name of the file containing the ID of a revert commit in case of conflicts."
  def revert_head, do: "REVERT_HEAD"

  @doc "Name of the ref ORIG_HEAD used by certain commands to store the original value of HEAD."
  def orig_head, do: "ORIG_HEAD"

  @doc ~S"""
  Name of the file in which git commands and hooks store and read the
  message prepared for the upcoming commit.
  """
  def commit_edit_msg, do: "COMMIT_EDITMSG"

  @doc "Well-known object ID for the empty blob."
  def empty_blob_id, do: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"

  @doc "Well-known object ID for the empty tree."
  def empty_tree_id, do: "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  @doc "Suffix of lock file name."
  def lock_suffix, do: ".lock"
end
