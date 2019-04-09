defmodule Xgit.Storage.File.FileRepositoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Storage.File.FileRepository
  alias Xgit.Storage.File.FileRepositoryBuilder
  alias Xgit.Lib.Constants
  alias Xgit.Lib.Repository

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

      r1 =
        %FileRepositoryBuilder{git_dir: git_dir}
        |> FileRepositoryBuilder.setup!()
        |> FileRepository.start_link!()

      assert ^r1 = Repository.create!(r1)
      assert ^git_dir = Repository.git_dir!(r1)
      assert File.dir?(git_dir)

      assert ^repo_parent = Repository.work_tree!(r1)
      assert File.dir?(repo_parent)

      index_file = Repository.index_file!(r1)
      assert ^index_file = Path.join(git_dir, "index")

      # assertEqualsPath(new File(theDir, "objects"), r.getObjectDatabase()
      #     .getDirectory());
    end
  end
end
