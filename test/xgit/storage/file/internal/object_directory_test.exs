# Copyright (C) 2012, Roberto Tyley <roberto.tyley@gmail.com>
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/ObjectDirectoryTest.java
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

defmodule Xgit.Storage.File.Internal.ObjectDirectoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Storage.File.Internal.ObjectDirectory
  alias Xgit.Lib.Config
  alias Xgit.Lib.ObjectDatabase

  import ExUnit.CaptureLog

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")

    git_dir = Path.join(temp_file_path, ".git")
    objects_dir = Path.join(git_dir, "objects")
    File.mkdir_p!(objects_dir)

    {:ok, objects_dir: objects_dir}
  end

  test "exists?/1", %{objects_dir: objects_dir} do
    extra_dir = Path.join(objects_dir, "extra")

    assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: extra_dir)
    assert is_pid(pid)

    assert ObjectDatabase.valid?(pid) == true
    assert ObjectDatabase.exists?(pid) == false
    assert :ok = ObjectDatabase.create!(pid)
    assert ObjectDatabase.exists?(pid) == true
  end

  describe "create/1" do
    test "creates appropriate subdirectories", %{objects_dir: objects_dir} do
      assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
      assert is_pid(pid)

      assert :ok = ObjectDatabase.create!(pid)

      assert File.dir?(objects_dir)
      assert File.dir?(Path.join(objects_dir, "info"))
      assert File.dir?(Path.join(objects_dir, "pack"))
    end
  end

  describe "directory/1" do
    test "returns path to objects directory", %{objects_dir: objects_dir} do
      assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
      assert is_pid(pid)

      assert ObjectDirectory.directory(pid) == objects_dir
    end
  end

  describe "pack_directory/1" do
    test "returns path to pack directory", %{objects_dir: objects_dir} do
      assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
      assert is_pid(pid)

      assert ObjectDirectory.pack_directory(pid) == Path.join(objects_dir, "pack")
    end
  end

  test "handles unexpected calls", %{objects_dir: objects_dir} do
    assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
    assert is_pid(pid)

    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(pid, :bogus)
           end) =~ "[warn]  ObjectDatabase received unrecognized call :bogus"

    assert Process.alive?(pid)
  end
end
