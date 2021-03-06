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

defmodule Xgit.Lib.ConfigConstantsTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.ConfigConstants

  defmacro assert_constant(name, value) do
    quote do
      assert ConfigConstants.unquote(name) == unquote(value)
    end
  end

  test "constants" do
    assert_constant(:config_core_section, "core")
    assert_constant(:config_branch_section, "branch")
    assert_constant(:config_remote_section, "remote")
    assert_constant(:config_diff_section, "diff")
    assert_constant(:config_dfs_section, "dfs")
    assert_constant(:config_receive_section, "receive")
    assert_constant(:config_user_section, "user")
    assert_constant(:config_gerrit_section, "gerrit")
    assert_constant(:config_workflow_section, "workflow")
    assert_constant(:config_submodule_section, "submodule")
    assert_constant(:config_rebase_section, "rebase")
    assert_constant(:config_gc_section, "gc")
    assert_constant(:config_pack_sction, "pack")
    assert_constant(:config_fetch_section, "fetch")
    assert_constant(:config_pull_section, "pull")
    assert_constant(:config_merge_section, "merge")
    assert_constant(:config_filter_section, "filter")
    assert_constant(:config_gpg_section, "gpg")
    assert_constant(:config_key_format, "format")
    assert_constant(:config_key_signingkey, "signingKey")
    assert_constant(:config_commit_section, "commit")
    assert_constant(:config_key_gpgsign, "gpgSign")
    assert_constant(:config_key_algorithm, "algorithm")
    assert_constant(:config_key_autocrlf, "autocrlf")
    assert_constant(:config_key_auto, "auto")
    assert_constant(:config_key_autogc, "autogc")
    assert_constant(:config_key_autopacklimit, "autopacklimit")
    assert_constant(:config_key_eol, "eol")
    assert_constant(:config_key_bare, "bare")
    assert_constant(:config_key_excludesfile, "excludesfile")
    assert_constant(:config_key_attributesfile, "attributesfile")
    assert_constant(:config_key_filemode, "filemode")
    assert_constant(:config_key_logallrefupdates, "logallrefupdates")
    assert_constant(:config_key_repo_format_version, "repositoryformatversion")
    assert_constant(:config_key_worktree, "worktree")
    assert_constant(:config_key_block_limit, "blockLimit")
    assert_constant(:config_key_block_size, "blockSize")
    assert_constant(:config_key_concurrency_level, "concurrencyLevel")
    assert_constant(:config_key_delta_base_cache_limit, "deltaBaseCacheLimit")
    assert_constant(:config_key_symlinks, "symlinks")
    assert_constant(:config_key_stream_file_threshold, "streamFileThreshold")
    assert_constant(:config_key_remote, "remote")
    assert_constant(:config_key_merge, "merge")
    assert_constant(:config_key_rebase, "rebase")
    assert_constant(:config_key_url, "url")
    assert_constant(:config_key_autosetupmerge, "autosetupmerge")
    assert_constant(:config_key_autosetuprebase, "autosetuprebase")
    assert_constant(:config_key_autostash, "autostash")
    assert_constant(:config_key_name, "name")
    assert_constant(:config_key_email, "email")
    assert_constant(:config_key_false, "false")
    assert_constant(:config_key_true, "true")
    assert_constant(:config_key_always, "always")
    assert_constant(:config_key_never, "never")
    assert_constant(:config_key_local, "local")
    assert_constant(:config_key_createchangeid, "createchangeid")
    assert_constant(:config_key_defbranchstartpoint, "defbranchstartpoint")
    assert_constant(:config_key_path, "path")
    assert_constant(:config_key_update, "update")
    assert_constant(:config_key_ignore, "ignore")
    assert_constant(:config_key_compression, "compression")
    assert_constant(:config_key_indexversion, "indexversion")
    assert_constant(:config_key_hidedotfiles, "hidedotfiles")
    assert_constant(:config_key_dirnogitlinks, "dirNoGitLinks")
    assert_constant(:config_key_precomposeunicode, "precomposeunicode")
    assert_constant(:config_key_pruneexpire, "pruneexpire")
    assert_constant(:config_key_prunepackexpire, "prunepackexpire")
    assert_constant(:config_key_logexpiry, "logExpiry")
    assert_constant(:config_key_autodetach, "autoDetach")
    assert_constant(:config_key_aggressive_depth, "aggressiveDepth")
    assert_constant(:config_key_aggressive_window, "aggressiveWindow")
    assert_constant(:config_key_mergeoptions, "mergeoptions")
    assert_constant(:config_key_ff, "ff")
    assert_constant(:config_key_checkstat, "checkstat")
    assert_constant(:config_key_renamelimit, "renamelimit")
    assert_constant(:config_key_trustfolderstat, "trustfolderstat")
    assert_constant(:config_key_supportsatomicfilecreation, "supportsatomicfilecreation")
    assert_constant(:config_key_noprefix, "noprefix")
    assert_constant(:config_renamelimit_copy, "copy")
    assert_constant(:config_renamelimit_copies, "copies")
    assert_constant(:config_key_renames, "renames")
    assert_constant(:config_key_usexgitbuiltin, "useXgitBuiltin")
    assert_constant(:config_key_fetch_recurse_submodules, "fetchRecurseSubmodules")
    assert_constant(:config_key_recurse_submodules, "recurseSubmodules")
    assert_constant(:config_key_required, "required")
    assert_constant(:config_section_lfs, "lfs")
    assert_constant(:config_section_i18n, "i18n")
    assert_constant(:config_key_log_output_encoding, "logOutputEncoding")
  end
end
