# Copyright (C) 2010, 2013 Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/RefDirectoryTest.java
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

defmodule Xgit.Storage.File.Internal.RefDirectoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.RefDatabase
  alias Xgit.Storage.File.Internal.RefDirectory

  import ExUnit.CaptureLog

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")

    git_dir = Path.join(temp_file_path, ".git")
    File.mkdir_p!(git_dir)

    {:ok, ref_directory_pid} = RefDirectory.start_link(git_dir)
    {:ok, git_dir: git_dir, ref_directory: ref_directory_pid}
  end

  describe "create/1" do
    test "creates appropriate subdirectories", %{git_dir: git_dir, ref_directory: ref_directory} do
      assert :ok = RefDatabase.create!(ref_directory)
      assert File.dir?(Path.join(git_dir, "refs"))
      assert File.dir?(Path.join(git_dir, "refs/heads"))
      assert File.dir?(Path.join(git_dir, "refs/tags"))
    end
  end

  test "handles unexpected calls", %{ref_directory: ref_directory} do
    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(ref_directory, :bogus)
           end) =~ "[warn]  RefDatabase received unrecognized call :bogus"

    assert Process.alive?(ref_directory)
  end
end
