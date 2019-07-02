# Copyright (C) 2010, Mathias Kinzler <mathias.kinzler@sap.com>
# Copyright (C) 2010, Chris Aniszczyk <caniszczyk@gmail.com>
# Copyright (C) 2012-2013, Robin Rosenberg
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ConfigConstants.java
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

defmodule Xgit.Lib.ConfigConstants do
  @moduledoc ~S"""
  Constants for use with `Xgit.Lib.Config`: section names and configuration keys.
  """

  @doc ~s"The `core` section"
  @spec config_core_section :: String.t()
  def config_core_section, do: "core"

  @doc ~s"The `branch` section"
  @spec config_branch_section :: String.t()
  def config_branch_section, do: "branch"

  @doc ~s"The `remote` section"
  @spec config_remote_section :: String.t()
  def config_remote_section, do: "remote"

  @doc ~s"The `diff` section"
  @spec config_diff_section :: String.t()
  def config_diff_section, do: "diff"

  @doc ~s"The `dfs` section"
  @spec config_dfs_section :: String.t()
  def config_dfs_section, do: "dfs"

  @doc ~s"The `receive` section"
  @spec config_receive_section :: String.t()
  def config_receive_section, do: "receive"

  @doc ~s"The `user` section"
  @spec config_user_section :: String.t()
  def config_user_section, do: "user"

  @doc ~s"The `gerrit` section"
  @spec config_gerrit_section :: String.t()
  def config_gerrit_section, do: "gerrit"

  @doc ~s"The `workflow` section"
  @spec config_workflow_section :: String.t()
  def config_workflow_section, do: "workflow"

  @doc ~s"The `submodule` section"
  @spec config_submodule_section :: String.t()
  def config_submodule_section, do: "submodule"

  @doc ~s"The `rebase` section"
  @spec config_rebase_section :: String.t()
  def config_rebase_section, do: "rebase"

  @doc ~s"The `gc` section"
  @spec config_gc_section :: String.t()
  def config_gc_section, do: "gc"

  @doc ~s"The `pack` section"
  @spec config_pack_sction :: String.t()
  def config_pack_sction, do: "pack"

  @doc ~s"The `fetch` section"
  @spec config_fetch_section :: String.t()
  def config_fetch_section, do: "fetch"

  @doc ~s"The `pull` section"
  @spec config_pull_section :: String.t()
  def config_pull_section, do: "pull"

  @doc ~s"The `merge` section"
  @spec config_merge_section :: String.t()
  def config_merge_section, do: "merge"

  @doc ~s"The `filter` section"
  @spec config_filter_section :: String.t()
  def config_filter_section, do: "filter"

  @doc ~s"The `gpg` section"
  @spec config_gpg_section :: String.t()
  def config_gpg_section, do: "gpg"

  @doc ~s"The `format` key"
  @spec config_key_format :: String.t()
  def config_key_format, do: "format"

  @doc ~s"The `signingKey` key"
  @spec config_key_signingkey :: String.t()
  def config_key_signingkey, do: "signingKey"

  @doc ~s"The `commit` section"
  @spec config_commit_section :: String.t()
  def config_commit_section, do: "commit"

  @doc ~s"The `gpgSign` key"
  @spec config_key_gpgsign :: String.t()
  def config_key_gpgsign, do: "gpgSign"

  @doc ~s"The `algorithm` key"
  @spec config_key_algorithm :: String.t()
  def config_key_algorithm, do: "algorithm"

  @doc ~s"The `autocrlf` key"
  @spec config_key_autocrlf :: String.t()
  def config_key_autocrlf, do: "autocrlf"

  @doc ~s"The `auto` key"
  @spec config_key_auto :: String.t()
  def config_key_auto, do: "auto"

  @doc ~s"The `autogc` key"
  @spec config_key_autogc :: String.t()
  def config_key_autogc, do: "autogc"

  @doc ~s"The `autopacklimit` key"
  @spec config_key_autopacklimit :: String.t()
  def config_key_autopacklimit, do: "autopacklimit"

  @doc ~s"The `eol` key"
  @spec config_key_eol :: String.t()
  def config_key_eol, do: "eol"

  @doc ~s"The `bare` key"
  @spec config_key_bare :: String.t()
  def config_key_bare, do: "bare"

  @doc ~s"The `excludesfile` key"
  @spec config_key_excludesfile :: String.t()
  def config_key_excludesfile, do: "excludesfile"

  @doc ~s"The `attributesfile` key"
  @spec config_key_attributesfile :: String.t()
  def config_key_attributesfile, do: "attributesfile"

  @doc ~s"The `filemode` key"
  @spec config_key_filemode :: String.t()
  def config_key_filemode, do: "filemode"

  @doc ~s"The `logallrefupdates` key"
  @spec config_key_logallrefupdates :: String.t()
  def config_key_logallrefupdates, do: "logallrefupdates"

  @doc ~s"The `repositoryformatversion` key"
  @spec config_key_repo_format_version :: String.t()
  def config_key_repo_format_version, do: "repositoryformatversion"

  @doc ~s"The `worktree` key"
  @spec config_key_worktree :: String.t()
  def config_key_worktree, do: "worktree"

  @doc ~s"The `blockLimit` key"
  @spec config_key_block_limit :: String.t()
  def config_key_block_limit, do: "blockLimit"

  @doc ~s"The `blockSize` key"
  @spec config_key_block_size :: String.t()
  def config_key_block_size, do: "blockSize"

  @doc ~s"The `concurrencyLevel` key"
  @spec config_key_concurrency_level :: String.t()
  def config_key_concurrency_level, do: "concurrencyLevel"

  @doc ~s"The `deltaBaseCacheLimit` key"
  @spec config_key_delta_base_cache_limit :: String.t()
  def config_key_delta_base_cache_limit, do: "deltaBaseCacheLimit"

  @doc ~s"The `symlinks` key"
  @spec config_key_symlinks :: String.t()
  def config_key_symlinks, do: "symlinks"

  @doc ~s"The `streamFileThreshold` key"
  @spec config_key_stream_file_threshold :: String.t()
  def config_key_stream_file_threshold, do: "streamFileThreshold"

  @doc ~s"The `remote` key"
  @spec config_key_remote :: String.t()
  def config_key_remote, do: "remote"

  @doc ~s"The `merge` key"
  @spec config_key_merge :: String.t()
  def config_key_merge, do: "merge"

  @doc ~s"The `rebase` key"
  @spec config_key_rebase :: String.t()
  def config_key_rebase, do: "rebase"

  @doc ~s"The `url` key"
  @spec config_key_url :: String.t()
  def config_key_url, do: "url"

  @doc ~s"The `autosetupmerge` key"
  @spec config_key_autosetupmerge :: String.t()
  def config_key_autosetupmerge, do: "autosetupmerge"

  @doc ~s"The `autosetuprebase` key"
  @spec config_key_autosetuprebase :: String.t()
  def config_key_autosetuprebase, do: "autosetuprebase"

  @doc ~s"The `autostash` key"
  @spec config_key_autostash :: String.t()
  def config_key_autostash, do: "autostash"

  @doc ~s"The `name` key"
  @spec config_key_name :: String.t()
  def config_key_name, do: "name"

  @doc ~s"The `email` key"
  @spec config_key_email :: String.t()
  def config_key_email, do: "email"

  @doc ~s"The `false` key (used to configure `config_key_autosetupmerge/0`)"
  @spec config_key_false :: String.t()
  def config_key_false, do: "false"

  @doc ~s"The `true` key (used to configure `config_key_autosetupmerge/0`)"
  @spec config_key_true :: String.t()
  def config_key_true, do: "true"

  @doc ~S"""
  The `always` key (used to configure `config_key_autosetuprebase/0` and
  `config_key_autosetupmerge/0`)
  """
  @spec config_key_always :: String.t()
  def config_key_always, do: "always"

  @doc ~s"The `never` key (used to configure `config_key_autosetuprebase/0`)"
  @spec config_key_never :: String.t()
  def config_key_never, do: "never"

  @doc ~s"The `local` key (used to configure `config_key_autosetuprebase/0`)"
  @spec config_key_local :: String.t()
  def config_key_local, do: "local"

  @doc ~s"The `createchangeid` key"
  @spec config_key_createchangeid :: String.t()
  def config_key_createchangeid, do: "createchangeid"

  @doc ~s"The `defaultsourceref` key"
  @spec config_key_defbranchstartpoint :: String.t()
  def config_key_defbranchstartpoint, do: "defbranchstartpoint"

  @doc ~s"The `path` key"
  @spec config_key_path :: String.t()
  def config_key_path, do: "path"

  @doc ~s"The `update` key"
  @spec config_key_update :: String.t()
  def config_key_update, do: "update"

  @doc ~s"The `ignore` key"
  @spec config_key_ignore :: String.t()
  def config_key_ignore, do: "ignore"

  @doc ~s"The `compression` key"
  @spec config_key_compression :: String.t()
  def config_key_compression, do: "compression"

  @doc ~s"The `indexversion` key"
  @spec config_key_indexversion :: String.t()
  def config_key_indexversion, do: "indexversion"

  @doc ~s"The `hidedotfiles` key"
  @spec config_key_hidedotfiles :: String.t()
  def config_key_hidedotfiles, do: "hidedotfiles"

  @doc ~s"The `dirnogitlinks` key"
  @spec config_key_dirnogitlinks :: String.t()
  def config_key_dirnogitlinks, do: "dirNoGitLinks"

  @doc ~s"The `precomposeunicode` key"
  @spec config_key_precomposeunicode :: String.t()
  def config_key_precomposeunicode, do: "precomposeunicode"

  @doc ~s"The `pruneexpire` key"
  @spec config_key_pruneexpire :: String.t()
  def config_key_pruneexpire, do: "pruneexpire"

  @doc ~s"The `prunepackexpire` key"
  @spec config_key_prunepackexpire :: String.t()
  def config_key_prunepackexpire, do: "prunepackexpire"

  @doc ~s"The `logexpiry` key"
  @spec config_key_logexpiry :: String.t()
  def config_key_logexpiry, do: "logExpiry"

  @doc ~s"The `autodetach` key"
  @spec config_key_autodetach :: String.t()
  def config_key_autodetach, do: "autoDetach"

  @doc ~s"The `aggressiveDepth` key"
  @spec config_key_aggressive_depth :: String.t()
  def config_key_aggressive_depth, do: "aggressiveDepth"

  @doc ~s"The `aggressiveWindow` key"
  @spec config_key_aggressive_window :: String.t()
  def config_key_aggressive_window, do: "aggressiveWindow"

  @doc ~s"The `mergeoptions` key"
  @spec config_key_mergeoptions :: String.t()
  def config_key_mergeoptions, do: "mergeoptions"

  @doc ~s"The `ff` key"
  @spec config_key_ff :: String.t()
  def config_key_ff, do: "ff"

  @doc ~s"The `checkstat` key"
  @spec config_key_checkstat :: String.t()
  def config_key_checkstat, do: "checkstat"

  @doc ~s"The `renamelimit` key in the `diff` section"
  @spec config_key_renamelimit :: String.t()
  def config_key_renamelimit, do: "renamelimit"

  @doc ~s"The `trustfolderstat` key in the `core` section"
  @spec config_key_trustfolderstat :: String.t()
  def config_key_trustfolderstat, do: "trustfolderstat"

  @doc ~s"The `supportsAtomicFileCreation` key in the `core` section"
  @spec config_key_supportsatomicfilecreation :: String.t()
  def config_key_supportsatomicfilecreation, do: "supportsatomicfilecreation"

  @doc ~s"The `noprefix` key in the `diff` section"
  @spec config_key_noprefix :: String.t()
  def config_key_noprefix, do: "noprefix"

  @doc ~s"A `renamelimit` value in the `diff` section"
  @spec config_renamelimit_copy :: String.t()
  def config_renamelimit_copy, do: "copy"

  @doc ~s"A `renamelimit` value in the `diff` section"
  @spec config_renamelimit_copies :: String.t()
  def config_renamelimit_copies, do: "copies"

  @doc ~s"The `renames` key in the `diff` section"
  @spec config_key_renames :: String.t()
  def config_key_renames, do: "renames"

  @doc ~S"""
  The `inCoreLimit` key in the `merge` section. It's a size limit (bytes) used to
  control a file to be stored in `Heap` or `LocalFile` during the merge.
  """
  @spec config_key_in_core_limit :: String.t()
  def config_key_in_core_limit, do: "inCoreLimit"

  @doc ~s"The `prune` key"
  @spec config_key_prune :: String.t()
  def config_key_prune, do: "prune"

  @doc ~s"The `streamBuffer` key"
  @spec config_key_stream_buffer :: String.t()
  def config_key_stream_buffer, do: "streamBuffer"

  @doc ~s"The `streamRatio` key"
  @spec config_key_streamratio :: String.t()
  def config_key_streamratio, do: "streamRatio"

  @doc ~S"""
  Flag in the filter section whether to use Xgit's implementations of
  filters and hooks.

  _PORTING NOTE:_ No such implementation exists as yet.
  """
  @spec config_key_usexgitbuiltin :: String.t()
  def config_key_usexgitbuiltin, do: "useXgitBuiltin"

  @doc ~s"The `fetchRecurseSubmodules` key"
  @spec config_key_fetch_recurse_submodules :: String.t()
  def config_key_fetch_recurse_submodules, do: "fetchRecurseSubmodules"

  @doc ~s"The `recurseSubmodules` key"
  @spec config_key_recurse_submodules :: String.t()
  def config_key_recurse_submodules, do: "recurseSubmodules"

  @doc ~s"The `required` key"
  @spec config_key_required :: String.t()
  def config_key_required, do: "required"

  @doc ~s"The `lfs` section"
  @spec config_section_lfs :: String.t()
  def config_section_lfs, do: "lfs"

  @doc ~s"The `i18n` section"
  @spec config_section_i18n :: String.t()
  def config_section_i18n, do: "i18n"

  @doc ~s"The `logOutputEncoding` key"
  @spec config_key_log_output_encoding :: String.t()
  def config_key_log_output_encoding, do: "logOutputEncoding"
end
