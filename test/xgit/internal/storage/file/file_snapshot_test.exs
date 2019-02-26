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

  test "actually is modified (trivial case)", %{trash: trash} do
    f1 = create_file!(trash, "simple")
    wait_next_sec(f1)

    save = FileSnapshot.save(f1)
    append!(f1, 'x')

    wait_next_sec(f1)

    assert FileSnapshot.modified?(save, f1) == true
  end

  test "new file without significant wait", %{trash: trash} do
    f1 = create_file!(trash, "newfile")
    wait_next_sec(f1)

    save = FileSnapshot.save(f1)
    IO.inspect(save, label: "new snapshot")

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

  defp create_file!(trash, leaf_name) when is_binary(trash) and is_binary(leaf_name) do
    path = Path.expand(leaf_name, trash)
    File.touch!(path)
    path
  end

  defp append!(path, b) when is_binary(path) and is_list(b), do: File.write!(path, b, [:append])
end
