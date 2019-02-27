defmodule Xgit.Internal.Storage.File.FileSnapshotTest do
  use ExUnit.Case, async: true

  alias Xgit.Internal.Storage.File.FileSnapshot

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")
    {:ok, trash: temp_file_path}
  end

  defp wait_next_sec(f) when is_binary(f) do
    %{mtime: initial_last_modified} = File.stat!(f, time: :posix)
    wait_next_sec(f, initial_last_modified)
  end

  defp wait_next_sec(f, initial_last_modified) do
    time_now = :os.system_time(:second)

    if time_now <= initial_last_modified do
      Process.sleep(100)
      wait_next_sec(f, initial_last_modified)
    end
  end

  test "missing_file/0", %{trash: trash} do
    missing = FileSnapshot.missing_file()
    path = Temp.path!()

    refute FileSnapshot.modified?(missing, path)

    f1 = create_file!(trash, "missing")
    assert FileSnapshot.modified?(missing, f1)

    assert to_string(missing) == "MISSING_FILE"
  end

  test "actually is modified (trivial case)", %{trash: trash} do
    f1 = create_file!(trash, "simple")
    wait_next_sec(f1)

    save = FileSnapshot.save(f1)
    append!(f1, 'x')

    wait_next_sec(f1)

    assert FileSnapshot.modified?(save, f1) == true

    assert String.starts_with?(to_string(save), "FileSnapshot")
  end

  test "new file without significant wait", %{trash: trash} do
    f1 = create_file!(trash, "newfile")
    wait_next_sec(f1)

    save = FileSnapshot.save(f1)

    Process.sleep(1500)
    assert FileSnapshot.modified?(save, f1) == true
  end

  test "new file without wait", %{trash: trash} do
    # Same as above but do not wait at all.

    f1 = create_file!(trash, "newfile")
    wait_next_sec(f1)

    save = FileSnapshot.save(f1)
    assert FileSnapshot.modified?(save, f1) == true
  end

  test "dirty snapshot is always dirty", %{trash: trash} do
    f1 = create_file!(trash, "newfile")
    wait_next_sec(f1)

    dirty = FileSnapshot.dirty()
    assert FileSnapshot.modified?(dirty, f1) == true

    assert to_string(dirty) == "DIRTY"
  end

  describe "set_clean/2" do
    test "without delay", %{trash: trash} do
      f1 = create_file!(trash, "newfile")
      wait_next_sec(f1)

      save = FileSnapshot.save(f1)
      assert FileSnapshot.modified?(save, f1) == true

      # an abuse of the API, but best we can do
      FileSnapshot.set_clean(save, save)
      assert FileSnapshot.modified?(save, f1) == false
    end

    test "with (faked) delay", %{trash: trash} do
      f1 = create_file!(trash, "newfile")
      wait_next_sec(f1)

      save = FileSnapshot.save(f1)
      assert FileSnapshot.modified?(save, f1) == true

      modified_earlier = %{save | last_modified: save.last_modified - 10}
      FileSnapshot.set_clean(modified_earlier, save)
      assert FileSnapshot.modified?(modified_earlier, f1) == true
    end
  end

  defp create_file!(trash, leaf_name) when is_binary(trash) and is_binary(leaf_name) do
    path = Path.expand(leaf_name, trash)
    File.touch!(path)
    path
  end

  defp append!(path, b) when is_binary(path) and is_list(b), do: File.write!(path, b, [:append])
end
