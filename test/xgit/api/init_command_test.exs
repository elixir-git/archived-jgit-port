# Copyright (C) 2010, Chris Aniszczyk <caniszczyk@gmail.com>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/api/InitCommandTest.java
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

defmodule Xgit.Api.InitCommandTest do
  use ExUnit.Case, async: true

  alias Xgit.Api.InitCommand
  alias Xgit.Lib.Repository

  test "basic case" do
    dir = Temp.mkdir!()

    repo =
      %InitCommand{dir: dir}
      |> InitCommand.run!()

    assert Repository.valid?(repo)
  end

  test "non-empty repository" do
    dir = Temp.mkdir!(prefix: "testInitRepository2")

    some_file = Path.join(dir, "someFile")
    File.touch!(some_file)

    assert File.regular?(some_file)

    repo = InitCommand.run!(%InitCommand{dir: dir})
    assert Repository.valid?(repo)
  end

  test "bare repository" do
    dir = Temp.mkdir!(prefix: "testInitBareRepository")

    repo = InitCommand.run!(%InitCommand{dir: dir, bare?: true})

    assert Repository.valid?(repo)
    assert Repository.bare?(repo)
  end

  test "non-bare repos where git_dir and dir are set" do
    # Similar to `git init --separate-git-dir /tmp/a /tmp/b`

    work_tree = Temp.mkdir!(prefix: "testInitRepositoryWT")
    git_dir = Temp.mkdir!(prefix: "testInitRepositoryGIT")

    repo = InitCommand.run!(%InitCommand{dir: work_tree, git_dir: git_dir})

    assert Repository.valid?(repo)
    assert Repository.bare?(repo) == false

    assert Repository.work_tree!(repo) == work_tree
    assert Repository.git_dir!(repo) == git_dir
  end

  test "non-bare repos where only git_dir is set" do
    # Similar to `git init --separate-git-dir /tmp/a`
    # NOTE: We are not porting this because (unlike jgit) xgit requires
    # explicit configuration for directories. It will not fall back to
    # user directory or current working directory.
  end

  test "bare repo: dir and git_dir must be the same" do
    # Similar to `git init --bare --separate-git-dir /tmp/a /tmp/b`

    dir = Temp.mkdir!(prefix: "testInitRepository.git")
    git_dir = Path.dirname(dir)

    assert_raise ArgumentError, fn ->
      InitCommand.run!(%InitCommand{dir: dir, git_dir: git_dir, bare?: true})
    end
  end

  test "must set dir or git_dir (non-bare repo)" do
    # Similar to `git init`. xgit doesn't allow fallback to current
    # working directory, so this is an error case.

    assert_raise ArgumentError, fn ->
      InitCommand.run!(%InitCommand{})
    end
  end

  test "must set dir or git_dir (bare repo)" do
    # Similar to `git init --bare`. xgit doesn't allow fallback to current
    # working directory, so this is an error case.

    assert_raise ArgumentError, fn ->
      InitCommand.run!(%InitCommand{bare?: true})
    end
  end

  test "in a non-bare repo, dir and git_dir must not be set to same directory" do
    # Similar to `git init --separate-git-dir /tmp/a /tmp/a`.

    dir = Temp.mkdir!(prefix: "testInitBareRepository")

    assert_raise ArgumentError, fn ->
      InitCommand.run!(%InitCommand{dir: dir, git_dir: dir})
    end
  end
end
