defmodule Xgit.Lib.ConfigConstants do
  @moduledoc ~S"""
  Constants for use with the Configuration classes: section names,
  configuration keys.
  """

  @doc ~s"The \"core\" section"
  def config_core_section, do: "core"

  @doc ~s"The \"branch\" section"
  def config_branch_section, do: "branch"

  @doc ~s"The \"remote\" section"
  def config_remote_section, do: "remote"

  @doc ~s"The \"diff\" section"
  def config_diff_section, do: "diff"

  @doc ~s"The \"dfs\" section"
  def config_dfs_section, do: "dfs"

  @doc ~s"The \"receive\" section"
  def config_receive_section, do: "receive"

  @doc ~s"The \"user\" section"
  def config_user_section, do: "user"

  @doc ~s"The \"gerrit\" section"
  def config_gerrit_section, do: "gerrit"

  @doc ~s"The \"workflow\" section"
  def config_workflow_section, do: "workflow"

  @doc ~s"The \"submodule\" section"
  def config_submodule_section, do: "submodule"

  @doc ~s"The \"rebase\" section"
  def config_rebase_section, do: "rebase"

  @doc ~s"The \"gc\" section"
  def config_gc_section, do: "gc"

  @doc ~s"The \"pack\" section"
  def config_pack_sction, do: "pack"

  @doc ~s"The \"fetch\" section"
  def config_fetch_section, do: "fetch"

  @doc ~s"The \"pull\" section"
  def config_pull_section, do: "pull"

  @doc ~s"The \"merge\" section"
  def config_merge_section, do: "merge"

  @doc ~s"The \"filter\" section"
  def config_filter_section, do: "filter"

  @doc ~s"The \"gpg\" section"
  def config_gpg_section, do: "gpg"

  @doc ~s"The \"format\" key"
  def config_key_format, do: "format"

  @doc ~s"The \"signingKey\" key"
  def config_key_signingkey, do: "signingKey"

  @doc ~s"The \"commit\" section"
  def config_commit_section, do: "commit"

  @doc ~s"The \"gpgSign\" key"
  def config_key_gpgsign, do: "gpgSign"

  @doc ~s"The \"algorithm\" key"
  def config_key_algorithm, do: "algorithm"

  @doc ~s"The \"autocrlf\" key"
  def config_key_autocrlf, do: "autocrlf"

  @doc ~s"The \"auto\" key"
  def config_key_auto, do: "auto"

  @doc ~s"The \"autogc\" key"
  def config_key_autogc, do: "autogc"

  @doc ~s"The \"autopacklimit\" key"
  def config_key_autopacklimit, do: "autopacklimit"

  @doc ~s"The \"eol\" key"
  def config_key_eol, do: "eol"

  @doc ~s"The \"bare\" key"
  def config_key_bare, do: "bare"

  @doc ~s"The \"excludesfile\" key"
  def config_key_excludesfile, do: "excludesfile"

  @doc ~s"The \"attributesfile\" key"
  def config_key_attributesfile, do: "attributesfile"

  @doc ~s"The \"filemode\" key"
  def config_key_filemode, do: "filemode"

  @doc ~s"The \"logallrefupdates\" key"
  def config_key_logallrefupdates, do: "logallrefupdates"

  @doc ~s"The \"repositoryformatversion\" key"
  def config_key_repo_format_version, do: "repositoryformatversion"

  @doc ~s"The \"worktree\" key"
  def config_key_worktree, do: "worktree"

  @doc ~s"The \"blockLimit\" key"
  def config_key_block_limit, do: "blockLimit"

  @doc ~s"The \"blockSize\" key"
  def config_key_block_size, do: "blockSize"

  @doc ~s"The \"concurrencyLevel\" key"
  def config_key_concurrency_level, do: "concurrencyLevel"

  @doc ~s"The \"deltaBaseCacheLimit\" key"
  def config_key_delta_base_cache_limit, do: "deltaBaseCacheLimit"

  @doc ~s"The \"symlinks\" key"
  def config_key_symlinks, do: "symlinks"

  @doc ~s"The \"streamFileThreshold\" key"
  def config_key_stream_file_threshold, do: "streamFileThreshold"

  @doc ~s"The \"remote\" key"
  def config_key_remote, do: "remote"

  @doc ~s"The \"merge\" key"
  def config_key_merge, do: "merge"

  @doc ~s"The \"rebase\" key"
  def config_key_rebase, do: "rebase"

  @doc ~s"The \"url\" key"
  def config_key_url, do: "url"

  @doc ~s"The \"autosetupmerge\" key"
  def config_key_autosetupmerge, do: "autosetupmerge"

  @doc ~s"The \"autosetuprebase\" key"
  def config_key_autosetuprebase, do: "autosetuprebase"

  @doc ~s"The \"autostash\" key"
  def config_key_autostash, do: "autostash"

  @doc ~s"The \"name\" key"
  def config_key_name, do: "name"

  @doc ~s"The \"email\" key"
  def config_key_email, do: "email"

  @doc ~s"The \"false\" key (used to configure `config_key_autosetupmerge/0`)"
  def config_key_false, do: "false"

  @doc ~s"The \"true\" key (used to configure `config_key_autosetupmerge/0`)"
  def config_key_true, do: "true"

  @doc ~S"""
  The "always" key (used to configure `config_key_autosetuprebase/0` and
  `config_key_autosetupmerge/0`)
  """
  def config_key_always, do: "always"

  @doc ~s"The \"never\" key (used to configure `config_key_autosetuprebase/0`)"
  def config_key_never, do: "never"

  @doc ~s"The \"local\" key (used to configure `config_key_autosetuprebase/0`)"
  def config_key_local, do: "local"

  @doc ~s"The \"createchangeid\" key"
  def config_key_createchangeid, do: "createchangeid"

  @doc ~s"The \"defaultsourceref\" key"
  def config_key_defbranchstartpoint, do: "defbranchstartpoint"

  @doc ~s"The \"path\" key"
  def config_key_path, do: "path"

  @doc ~s"The \"update\" key"
  def config_key_update, do: "update"

  @doc ~s"The \"ignore\" key"
  def config_key_ignore, do: "ignore"

  @doc ~s"The \"compression\" key"
  def config_key_compression, do: "compression"

  @doc ~s"The \"indexversion\" key"
  def config_key_indexversion, do: "indexversion"

  @doc ~s"The \"hidedotfiles\" key"
  def config_key_hidedotfiles, do: "hidedotfiles"

  @doc ~s"The \"dirnogitlinks\" key"
  def config_key_dirnogitlinks, do: "dirNoGitLinks"

  @doc ~s"The \"precomposeunicode\" key"
  def config_key_precomposeunicode, do: "precomposeunicode"

  @doc ~s"The \"pruneexpire\" key"
  def config_key_pruneexpire, do: "pruneexpire"

  @doc ~s"The \"prunepackexpire\" key"
  def config_key_prunepackexpire, do: "prunepackexpire"

  @doc ~s"The \"logexpiry\" key"
  def config_key_logexpiry, do: "logExpiry"

  @doc ~s"The \"autodetach\" key"
  def config_key_autodetach, do: "autoDetach"

  @doc ~s"The \"aggressiveDepth\" key"
  def config_key_aggressive_depth, do: "aggressiveDepth"

  @doc ~s"The \"aggressiveWindow\" key"
  def config_key_aggressive_window, do: "aggressiveWindow"

  @doc ~s"The \"mergeoptions\" key"
  def config_key_mergeoptions, do: "mergeoptions"

  @doc ~s"The \"ff\" key"
  def config_key_ff, do: "ff"

  @doc ~s"The \"checkstat\" key"
  def config_key_checkstat, do: "checkstat"

  @doc ~s"The \"renamelimit\" key in the \"diff\" section"
  def config_key_renamelimit, do: "renamelimit"

  @doc ~s"The \"trustfolderstat\" key in the \"core\" section"
  def config_key_trustfolderstat, do: "trustfolderstat"

  @doc ~s"The \"supportsAtomicFileCreation\" key in the \"core\" section"
  def config_key_supportsatomicfilecreation, do: "supportsatomicfilecreation"

  @doc ~s"The \"noprefix\" key in the \"diff\" section"
  def config_key_noprefix, do: "noprefix"

  @doc ~s"A \"renamelimit\" value in the \"diff\" section"
  def config_renamelimit_copy, do: "copy"

  @doc ~s"A \"renamelimit\" value in the \"diff\" section"
  def config_renamelimit_copies, do: "copies"

  @doc ~s"The \"renames\" key in the \"diff\" section"
  def config_key_renames, do: "renames"

  @doc ~S"""
  The "inCoreLimit" key in the "merge" section. It's a size limit (bytes) used to
  control a file to be stored in `Heap` or `LocalFile` during the merge.
  """
  def config_key_in_core_limit, do: "inCoreLimit"

  @doc ~s"The \"prune\" key"
  def config_key_prune, do: "prune"

  @doc ~s"The \"streamBuffer\" key"
  def config_key_stream_buffer, do: "streamBuffer"

  @doc ~s"The \"streamRatio\" key"
  def config_key_streamratio, do: "streamRatio"

  @doc ~S"""
  Flag in the filter section whether to use XGit's implementations of
  filters and hooks.

  PORTING NOTE: No such implementation exists as yet.
  """
  def config_key_usexgitbuiltin, do: "useXGitBuiltin"

  @doc ~s"The \"fetchRecurseSubmodules\" key"
  def config_key_fetch_recurse_submodules, do: "fetchRecurseSubmodules"

  @doc ~s"The \"recurseSubmodules\" key"
  def config_key_recurse_submodules, do: "recurseSubmodules"

  @doc ~s"The \"required\" key"
  def config_key_required, do: "required"

  @doc ~s"The \"lfs\" section"
  def config_section_lfs, do: "lfs"

  @doc ~s"The \"i18n\" section"
  def config_section_i18n, do: "i18n"

  @doc ~s"The \"logOutputEncoding\" key"
  def config_key_log_output_encoding, do: "logOutputEncoding"
end
