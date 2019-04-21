defmodule Xgit.Lib.FileModeTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.FileMode

  doctest Xgit.Lib.FileMode

  test "tree/0" do
    assert %FileMode{mode_bits: 0o040000, object_type: 2, octal_bytes: '40000'} =
             tree = FileMode.tree()

    assert FileMode.match_mode_bits?(tree, 0o040000)
    refute FileMode.match_mode_bits?(tree, 0o100755)

    assert to_string(tree) == "40000"
  end

  test "symlink/0" do
    assert %FileMode{mode_bits: 0o120000, object_type: 3, octal_bytes: '120000'} =
             symlink = FileMode.symlink()

    assert FileMode.match_mode_bits?(symlink, 0o120000)
    refute FileMode.match_mode_bits?(symlink, 0o100755)

    assert to_string(symlink) == "120000"
  end

  test "regular_file/0" do
    assert %FileMode{mode_bits: 0o100644, object_type: 3, octal_bytes: '100644'} =
             regular_file = FileMode.regular_file()

    assert FileMode.match_mode_bits?(regular_file, 0o100644)
    refute FileMode.match_mode_bits?(regular_file, 0o100755)

    assert to_string(regular_file) == "100644"
  end

  test "executable_file/0" do
    assert %FileMode{mode_bits: 0o100755, object_type: 3, octal_bytes: '100755'} =
             executable_file = FileMode.executable_file()

    assert FileMode.match_mode_bits?(executable_file, 0o100755)
    refute FileMode.match_mode_bits?(executable_file, 0o100644)

    assert to_string(executable_file) == "100755"
  end

  test "gitlink/0" do
    assert %FileMode{mode_bits: 0o160000, object_type: 1, octal_bytes: '160000'} =
             gitlink = FileMode.gitlink()

    assert FileMode.match_mode_bits?(gitlink, 0o160000)
    refute FileMode.match_mode_bits?(gitlink, 0o100644)

    assert to_string(gitlink) == "160000"
  end

  test "missing/0" do
    assert %FileMode{mode_bits: 0, object_type: -1, octal_bytes: '0'} =
             missing = FileMode.missing()

    assert FileMode.match_mode_bits?(missing, 0)
    refute FileMode.match_mode_bits?(missing, 0o100644)

    assert to_string(missing) == "0"
  end

  test "from_bits/1" do
    assert FileMode.from_bits(0) == FileMode.missing()
    assert FileMode.from_bits(0o040000) == FileMode.tree()
    assert FileMode.from_bits(0o100755) == FileMode.executable_file()
    assert FileMode.from_bits(0o100645) == FileMode.executable_file()
    assert FileMode.from_bits(0o100644) == FileMode.regular_file()
    assert FileMode.from_bits(0o100600) == FileMode.regular_file()
    assert FileMode.from_bits(0o120000) == FileMode.symlink()
    assert FileMode.from_bits(0o160000) == FileMode.gitlink()

    assert FileMode.from_bits(0o140000) == %FileMode{
             mode_bits: 0o140000,
             object_type: -1,
             octal_bytes: '140000'
           }
  end
end
