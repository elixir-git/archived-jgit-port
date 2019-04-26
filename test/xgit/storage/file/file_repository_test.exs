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

defmodule Xgit.Storage.File.FileRepositoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.ObjectDirectory
  alias Xgit.Lib.Config
  alias Xgit.Lib.Constants
  alias Xgit.Lib.Repository
  alias Xgit.Storage.File.FileRepository
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Test.MockSystemReader

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")
    {:ok, trash: temp_file_path}
  end

  describe "create!/2" do
    test "default case", %{trash: trash} do
      # Check the default rules for looking up directories and files within a
      # repo when `git_dir` is given.

      repo_parent = Path.join(trash, "r1")
      git_dir = Path.join(repo_parent, Constants.dot_git())

      {:ok, r1} =
        %FileRepositoryBuilder{git_dir: git_dir}
        |> FileRepositoryBuilder.setup!()
        |> FileRepository.start_link()

      assert ^r1 = Repository.create!(r1)
      assert ^git_dir = Repository.git_dir!(r1)
      assert File.dir?(git_dir)

      assert ^repo_parent = Repository.work_tree!(r1)
      assert File.dir?(repo_parent)

      index_file = Repository.index_file!(r1)
      assert ^index_file = Path.join(git_dir, "index")

      object_db = r1 |> Repository.object_database!() |> ObjectDirectory.directory()
      assert ^object_db = Path.join(git_dir, "objects")
    end

    test "ignore system config", %{trash: trash} do
      repo_parent = Path.join(trash, "r1")
      git_dir = Path.join(repo_parent, Constants.dot_git())

      msr = %MockSystemReader{env: %{"GIT_CONFIG_NOSYSTEM" => "true"}, user_config: Config.new()}

      {:ok, r1} =
        %FileRepositoryBuilder{git_dir: git_dir}
        |> FileRepositoryBuilder.setup!()
        |> FileRepository.start_link(system_reader: msr)

      assert ^r1 = Repository.create!(r1)
      assert ^git_dir = Repository.git_dir!(r1)
      assert File.dir?(git_dir)

      assert Repository.bare?(r1) == false

      assert ^repo_parent = Repository.work_tree!(r1)
      assert File.dir?(repo_parent)

      index_file = Repository.index_file!(r1)
      assert ^index_file = Path.join(git_dir, "index")

      object_db = r1 |> Repository.object_database!() |> ObjectDirectory.directory()
      assert ^object_db = Path.join(git_dir, "objects")
    end

    test "fails when config exists", %{trash: trash} do
      repo_parent = Path.join(trash, "r1")
      git_dir = Path.join(repo_parent, Constants.dot_git())

      File.mkdir_p!(git_dir)
      File.touch!(Path.join(git_dir, "config"))

      {:ok, r1} =
        %FileRepositoryBuilder{git_dir: git_dir}
        |> FileRepositoryBuilder.setup!()
        |> FileRepository.start_link()

      assert_raise(RuntimeError, "Repository already exists: #{git_dir}", fn ->
        Repository.create!(r1)
      end)
    end
  end

  test "config!/1", %{trash: trash} do
    repo_parent = Path.join(trash, "r1")
    git_dir = Path.join(repo_parent, Constants.dot_git())

    {:ok, r1} =
      %FileRepositoryBuilder{git_dir: git_dir}
      |> FileRepositoryBuilder.setup!()
      |> FileRepository.start_link()

    assert ^r1 = Repository.create!(r1)

    config = Repository.config!(r1)
    Config.set_string(config, "user", "name", "bob")
    assert :ok = Config.save(config)

    assert File.regular?(Path.join(git_dir, "config"))
  end

  test "valid?/1", %{trash: trash} do
    repo_parent = Path.join(trash, "r1")
    git_dir = Path.join(repo_parent, Constants.dot_git())

    {:ok, r1} =
      %FileRepositoryBuilder{git_dir: git_dir}
      |> FileRepositoryBuilder.setup!()
      |> FileRepository.start_link()

    assert ^r1 = Repository.create!(r1)

    {:ok, not_repository_pid} = GenServer.start_link(__MODULE__.NotARepository, [:x])

    assert Repository.valid?(r1) == true
    assert Repository.valid?(not_repository_pid) == false

    GenServer.stop(not_repository_pid)
    assert Repository.valid?(not_repository_pid) == false

    assert Repository.valid?(nil) == false
    assert Repository.valid?("I'm a repository. Trust me!") == false
  end

  defmodule NotARepository do
    use GenServer

    def init(x), do: {:ok, x}
    def handle_call(_, _, x), do: {:reply, :nope, x}
  end
end
