defmodule Xgit.Lib.RepositoryCacheTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.RepositoryCache.FileKey

  describe "FileKey.contains_git_repository?/1" do
    setup do
      Temp.track!()
      temp_file_path = Temp.mkdir!(prefix: "tmp_")
      {:ok, trash: temp_file_path}
    end

    test "is (close enough to) a repository 1", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refs/mumble")

      assert FileKey.contains_git_repository?(git_dir) == true
    end

    test "is (close enough to) a repository 2", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "e0fa091743a73c8431da4ab2491b2b7ccbc0bb04")

      assert FileKey.contains_git_repository?(git_dir) == true
    end

    test "not a repository 1", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "ref: refz/mumble")

      assert FileKey.contains_git_repository?(git_dir) == false
    end

    test "not a repository 2", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      object_dir = Path.join(git_dir, "objects")
      File.mkdir_p!(object_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "refs/mumble")

      assert FileKey.contains_git_repository?(git_dir) == false
    end

    test "not a repository 3", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.mkdir_p!(git_dir)

      refs_dir = Path.join(git_dir, "refs")
      File.mkdir_p!(refs_dir)

      head_file = Path.join(git_dir, "HEAD")
      File.write!(head_file, "refs/mumble")

      assert FileKey.contains_git_repository?(git_dir) == false
    end

    test "not a repository 4", %{trash: trash} do
      git_dir = Path.join(trash, ".git")
      File.write!(git_dir, "not a directory")

      assert FileKey.contains_git_repository?(git_dir) == false
    end
  end
end
