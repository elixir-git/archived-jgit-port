defmodule Xgit.Lib.ConstantsTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants
  doctest Xgit.Lib.Constants

  test "object_id_string_length/0" do
    assert Constants.object_id_string_length() == 40
  end

  test "obj_bad/0" do
    assert Constants.obj_bad() == -1
  end

  test "r_notes_commits/0" do
    assert Constants.r_notes_commits() == "refs/notes/commits"
  end

  test "r_stash/0" do
    assert Constants.r_stash() == "refs/stash"
  end

  describe "type_string/1" do
    test "commit" do
      assert Constants.type_string(1) == "commit"
    end

    test "tree" do
      assert Constants.type_string(2) == "tree"
    end

    test "blob" do
      assert Constants.type_string(3) == "blob"
    end

    test "tag" do
      assert Constants.type_string(4) == "tag"
    end

    test "error" do
      assert_raise(FunctionClauseError, fn -> Constants.type_string(5) end)
    end
  end

  describe "encoded_type_string/1" do
    test "commit" do
      assert Constants.encoded_type_string(1) == 'commit'
    end

    test "tree" do
      assert Constants.encoded_type_string(2) == 'tree'
    end

    test "blob" do
      assert Constants.encoded_type_string(3) == 'blob'
    end

    test "tag" do
      assert Constants.encoded_type_string(4) == 'tag'
    end

    test "error" do
      assert_raise FunctionClauseError, fn -> Constants.encoded_type_string(5) end
    end
  end

  describe "decode_type_string/3" do
    test "commit" do
      assert Constants.decode_type_string(nil, 'commit\nmumble', ?\n) == {1, 'mumble'}
    end

    test "tree" do
      assert Constants.decode_type_string(nil, 'tree\noak', ?\n) == {2, 'oak'}
    end

    test "blob" do
      assert Constants.decode_type_string(nil, 'blob 42', ?\s) == {3, '42'}
    end

    test "tag" do
      assert Constants.decode_type_string(nil, 'tag yup', ?\s) == {4, 'yup'}
    end

    test "error" do
      assert_raise Xgit.Errors.CorruptObjectError, fn ->
        Constants.decode_type_string("whatever", 'not_a_tag 42', ?\s)
      end
    end
  end

  describe "encode_ascii/1" do
    test "converts integers" do
      assert Constants.encode_ascii(42) == '42'
      assert Constants.encode_ascii(0) == '0'
      assert Constants.encode_ascii(-110) == '-110'
    end

    test "converts a simple ASCII string to charlist" do
      assert Constants.encode_ascii("abc") == 'abc'
    end

    test "raises ArgumentError on non-ASCII input" do
      assert_raise(ArgumentError, fn ->
        Constants.encode_ascii("Ūnĭcōde̽")
      end)
    end
  end
end
