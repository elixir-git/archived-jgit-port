defmodule Xgit.Util.PathsTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.FileMode
  alias Xgit.Util.Paths

  describe "strip_trailing_separator/1" do
    test "empty list" do
      assert Paths.strip_trailing_separator([]) == []
    end

    test "without trailing /" do
      assert Paths.strip_trailing_separator('abc') == 'abc'
      assert Paths.strip_trailing_separator('/abc') == '/abc'
      assert Paths.strip_trailing_separator('foo/b') == 'foo/b'
    end

    test "with trailing /" do
      assert Paths.strip_trailing_separator('/') == []
      assert Paths.strip_trailing_separator('abc/') == 'abc'
      assert Paths.strip_trailing_separator('foo/bar//') == 'foo/bar'
    end
  end

  describe "compare/4" do
    test "simple case (paths don't match)" do
      assert Paths.compare('abc', FileMode.type_file(), 'def', FileMode.type_file()) == :lt
      assert Paths.compare('abc', FileMode.type_file(), 'aba', FileMode.type_file()) == :gt
    end

    test "lengths mismatch" do
      assert Paths.compare('abc', FileMode.type_file(), 'ab', FileMode.type_file()) == :gt
      assert Paths.compare('ab', FileMode.type_file(), 'aba', FileMode.type_file()) == :lt
    end

    test "implied / for file tree" do
      assert Paths.compare('ab/', FileMode.type_tree(), 'ab', FileMode.type_tree()) == :eq
      assert Paths.compare('ab', FileMode.type_tree(), 'ab/', FileMode.type_tree()) == :eq
    end

    test "exact match" do
      assert Paths.compare('abc', FileMode.type_file(), 'abc', FileMode.type_file()) == :eq
    end

    test "match except for file mode" do
      assert Paths.compare('abc', FileMode.type_tree(), 'abc', FileMode.type_file()) == :gt
      assert Paths.compare('abc', FileMode.type_file(), 'abc', FileMode.type_tree()) == :lt
    end

    test "gitlink exception" do
      assert Paths.compare('abc', FileMode.type_tree(), 'abc', FileMode.type_gitlink()) == :eq
      assert Paths.compare('abc', FileMode.type_gitlink(), 'abc', FileMode.type_tree()) == :eq
    end
  end

  describe "compare_same_name/3" do
    test "simple case (paths don't match)" do
      assert Paths.compare_same_name('abc', 'def', FileMode.type_file()) == :lt
      assert Paths.compare_same_name('abc', 'aba', FileMode.type_file()) == :gt
    end

    test "lengths mismatch" do
      assert Paths.compare_same_name('abc', 'ab', FileMode.type_file()) == :gt
      assert Paths.compare_same_name('ab', 'aba', FileMode.type_file()) == :lt
    end

    test "implied / for file tree" do
      assert Paths.compare_same_name('ab/', 'ab', FileMode.type_tree()) == :eq
      assert Paths.compare_same_name('ab', 'ab/', FileMode.type_tree()) == :eq
    end

    test "exact match, different type" do
      assert Paths.compare_same_name('abc', 'abc', FileMode.type_file()) == :eq
    end

    test "exact match, same type" do
      assert Paths.compare_same_name('abc', 'abc', FileMode.type_tree()) == :eq
    end

    test "match except for file mode" do
      assert Paths.compare_same_name('abc', 'abc', FileMode.type_file()) == :eq
    end

    test "gitlink exception" do
      assert Paths.compare_same_name('abc', 'abc', FileMode.type_gitlink()) == :eq
    end
  end
end
