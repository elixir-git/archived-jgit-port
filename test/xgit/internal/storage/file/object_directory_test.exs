defmodule Xgit.Internal.Storage.File.ObjectDirectoryTest do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.ObjectDirectory
  alias Xgit.Lib.Config
  alias Xgit.Lib.ObjectDatabase

  import ExUnit.CaptureLog

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")

    git_dir = Path.join(temp_file_path, ".git")
    objects_dir = Path.join(git_dir, "objects")
    File.mkdir_p!(objects_dir)

    {:ok, objects_dir: objects_dir}
  end

  describe "create/1" do
    test "creates appropriate subdirectories", %{objects_dir: objects_dir} do
      assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
      assert is_pid(pid)

      assert :ok = ObjectDatabase.create(pid)

      assert File.dir?(objects_dir)
      assert File.dir?(Path.join(objects_dir, "info"))
      assert File.dir?(Path.join(objects_dir, "pack"))
    end
  end

  describe "directory/1" do
    test "returns path to objects directory", %{objects_dir: objects_dir} do
      assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
      assert is_pid(pid)

      assert ObjectDirectory.directory(pid) == objects_dir
    end
  end

  test "handles unexpected calls", %{objects_dir: objects_dir} do
    assert {:ok, pid} = ObjectDirectory.start_link(config: Config.new(), objects: objects_dir)
    assert is_pid(pid)

    assert capture_log(fn ->
             assert {:error, :unknown_message} = GenServer.call(pid, :bogus)
           end) =~ "[warn]  ObjectDatabase received unrecognized call :bogus"

    assert Process.alive?(pid)
  end
end
