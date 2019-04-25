defmodule Xgit.Api.InitCommandTest do
  use Xgit.Test.RepositoryTestCase

  alias Xgit.Api.InitCommand
  alias Xgit.Lib.Repository

  setup do
    RepositoryTestCase.setup_test()
  end

  test "basic case" do
    dir = Temp.mkdir!()

    repo =
      %InitCommand{dir: dir}
      |> InitCommand.run()

    assert Repository.valid?(repo)
  end

  test "non-empty repository" do
    dir = Temp.mkdir!(prefix: "testInitRepository2")

    some_file = Path.join(dir, "someFile")
    File.touch!(some_file)

    assert File.regular?(some_file)

    repo = InitCommand.run(%InitCommand{dir: dir})
    assert Repository.valid?(repo)
  end

  test "bare repository" do
    dir = Temp.mkdir!(prefix: "testInitBareRepository")

    repo = InitCommand.run(%InitCommand{dir: dir, bare?: true})

    assert Repository.valid?(repo)
    assert Repository.bare?(repo)
  end

  test "non-bare repos where git_dir and dir are set" do
    # Similar to `git init --separate-git-dir /tmp/a /tmp/b`

    work_tree = Temp.mkdir!(prefix: "testInitRepositoryWT")
    git_dir = Temp.mkdir!(prefix: "testInitRepositoryGIT")

    repo = InitCommand.run(%InitCommand{dir: work_tree, git_dir: git_dir})

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
      InitCommand.run(%InitCommand{dir: dir, git_dir: git_dir, bare?: true})
    end
  end

  test "must set dir or git_dir (non-bare repo)" do
    # Similar to `git init`. xgit doesn't allow fallback to current
    # working directory, so this is an error case.

    assert_raise ArgumentError, fn ->
      InitCommand.run(%InitCommand{})
    end
  end

  test "must set dir or git_dir (bare repo)" do
    # Similar to `git init --bare`. xgit doesn't allow fallback to current
    # working directory, so this is an error case.

    assert_raise ArgumentError, fn ->
      InitCommand.run(%InitCommand{bare?: true})
    end
  end

  test "in a non-bare repo, dir and git_dir must not be set to same directory" do
    # Similar to `git init --separate-git-dir /tmp/a /tmp/a`.

    dir = Temp.mkdir!(prefix: "testInitBareRepository")

    assert_raise ArgumentError, fn ->
      InitCommand.run(%InitCommand{dir: dir, git_dir: dir})
    end
  end
end
