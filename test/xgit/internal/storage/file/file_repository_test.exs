defmodule Xgit.Internal.Storage.File.FileRepositoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.FileRepository
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
      # repo when `gitDir` is given.

      repo_parent = Path.join(trash, "r1")
      git_dir = Path.join(repo_parent, Constants.dot_git())

      r1 = FileRepository.from_git_dir!(git_dir)
      assert r1 = Repository.create!(r1)

      # File theDir = new File(repo1Parent, Constants.DOT_GIT);
      # FileRepository r = (FileRepository) new FileRepositoryBuilder()
      #     .setGitDir(theDir).build();
      # assertEqualsPath(theDir, r.getDirectory());
      # assertEqualsPath(repo1Parent, r.getWorkTree());
      # assertEqualsPath(new File(theDir, "index"), r.getIndexFile());
      # assertEqualsPath(new File(theDir, "objects"), r.getObjectDatabase()
      #     .getDirectory());
    end
  end
end
