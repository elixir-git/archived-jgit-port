defmodule Xgit.Internal.Storage.File.RefDirectoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.RefDirectory
  alias Xgit.Lib.RefDatabase

  import ExUnit.CaptureLog

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")

    git_dir = Path.join(temp_file_path, ".git")
    File.mkdir_p!(git_dir)

    {:ok, ref_directory_pid} = RefDirectory.start_link(git_dir)
    {:ok, git_dir: git_dir, ref_directory: ref_directory_pid}
  end

  describe "create/1" do
    test "creates appropriate subdirectories", %{git_dir: git_dir, ref_directory: ref_directory} do
      assert :ok = RefDatabase.create(ref_directory)
      assert File.dir?(Path.join(git_dir, "refs"))
      assert File.dir?(Path.join(git_dir, "refs/heads"))
      assert File.dir?(Path.join(git_dir, "refs/tags"))
    end
  end

  test "handles unexpected calls", %{ref_directory: ref_directory} do
    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(ref_directory, :bogus)
           end) =~ "[warn]  RefDatabase received unrecognized call :bogus"

    assert Process.alive?(ref_directory)
  end
end
