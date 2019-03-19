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
end
