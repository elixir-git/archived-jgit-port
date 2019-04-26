# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/FileRepositoryBuilderTest.java
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

defmodule Xgit.Storage.File.FileRepositoryBuilderTest do
  use Xgit.Test.LocalDiskRepositoryTestCase, async: true

  alias Xgit.Lib.Config
  alias Xgit.Lib.ConfigConstants
  alias Xgit.Lib.Constants
  alias Xgit.Lib.Repository
  alias Xgit.Storage.File.FileRepository
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Test.MockSystemReader

  describe "read_environment/2" do
    test "basic case" do
      msr = %MockSystemReader{}
      b = %FileRepositoryBuilder{} |> FileRepositoryBuilder.read_environment(msr)

      assert b == %FileRepositoryBuilder{
               git_dir: nil,
               object_dir: nil,
               alternate_object_directories: nil,
               bare?: false,
               must_exist?: false,
               work_tree: nil,
               index_file: nil,
               ceiling_directories: nil
             }
    end

    test "read from environment" do
      msr = %MockSystemReader{
        env: %{
          "GIT_DIR" => ".xgit",
          "GIT_OBJECT_DIRECTORY" => ".objects",
          "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "alternate:object:dirs",
          "GIT_WORK_TREE" => "work_tree",
          "GIT_INDEX_FILE" => "gitindex",
          "GIT_CEILING_DIRECTORIES" => "git:ceiling:dirs"
        }
      }

      b = %FileRepositoryBuilder{} |> FileRepositoryBuilder.read_environment(msr)

      assert b == %FileRepositoryBuilder{
               git_dir: ".xgit",
               object_dir: ".objects",
               alternate_object_directories: ["alternate", "object", "dirs"],
               bare?: false,
               must_exist?: false,
               work_tree: "work_tree",
               index_file: "gitindex",
               ceiling_directories: ["git", "ceiling", "dirs"]
             }
    end

    test "builder was already populated" do
      msr = %MockSystemReader{
        env: %{
          "GIT_DIR" => ".xgit",
          "GIT_OBJECT_DIRECTORY" => ".objects",
          "GIT_ALTERNATE_OBJECT_DIRECTORIES" => "alternate:object:dirs",
          "GIT_WORK_TREE" => "work_tree",
          "GIT_INDEX_FILE" => "gitindex",
          "GIT_CEILING_DIRECTORIES" => "git:ceiling:dirs"
        }
      }

      b =
        %FileRepositoryBuilder{
          git_dir: "xgit",
          object_dir: "objects",
          alternate_object_directories: ["object", "alternates"],
          bare?: false,
          must_exist?: false,
          work_tree: "tree_of_work",
          index_file: "index_of_git",
          ceiling_directories: ["ceilings", "dirs"]
        }
        |> FileRepositoryBuilder.read_environment(msr)

      assert b == %FileRepositoryBuilder{
               git_dir: "xgit",
               object_dir: "objects",
               alternate_object_directories: ["object", "alternates"],
               bare?: false,
               must_exist?: false,
               work_tree: "tree_of_work",
               index_file: "index_of_git",
               ceiling_directories: ["ceilings", "dirs"]
             }
    end
  end

  describe "find_git_dir/2" do
    setup do
      Temp.track!()
      temp_file_path = Temp.mkdir!(prefix: "tmp_")
      {:ok, trash: temp_file_path}
    end

    test "git_dir already populated" do
      b = %FileRepositoryBuilder{git_dir: "already here"}
      assert FileRepositoryBuilder.find_git_dir(b, "blah") == b
    end

    test "git_dir fallback to cwd not allowed" do
      assert_raise RuntimeError,
                   "FileRepositoryBuilder: git_dir must be explicitly specified",
                   fn -> FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}) end
    end

    test "git_dir miss (no .git dir)", %{trash: trash} do
      assert %FileRepositoryBuilder{git_dir: nil} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}, trash)
    end

    test "happy path 1", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      assert %FileRepositoryBuilder{git_dir: trash} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}, trash)
    end

    test "happy path 2", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      assert %FileRepositoryBuilder{git_dir: git_dir} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}, trash)
    end

    test "happy path 3 (is non-traditional git directory)", %{trash: trash} do
      object_dir = Path.join(trash, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(trash, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(trash, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      assert %FileRepositoryBuilder{git_dir: trash} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}, trash)
    end

    test "scan up", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      extra_dirs = Path.join(trash, "a/b/c")
      File.mkdir_p!(extra_dirs)

      assert %FileRepositoryBuilder{git_dir: git_dir} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{}, extra_dirs)
    end

    test "avoids ceiling", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      ceiling = Path.join(trash, "a")
      File.mkdir_p!(ceiling)

      extra_dirs = Path.join(ceiling, "b/c/d")
      File.mkdir_p!(extra_dirs)

      assert %FileRepositoryBuilder{git_dir: nil} =
               FileRepositoryBuilder.find_git_dir(
                 %FileRepositoryBuilder{ceiling_directories: [ceiling]},
                 extra_dirs
               )
    end
  end

  describe "setup!/1" do
    setup do
      Temp.track!()
      {:ok, trash: Temp.mkdir!(prefix: "tmp_")}
    end

    test "error: both git_dir and work_tree are nil" do
      assert_raise ArgumentError, fn ->
        %FileRepositoryBuilder{git_dir: nil, work_tree: nil}
        |> FileRepositoryBuilder.setup!()
      end
    end

    test "work_tree can't (yet) be sym ref", %{trash: trash} do
      dot_git = Path.join(trash, Constants.dot_git())
      File.write!(dot_git, "invalid sym ref")

      assert_raise RuntimeError, fn ->
        %FileRepositoryBuilder{work_tree: trash}
        |> FileRepositoryBuilder.setup!()
      end
    end

    test "happy path: populate from valid (if missing) work_tree", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      index_file = Path.join(git_dir, "index")
      objects_dir = Path.join(git_dir, "objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^work_tree
             } =
               %FileRepositoryBuilder{work_tree: work_tree}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: populate from valid git_dir", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      index_file = Path.join(git_dir, "index")
      objects_dir = Path.join(git_dir, "objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^work_tree
             } =
               %FileRepositoryBuilder{git_dir: git_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: populate as bare repo", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      objects_dir = Path.join(git_dir, "objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: true,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: nil,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: nil
             } =
               %FileRepositoryBuilder{git_dir: git_dir, bare?: true}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: imply bare repo", %{trash: trash} do
      git_dir = Path.join(trash, "notgit")
      objects_dir = Path.join(git_dir, "objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: true,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: nil,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: nil
             } =
               %FileRepositoryBuilder{git_dir: git_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: explicitly configure as not bare", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      config_file = Path.join(git_dir, "config")
      index_file = Path.join(git_dir, "index")
      objects_dir = Path.join(git_dir, "objects")

      File.mkdir_p!(git_dir)
      File.write!(config_file, "[core]\n\tbare = false")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^work_tree
             } =
               %FileRepositoryBuilder{git_dir: git_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: explicitly configure as bare", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      config_file = Path.join(git_dir, "config")
      objects_dir = Path.join(git_dir, "objects")

      File.mkdir_p!(git_dir)
      File.write!(config_file, "[core]\n\tbare = true")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: true,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: nil,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: nil
             } =
               %FileRepositoryBuilder{git_dir: git_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: explicitly configure work tree", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      config_file = Path.join(git_dir, "config")
      index_file = Path.join(git_dir, "index")
      objects_dir = Path.join(git_dir, "objects")

      File.mkdir_p!(git_dir)
      File.write!(config_file, "[core]\n\tworktree = ../some_other_worktree")

      configured_work_tree = Path.join(work_tree, "some_other_worktree")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^configured_work_tree
             } =
               %FileRepositoryBuilder{git_dir: git_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: explicitly configure index file", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      index_file = Path.join(git_dir, "unusual-index")
      objects_dir = Path.join(git_dir, "objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^work_tree
             } =
               %FileRepositoryBuilder{git_dir: git_dir, index_file: index_file}
               |> FileRepositoryBuilder.setup!()
    end

    test "happy path: explicitly configure objects dir", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      index_file = Path.join(git_dir, "index")
      objects_dir = Path.join(git_dir, "unusual-objects")

      assert %FileRepositoryBuilder{
               alternate_object_directories: nil,
               bare?: false,
               ceiling_directories: nil,
               git_dir: ^git_dir,
               index_file: ^index_file,
               must_exist?: false,
               object_dir: ^objects_dir,
               work_tree: ^work_tree
             } =
               %FileRepositoryBuilder{git_dir: git_dir, object_dir: objects_dir}
               |> FileRepositoryBuilder.setup!()
    end

    test "error: malformed config file", %{trash: trash} do
      work_tree = Path.join(trash, "work_tree")
      git_dir = Path.join(work_tree, ".git")
      config_file = Path.join(git_dir, "config")

      File.mkdir_p!(git_dir)
      File.write!(config_file, "malformed config file")

      assert_raise ArgumentError, fn ->
        %FileRepositoryBuilder{git_dir: git_dir}
        |> FileRepositoryBuilder.setup!()
      end
    end
  end

  test "should automagically detect .git directory" do
    r = LocalDiskRepositoryTestCase.create_work_repository!()
    d = r |> Repository.git_dir!() |> Path.join("sub_dir")
    File.mkdir_p!(d)

    d2 =
      %FileRepositoryBuilder{}
      |> FileRepositoryBuilder.find_git_dir(d)
      |> Map.get(:git_dir)

    assert Repository.git_dir!(r) == d2
  end

  test "can read empty format version from config" do
    r = LocalDiskRepositoryTestCase.create_work_repository!()
    git_dir = Repository.git_dir!(r)
    config = Repository.config!(r)

    Config.set_string(
      config,
      ConfigConstants.config_core_section(),
      ConfigConstants.config_key_repo_format_version(),
      ""
    )

    Config.save(config)

    assert {:ok, _} =
             %FileRepositoryBuilder{git_dir: git_dir}
             |> FileRepositoryBuilder.setup!()
             |> FileRepository.start_link()
  end

  test "raises error if repository format version is invalid" do
    r = LocalDiskRepositoryTestCase.create_work_repository!()
    git_dir = Repository.git_dir!(r)
    config = Repository.config!(r)

    Config.set_string(
      config,
      ConfigConstants.config_core_section(),
      ConfigConstants.config_key_repo_format_version(),
      "notanumber"
    )

    Config.save(config)

    Process.flag(:trap_exit, true)

    %FileRepositoryBuilder{git_dir: git_dir}
    |> FileRepositoryBuilder.setup!()
    |> FileRepository.start_link()

    assert_receive {:EXIT, _pid,
                    {%Xgit.Errors.ConfigInvalidError{
                       message: "Invalid integer value: core.repositoryformatversion=notanumber"
                     }, _}}
  end

  test "raises error if repository format version is unknown" do
    r = LocalDiskRepositoryTestCase.create_work_repository!()
    git_dir = Repository.git_dir!(r)
    config = Repository.config!(r)

    Config.set_int(
      config,
      ConfigConstants.config_core_section(),
      ConfigConstants.config_key_repo_format_version(),
      999_999
    )

    Config.save(config)

    Process.flag(:trap_exit, true)

    %FileRepositoryBuilder{git_dir: git_dir}
    |> FileRepositoryBuilder.setup!()
    |> FileRepository.start_link()

    assert_receive {:EXIT, _pid, {%ArgumentError{message: "Unknown repository format"}, _}}
  end

  test "TEMPORARY: raises error if repository format calls for reftree" do
    r = LocalDiskRepositoryTestCase.create_work_repository!()
    git_dir = Repository.git_dir!(r)
    config = Repository.config!(r)

    Config.set_int(
      config,
      ConfigConstants.config_core_section(),
      ConfigConstants.config_key_repo_format_version(),
      1
    )

    Config.set_string(config, "extensions", "refStorage", "reftree")
    Config.save(config)

    Process.flag(:trap_exit, true)

    %FileRepositoryBuilder{git_dir: git_dir}
    |> FileRepositoryBuilder.setup!()
    |> FileRepository.start_link()

    assert_receive {:EXIT, _pid,
                    {%ArgumentError{message: "RefTreeDatabase not yet implemented"}, _}}
  end

  # @Test
  # public void absoluteGitDirRef() throws Exception {
  #   Repository repo1 = createWorkRepository();
  #   File dir = createTempDirectory("dir");
  #   File dotGit = new File(dir, Constants.DOT_GIT);
  #   try (BufferedWriter writer = Files.newBufferedWriter(dotGit.toPath(),
  #       UTF_8)) {
  #     writer.append("gitdir: " + repo1.getDirectory().getAbsolutePath());
  #   }
  #   FileRepositoryBuilder builder = new FileRepositoryBuilder();
  #
  #   builder.setWorkTree(dir);
  #   builder.setMustExist(true);
  #   Repository repo2 = builder.build();
  #
  #   assertEquals(repo1.getDirectory().getAbsolutePath(),
  #       repo2.getDirectory().getAbsolutePath());
  #   assertEquals(dir, repo2.getWorkTree());
  # }
  #
  # @Test
  # public void relativeGitDirRef() throws Exception {
  #   Repository repo1 = createWorkRepository();
  #   File dir = new File(repo1.getWorkTree(), "dir");
  #   assertTrue(dir.mkdir());
  #   File dotGit = new File(dir, Constants.DOT_GIT);
  #   try (BufferedWriter writer = Files.newBufferedWriter(dotGit.toPath(),
  #       UTF_8)) {
  #     writer.append("gitdir: ../" + Constants.DOT_GIT);
  #   }
  #   FileRepositoryBuilder builder = new FileRepositoryBuilder();
  #   builder.setWorkTree(dir);
  #   builder.setMustExist(true);
  #   Repository repo2 = builder.build();
  #
  #   // The tmp directory may be a symlink so the actual path
  #   // may not
  #   assertEquals(repo1.getDirectory().getCanonicalPath(),
  #       repo2.getDirectory().getCanonicalPath());
  #   assertEquals(dir, repo2.getWorkTree());
  # }
  #
  # @Test
  # public void scanWithGitDirRef() throws Exception {
  #   Repository repo1 = createWorkRepository();
  #   File dir = createTempDirectory("dir");
  #   File dotGit = new File(dir, Constants.DOT_GIT);
  #   try (BufferedWriter writer = Files.newBufferedWriter(dotGit.toPath(),
  #       UTF_8)) {
  #     writer.append(
  #         "gitdir: " + repo1.getDirectory().getAbsolutePath());
  #   }
  #   FileRepositoryBuilder builder = new FileRepositoryBuilder();
  #
  #   builder.setWorkTree(dir);
  #   builder.findGitDir(dir);
  #   assertEquals(repo1.getDirectory().getAbsolutePath(),
  #       builder.getGitDir().getAbsolutePath());
  #   builder.setMustExist(true);
  #   Repository repo2 = builder.build();
  #
  #   // The tmp directory may be a symlink
  #   assertEquals(repo1.getDirectory().getCanonicalPath(),
  #       repo2.getDirectory().getCanonicalPath());
  #   assertEquals(dir, repo2.getWorkTree());
  # }
end
