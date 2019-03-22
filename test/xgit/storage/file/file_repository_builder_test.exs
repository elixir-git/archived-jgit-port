defmodule Xgit.Storage.File.FileRepositoryBuilderTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants
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
end
