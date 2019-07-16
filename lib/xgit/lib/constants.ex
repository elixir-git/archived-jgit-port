# Copyright (C) 2008, Google Inc.
# Copyright (C) 2008, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2017, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/Constants.java
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

defmodule Xgit.Lib.Constants do
  @moduledoc ~S"""
  Miscellaneous constants and helpers used throughout Xgit.
  """

  @doc ~S"""
  A git object hash is 160 bits, i.e. 20 bytes.

  Changing this assumption is not going to be as easy as changing this declaration.
  """
  @spec object_id_length :: integer
  def object_id_length, do: 20

  @doc ~S"""
  A git object can be expressed as a 40-character string of hexadecimal digits.
  """
  @spec object_id_string_length :: integer
  def object_id_string_length, do: object_id_length() * 2

  @doc "Special name for the `HEAD` symbolic-ref."
  @spec head :: String.t()
  def head, do: "HEAD"

  @doc "Special name for the `FETCH_HEAD` symbolic-ref."
  @spec fetch_head :: String.t()
  def fetch_head, do: "FETCH_HEAD"

  @doc ~S"""
  Text string that identifies an object as a commit.

  Commits connect trees into a string of project histories, where each
  commit is an assertion that the best way to continue is to use this other
  tree (set of files).
  """
  @spec type_commit :: String.t()
  def type_commit, do: "commit"

  @doc ~S"""
  Text string that identifies an object as a blob.

  Blobs store whole file revisions. They are used for any user file, as
  well as for symlinks. Blobs form the bulk of any project's storage space.
  """
  @spec type_blob :: String.t()
  def type_blob, do: "blob"

  @doc ~S"""
  Text string that identifies an object as a tree.

  Trees attach object IDs (hashes) to names and file modes. The normal use
  for a tree is to store a version of a directory and its contents.
  """
  @spec type_tree :: String.t()
  def type_tree, do: "tree"

  @doc ~S"""
  Text string that identifies an object as an annotated tag.

  Annotated tags store a pointer to any other object, and an additional
  message. It is most commonly used to record a stable release of the
  project.
  """
  @spec type_tag :: String.t()
  def type_tag, do: "tag"

  @typedoc "In-pack object type values. See `obj_*` functions."
  @type obj_type :: 0..7
  # Intentionally not including obj_bad because that isn't a valid type.

  @doc "An unknown or invalid object type code."
  @spec obj_bad :: integer
  def obj_bad, do: -1

  @doc ~S"""
  In-pack object type: extended types.

  This header code is reserved for future expansion. It is currently
  undefined/unsupported.
  """
  @spec obj_ext :: integer
  def obj_ext, do: 0

  @doc ~S"""
  In-pack object type: commit.

  Indicates the associated object is a commit.

  *This constant is fixed and is defined by the git packfile format.*

  See `type_commit/0`.
  """
  @spec obj_commit :: integer
  def obj_commit, do: 1

  @doc ~S"""
  In-pack object type: tree.

  Indicates the associated object is a tree.

  *This constant is fixed and is defined by the git packfile format.*

  See `type_tree/0`.
  """
  @spec obj_tree :: integer
  def obj_tree, do: 2

  @doc ~S"""
  In-pack object type: blob.

  Indicates the associated object is a blob.

  *This constant is fixed and is defined by the git packfile format.*

  See `type_blob/0`.
  """
  @spec obj_blob :: integer
  def obj_blob, do: 3

  @doc ~S"""
  In-pack object type: annotated tag.

  Indicates the associated object is an annotated tag.

  *This constant is fixed and is defined by the git packfile format.*

  See `type_tag/0`.
  """
  @spec obj_tag :: integer
  def obj_tag, do: 4

  @doc "In-pack object type: reserved for future use."
  @spec obj_type_5 :: integer
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

  *This constant is fixed and is defined by the git packfile format.*
  """
  @spec obj_ofs_delta :: integer
  def obj_ofs_delta, do: 6

  @doc ~S"""
  In-pack object type: reference delta

  Objects stored with this type actually have a different type which must
  be obtained from their delta base object. Delta objects store only the
  changes needed to apply to the base object in order to recover the
  original object.

  A reference delta uses a full object ID (hash) to reference the delta
  base. The base object is allowed to be omitted from the packfile, but
  only in the case of a thin pack being transferred over the network.

  *This constant is fixed and is defined by the git packfile format.*
  """
  @spec obj_ref_delta :: integer
  def obj_ref_delta, do: 7

  @doc ~S"""
  Pack file signature that occurs at file header. This identifies the file as git
  packfile formatted.

  *This constant is fixed and is defined by the git packfile format.*
  """
  @spec pack_signature :: charlist
  def pack_signature, do: 'PACK'

  @doc "Default main branch name."
  @spec master :: String.t()
  def master, do: "master"

  @doc "Default stash branch name."
  @spec stash :: String.t()
  def stash, do: "stash"

  @doc "Prefix for branch refs."
  @spec r_heads :: String.t()
  def r_heads, do: "refs/heads/"

  @doc "Prefix for remotes refs."
  @spec r_remotes :: String.t()
  def r_remotes, do: "refs/remotes/"

  @doc "Prefix for tag refs."
  @spec r_tags :: String.t()
  def r_tags, do: "refs/tags/"

  @doc "Prefix for notes refs."
  @spec r_notes :: String.t()
  def r_notes, do: "refs/notes/"

  @doc "Standard notes ref."
  @spec r_notes_commits :: String.t()
  def r_notes_commits, do: "#{r_notes()}commits"

  @doc "Prefix for any ref."
  @spec r_refs :: String.t()
  def r_refs, do: "refs/"

  @doc "Standard stash ref."
  @spec r_stash :: String.t()
  def r_stash, do: "#{r_refs()}#{stash()}"

  @doc "Logs folder name."
  @spec logs :: String.t()
  def logs, do: "logs"

  @doc "Info refs folder."
  @spec info_refs :: String.t()
  def info_refs, do: "info/refs"

  @doc "Packed refs file."
  @spec packed_refs :: String.t()
  def packed_refs, do: "packed-refs"

  @doc "Excludes file."
  @spec info_exclude :: String.t()
  def info_exclude, do: "info/exclude"

  @doc "Attributes override file."
  @spec info_attributes :: String.t()
  def info_attributes, do: "info/attributes"

  # IMPORTANT: Per Xgit policy, we do not use the current working directory
  # nor the directory from which the Elixir app was started as a default.
  # Therefore, the jgit constant OS_USER_DIR and the Java system property "user.dir"
  # are not available in Xgit.

  # /** The system property that contains the system user name */
  # public static final String OS_USER_NAME_KEY = "user.name";

  @doc "The environment variable that contains the author's name."
  @spec git_author_name_key :: String.t()
  def git_author_name_key, do: "GIT_AUTHOR_NAME"

  @doc "The environment variable that contains the author's email."
  @spec git_author_email_key :: String.t()
  def git_author_email_key, do: "GIT_AUTHOR_EMAIL"

  @doc "The environment variable that contains the commiter's name."
  @spec git_committer_name_key :: String.t()
  def git_committer_name_key, do: "GIT_COMMITTER_NAME"

  @doc "The environment variable that contains the commiter's email."
  @spec git_committer_email_key :: String.t()
  def git_committer_email_key, do: "GIT_COMMITTER_EMAIL"

  @doc "The environment variable that blocks use of the system config file."
  @spec git_config_nosystem_key :: String.t()
  def git_config_nosystem_key, do: "GIT_CONFIG_NOSYSTEM"

  @doc ~S"""
  The environment variable that limits how close to the root of the file
  systems Xgit will traverse when looking for a repository root.
  """
  @spec git_ceiling_directories_key :: String.t()
  def git_ceiling_directories_key, do: "GIT_CEILING_DIRECTORIES"

  @doc ~S"""
  The environment variable that tells us which directory is the `.git`
  directory.
  """
  @spec git_dir_key :: String.t()
  def git_dir_key, do: "GIT_DIR"

  @doc ~S"""
  The environment variable that tells us which directory is the working
  directory.
  """
  @spec git_work_tree_key :: String.t()
  def git_work_tree_key, do: "GIT_WORK_TREE"

  @doc "The environment variable that tells us which file holds the git index."
  @spec git_index_file_key :: String.t()
  def git_index_file_key, do: "GIT_INDEX_FILE"

  @doc "The environment variable that tells us where objects are stored."
  @spec git_object_directory_key :: String.t()
  def git_object_directory_key, do: "GIT_OBJECT_DIRECTORY"

  @doc ~S"""
  The environment variable that tells us where to look for objects, besides
  the default objects directory.
  """
  @spec git_alternate_object_directories_key :: String.t()
  def git_alternate_object_directories_key, do: "GIT_ALTERNATE_OBJECT_DIRECTORIES"

  @doc "Default value for the user name if no other information is available."
  @spec unknown_user_default :: String.t()
  def unknown_user_default, do: "unknown-user"

  @doc "Beginning of the common `Signed-off-by: ` commit message line."
  @spec signed_off_by_tag :: String.t()
  def signed_off_by_tag, do: "Signed-off-by: "

  @doc "A gitignore file name."
  @spec gitignore_filename :: String.t()
  def gitignore_filename, do: ".gitignore"

  @doc "Default remote name used by clone, push, and fetch operations."
  @spec default_remote_name :: String.t()
  def default_remote_name, do: "origin"

  @doc "Default name for the git repository directory."
  @spec dot_git :: String.t()
  def dot_git, do: ".git"

  @doc "Default name for the git repository configuration."
  @spec config :: String.t()
  def config, do: "config"

  @doc "A bare repository typically ends with this string."
  @spec dot_git_ext :: String.t()
  def dot_git_ext, do: ".git"

  @doc "Name of the attributes file."
  @spec dot_git_attributes :: String.t()
  def dot_git_attributes, do: ".gitattributes"

  @doc "Key for filters in .gitattributes."
  @spec attr_filter :: String.t()
  def attr_filter, do: "filter"

  @doc "`clean` command name; used to call filter driver."
  @spec attr_filter_type_clean :: String.t()
  def attr_filter_type_clean, do: "clean"

  @doc "`smudge` command name; used to call filter driver."
  @spec attr_filter_type_smudge :: String.t()
  def attr_filter_type_smudge, do: "smudge"

  # /**
  #  * Builtin filter commands start with this prefix
  #  *
  #  * @since 4.6
  #  */
  # public static final String BUILTIN_FILTER_PREFIX = "jgit://builtin/";

  @doc "Name of the ignore file."
  @spec dot_git_ignore :: String.t()
  def dot_git_ignore, do: ".gitignore"

  @doc "Name of the submodules file."
  @spec dot_git_modules :: String.t()
  def dot_git_modules, do: ".gitmodules"

  @doc "Name of the .git/shallow file."
  @spec shallow :: String.t()
  def shallow, do: "shallow"

  @doc "Prefix of the first line in a `.git` file."
  @spec gitdir :: String.t()
  def gitdir, do: "gitdir: "

  @doc "Name of the folder (inside `gitdir/0`) where submodules are stored."
  @spec modules :: String.t()
  def modules, do: "modules"

  @doc "Name of the folder (inside `gitdir/0`) where the hooks are stored."
  @spec hooks :: String.t()
  def hooks, do: "hooks"

  @doc "Merge attribute."
  @spec attr_merge :: String.t()
  def attr_merge, do: "merge"

  @doc "Diff attribute."
  @spec attr_diff :: String.t()
  def attr_diff, do: "diff"

  @doc "Binary value for custom merger."
  @spec attr_built_in_binary_merger :: String.t()
  def attr_built_in_binary_merger, do: "binary"

  # TO DO: https://github.com/elixir-git/archived-jgit-port/issues/130
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
  #   try {
  #     return MessageDigest.getInstance(HASH_FUNCTION);
  #   } catch (NoSuchAlgorithmException nsae) {
  #     throw new RuntimeException(MessageFormat.format(
  #         JGitText.get().requiredHashFunctionNotAvailable, HASH_FUNCTION), nsae);
  #   }
  # }

  @doc ~S"""
  Convert an `obj_*` (numeric) type constant to the canonical string name for that type.
  """
  @spec type_string(type_code :: integer) :: String.t()
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
  @spec encoded_type_string(type_code :: integer) :: charlist
  def encoded_type_string(type_code) do
    type_code
    |> type_string()
    |> to_charlist()
  end

  @doc ~S"""
  Parse an encoded type string into a type constant.

  ## Parameters

  `id` is the object ID this type string came from; may be `nil` if that is not
  known at the time the parse is occurring.

  `type_string` is the charlist version of the type code.

  `end_mark` is the character immediately following the type string. Usually
  space or `\n` (line feed).

  ## Return Values

  `{type, remainder}` where `type` is one of `obj_blob/0`, `obj_commit/0`,
  `obj_tag/0`, or `obj_tree/0` and `remainder` is what remains of `type_string`
  following what was parsed.

  ## Errors

  Raises `Xgit.Errors.CorruptObjectError` if there is no valid type identified
  by `type_string`.
  """
  @spec decode_type_string(id :: String.t(), type_string :: charlist, end_mark :: char) ::
          {integer, charlist}
  def decode_type_string(id, type_string, end_mark)

  def decode_type_string(_id, [?c, ?o, ?m, ?m, ?i, ?t, end_mark | r], end_mark),
    do: {obj_commit(), r}

  def decode_type_string(_id, [?t, ?r, ?e, ?e, end_mark | r], end_mark),
    do: {obj_tree(), r}

  def decode_type_string(_id, [?b, ?l, ?o, ?b, end_mark | r], end_mark),
    do: {obj_blob(), r}

  def decode_type_string(_id, [?t, ?a, ?g, end_mark | r], end_mark),
    do: {obj_tag(), r}

  def decode_type_string(id, _type_string, _end_mark),
    do: raise(Xgit.Errors.CorruptObjectError, id: id, why: "invalid type")

  @doc ~S"""
  Convert a string or integer into its US-ASCII (charlist) representation.

  If `value` is a string containing non-ASCII characters, raises `ArgumentError`.
  """
  @spec encode_ascii(value :: integer | String.t()) :: charlist
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
  @spec merge_msg :: String.t()
  def merge_msg, do: "MERGE_MSG"

  @doc "Name of the file containing the IDs of the parents of a merge commit."
  @spec merge_head :: String.t()
  def merge_head, do: "MERGE_HEAD"

  @doc "Name of the file containing the ID of a cherry pick commit in case of conflicts."
  @spec cherry_pick_head :: String.t()
  def cherry_pick_head, do: "CHERRY_PICK_HEAD"

  @doc "Name of the file containing the commit message for a squash commit."
  @spec squash_msg :: String.t()
  def squash_msg, do: "SQUASH_MSG"

  @doc "Name of the file containing the ID of a revert commit in case of conflicts."
  @spec revert_head :: String.t()
  def revert_head, do: "REVERT_HEAD"

  @doc "Name of the ref `ORIG_HEAD` used by certain commands to store the original value of `HEAD`."
  @spec orig_head :: String.t()
  def orig_head, do: "ORIG_HEAD"

  @doc ~S"""
  Name of the file in which git commands and hooks store and read the
  message prepared for the upcoming commit.
  """
  @spec commit_edit_msg :: String.t()
  def commit_edit_msg, do: "COMMIT_EDITMSG"

  @doc "Well-known object ID for the empty blob."
  @spec empty_blob_id :: String.t()
  def empty_blob_id, do: "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"

  @doc "Well-known object ID for the empty tree."
  @spec empty_tree_id :: String.t()
  def empty_tree_id, do: "4b825dc642cb6eb9a060e54bf8d69288fbee4904"

  @doc "Suffix of lock file name."
  @spec lock_suffix :: String.t()
  def lock_suffix, do: ".lock"

  @typedoc "Time zone offset (in minutes +/- from GMT."
  @type tz_offset :: -720..840
end
