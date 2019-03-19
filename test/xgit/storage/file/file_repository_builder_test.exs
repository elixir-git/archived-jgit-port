defmodule Xgit.Storage.File.FileRepositoryBuilderTest do
  use ExUnit.Case, async: true

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

    test "git_dir fallback to cwd" do
      assert %FileRepositoryBuilder{git_dir: dir} =
               FileRepositoryBuilder.find_git_dir(%FileRepositoryBuilder{})

      assert is_binary(dir) || is_nil(dir)
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
end
