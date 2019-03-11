defmodule Xgit.Lib.ObjectCheckerTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.CorruptObjectError
  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectChecker
  alias Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy
  alias Xgit.Lib.ObjectId

  @placeholder_object_id 0..19 |> Enum.to_list()

  test "invalid object type" do
    assert_corrupt("invalid type -1", Constants.obj_bad(), [])
  end

  describe "check blob" do
    test "any blob should pass" do
      ObjectChecker.check!(%ObjectChecker{}, Constants.obj_blob(), [0])
      ObjectChecker.check!(%ObjectChecker{}, Constants.obj_blob(), [1])
    end

    test "strategy hook: blob not corrupt" do
      checker = %ObjectChecker{strategy: %SecretKeyCheckerStrategy{}}
      assert :ok = ObjectChecker.check!(checker, Constants.obj_blob(), 'public_key')
    end

    test "strategy hook: blob corrupt" do
      checker = %ObjectChecker{strategy: %SecretKeyCheckerStrategy{}}

      assert_raise CorruptObjectError, fn ->
        ObjectChecker.check!(checker, Constants.obj_blob(), 'secret_key')
      end
    end
  end

  describe "check commit" do
    test "valid: no parent" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> 1 +0000
      committer A. U. Thor <author@localhost> 1 +0000
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "valid: blank author" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author <> 0 +0000
      committer <> 0 +0000
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "invalid: corrupt author" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author b <b@c> <b@c> 0 +0000
      committer <> 0 +0000
      """

      assert_corrupt("bad date", Constants.obj_commit(), data)

      checker = %ObjectChecker{allow_invalid_person_ident?: true}
      assert :ok = ObjectChecker.check!(checker, Constants.obj_commit(), data)

      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: corrupt committer" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author <> 0 +0000
      committer b <b@c> <b@c> 0 +0000
      """

      assert_corrupt("bad date", Constants.obj_commit(), data)

      checker = %ObjectChecker{allow_invalid_person_ident?: true}
      assert :ok = ObjectChecker.check!(checker, Constants.obj_commit(), data)

      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "valid: one parent" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> 1 +0000
      committer A. U. Thor <author@localhost> 1 +0000
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "valid: two parents" do
      data = ~C"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> 1 +0000
      committer A. U. Thor <author@localhost> 1 +0000
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "valid: 128 parents" do
      data =
        'tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          (1..128
           |> Enum.map(fn _ -> 'parent be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' end)
           |> Enum.concat()) ++
          'author A. U. Thor <author@localhost> 1 +0000\n' ++
          'committer A. U. Thor <author@localhost> 1 +0000\n'

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "valid: normal time" do
      ts = "1222757360 -0730"

      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> #{ts}
      committer A. U. Thor <author@localhost> #{ts}
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_commit(), data)
    end

    test "invalid: no tree 1" do
      data = ~C"""
      parent be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no tree header", Constants.obj_commit(), data)
    end

    test "invalid: no tree 2" do
      data = ~C"""
      trie be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no tree header", Constants.obj_commit(), data)
    end

    test "invalid: no tree 3" do
      data = ~C"""
      treebe9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no tree header", Constants.obj_commit(), data)
    end

    test "invalid: no tree 4" do
      data = ~c"""
      tree\tbe9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no tree header", Constants.obj_commit(), data)
    end

    test "invalid: invalid tree 1" do
      data = ~c"""
      tree zzzzfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("invalid tree", Constants.obj_commit(), data)
    end

    test "invalid: invalid tree 2" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189z
      """

      assert_corrupt("invalid tree", Constants.obj_commit(), data)
    end

    test "invalid: invalid tree 3" do
      data = ~c"""
      tree be9b
      """

      assert_corrupt("invalid tree", Constants.obj_commit(), data)
    end

    test "invalid: invalid tree 4" do
      data = ~c"""
      tree  be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("invalid tree", Constants.obj_commit(), data)
    end

    test "invalid: invalid parent 1" do
      data =
        'tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'parent \n'

      assert_corrupt("invalid parent", Constants.obj_commit(), data)
    end

    test "invalid: invalid parent 2" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent zzzzfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("invalid parent", Constants.obj_commit(), data)
    end

    test "invalid: invalid parent 3" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent  be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("invalid parent", Constants.obj_commit(), data)
    end

    test "invalid: invalid parent 4" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent  be9bfa841874ccc9f2ef7c48d0c76226f89b7189z
      """

      assert_corrupt("invalid parent", Constants.obj_commit(), data)
    end

    test "invalid: invalid parent 5" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      parent\tbe9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      # Yes, really, we complain about author not being
      # found as the invalid parent line wasn't consumed.
      assert_corrupt("no author", Constants.obj_commit(), data)
    end

    test "invalid: no author" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      committer A. U. Thor <author@localhost> 1 +0000
      """

      assert_corrupt("no author", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: no committer 1" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> 1 +0000
      """

      assert_corrupt("no committer", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: no committer 2" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <author@localhost> 1 +0000

      """

      assert_corrupt("no committer", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 1" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor <foo 1 +0000
      """

      assert_corrupt("bad email", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 2" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author A. U. Thor foo> 1 +0000
      """

      assert_corrupt("missing email", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 3" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author 1 +0000
      """

      assert_corrupt("missing email", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 4" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author a <b> +0000
      """

      assert_corrupt("bad date", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 5" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author a <b>
      """

      assert_corrupt("bad date", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 6" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author a <b> z
      """

      assert_corrupt("bad date", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid author 7" do
      data = ~c"""
      tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      author a <b> 1 z
      """

      assert_corrupt("bad time zone", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end

    test "invalid: invalid committer" do
      data =
        'tree be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'author a <b> 1 +0000\n' ++
          'committer a <'

      assert_corrupt("bad email", Constants.obj_commit(), data)
      assert_skiplist_accepts(Constants.obj_commit(), data)
    end
  end

  describe "check tag" do
    test "valid" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      type commit
      tag test-tag
      tagger A. U. Thor <author@localhost> 1 +0000
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tag(), data)
    end

    test "invalid: no object 1" do
      assert_corrupt("no object header", Constants.obj_tag(), [])
    end

    test "invalid: no object 2" do
      data = 'object\tbe9bfa841874ccc9f2ef7c48d0c76226f89b7189\n'
      assert_corrupt("no object header", Constants.obj_tag(), data)
    end

    test "invalid: no object 3" do
      data = ~c"""
      obejct be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no object header", Constants.obj_tag(), data)
    end

    test "invalid: no object 4" do
      data = ~c"""
      object zz9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("invalid object", Constants.obj_tag(), data)
    end

    test "invalid: no object 5" do
      data = 'object be9bfa841874ccc9f2ef7c48d0c76226f89b7189 \n'
      assert_corrupt("invalid object", Constants.obj_tag(), data)
    end

    test "invalid: no object 6" do
      data = 'object be9'
      assert_corrupt("invalid object", Constants.obj_tag(), data)
    end

    test "invalid: no type 1" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      """

      assert_corrupt("no type header", Constants.obj_tag(), data)
    end

    test "invalid: no type 2" do
      data =
        'object be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'type\tcommit\n'

      assert_corrupt("no type header", Constants.obj_tag(), data)
    end

    test "invalid: no type 3" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      tpye commit
      """

      assert_corrupt("no type header", Constants.obj_tag(), data)
    end

    test "invalid: no type 4" do
      data =
        'object be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'type commit'

      assert_corrupt("no tag header", Constants.obj_tag(), data)
    end

    test "invalid: no tag header 1" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      type commit
      """

      assert_corrupt("no tag header", Constants.obj_tag(), data)
    end

    test "invalid: no tag header 2" do
      data =
        'object be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'type commit\n' ++
          'tag\tfoo\n'

      assert_corrupt("no tag header", Constants.obj_tag(), data)
    end

    test "invalid: no tag header 3" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      type commit
      tga foo
      """

      assert_corrupt("no tag header", Constants.obj_tag(), data)
    end

    test "valid: has no tagger header" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      type commit
      tag foo
      """

      assert :ok = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tag(), data)
    end

    test "invalid: invalid tagger header 1" do
      data =
        'object be9bfa841874ccc9f2ef7c48d0c76226f89b7189\n' ++
          'type commit\n' ++
          'tag foo\n' ++
          'tagger \n'

      assert_corrupt("missing email", Constants.obj_tag(), data)

      assert :ok =
               ObjectChecker.check!(
                 %ObjectChecker{allow_invalid_person_ident?: true},
                 Constants.obj_tag(),
                 data
               )

      assert_skiplist_accepts(Constants.obj_tag(), data)
    end

    test "invalid: invalid tagger header 3" do
      data = ~c"""
      object be9bfa841874ccc9f2ef7c48d0c76226f89b7189
      type commit
      tag foo
      tagger a < 1 +000
      """

      assert_corrupt("bad email", Constants.obj_tag(), data)
    end
  end

  describe "check tree" do
    test "valid: empty tree" do
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), [])
    end

    test "valid tree 1" do
      data = entry("100644 regular-file")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid tree 2" do
      data = entry("100755 executable")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid tree 3" do
      data = entry("40000 tree")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid tree 4" do
      data = entry("120000 symlink")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid tree 5" do
      data = entry("160000 git link")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid tree 6" do
      data = entry("100644 .a")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: .gitmodules" do
      data = entry("100644 .gitmodules")

      assert {:ok,
              [
                {"0123012301230123012301230123012301230123",
                 "000102030405060708090a0b0c0d0e0f10111213"}
              ]} =
               ObjectChecker.check!(
                 %ObjectChecker{},
                 "0123012301230123012301230123012301230123",
                 Constants.obj_tree(),
                 data
               )
    end

    @ntfs_gitmodules [
      ".GITMODULES",
      ".gitmodules",
      ".Gitmodules",
      ".gitmoduleS",
      "gitmod~1",
      "GITMOD~1",
      "gitmod~4",
      "GI7EBA~1",
      "gi7eba~9",
      "GI7EB~10",
      "GI7E~123",
      "~1000000",
      "~9999999"
    ]

    test "valid: NTFS .gitmodules" do
      # Windows case insensitivity and long file name handling
      # means that .gitmodules has many synonyms.
      #
      # Examples inspired by git.git's t/t0060-path-utils.sh, by
      # Johannes Schindelin and Congyi Wu.

      Enum.each(@ntfs_gitmodules, fn gitmodules_name ->
        data = entry("100644 #{gitmodules_name}")

        assert {:ok,
                [
                  {"0123012301230123012301230123012301230123",
                   "000102030405060708090a0b0c0d0e0f10111213"}
                ]} =
                 ObjectChecker.check!(
                   %ObjectChecker{windows?: true},
                   "0123012301230123012301230123012301230123",
                   Constants.obj_tree(),
                   data
                 )
      end)
    end

    @not_gitmodules [".gitmodu", ".gitmodules oh never mind"]

    test "valid: NTFS names that aren't .gitmodules" do
      Enum.each(@not_gitmodules, fn not_gitmodules_name ->
        data = entry("100644 #{not_gitmodules_name}")

        assert {:ok, []} =
                 ObjectChecker.check!(
                   %ObjectChecker{windows?: true},
                   "0123012301230123012301230123012301230123",
                   Constants.obj_tree(),
                   data
                 )
      end)
    end

    # UNIMPLEMENTED in jgit: HFS: match ".gitmodules" case-insensitively, after
    # stripping out certain zero-length Unicode code points that HFS+ strips out.

    test "valid: .GITMODULES" do
      data = entry("100644 .GITMODULES")

      assert {:ok,
              [
                {"0123012301230123012301230123012301230123",
                 "000102030405060708090a0b0c0d0e0f10111213"}
              ]} =
               ObjectChecker.check!(
                 %ObjectChecker{windows?: true},
                 "0123012301230123012301230123012301230123",
                 Constants.obj_tree(),
                 data
               )
    end

    test "valid: name that isn't .gitmodules" do
      data = entry("100644 .gitmodulez")

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{windows?: true},
                 "0123012301230123012301230123012301230123",
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: null SHA-1 in tree entry" do
      data = '100644 A' ++ Enum.map(0..20, fn _ -> 0 end)

      assert_corrupt("entry points to null SHA-1", Constants.obj_tree(), data)

      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{null_sha1: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "valid: posix names" do
      check_one_name("a<b>c:d|e")
      check_one_name("test ")
      check_one_name("test.")
      check_one_name("NUL")
    end

    test "valid: sorting 1" do
      data = entry("100644 fooaaa") ++ entry("100755 foobar")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 2" do
      data = entry("100755 fooaaa") ++ entry("100644 foobar")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 3" do
      data = entry("40000 a") ++ entry("100644 b")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 4" do
      data = entry("100644 a") ++ entry("40000 b")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 5" do
      data = entry("100644 a.c") ++ entry("40000 a") ++ entry("100644 a0c")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 6" do
      data = entry("40000 a") ++ entry("100644 apple")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 7" do
      data = entry("40000 an orang") ++ entry("40000 an orange")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: sorting 8" do
      data = entry("100644 a") ++ entry("100644 a0c") ++ entry("100644 b")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: mode with zero (with flags set)" do
      data = entry("040000 a")

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{zero_padded_filemode: true}},
                 Constants.obj_tree(),
                 data
               )

      assert_skiplist_accepts(Constants.obj_tree(), data)
    end

    test "invalid: mode starts with zero 1" do
      data = entry("0 a")
      assert_corrupt("mode starts with '0'", Constants.obj_tree(), data)
    end

    test "invalid: mode starts with zero 2" do
      data = entry("0100644 a")
      assert_corrupt("mode starts with '0'", Constants.obj_tree(), data)
    end

    test "invalid: mode starts with zero 3" do
      data = entry("040000 a")
      assert_corrupt("mode starts with '0'", Constants.obj_tree(), data)
    end

    test "invalid: mode not octal 1" do
      data = entry("8 a")
      assert_corrupt("invalid mode character", Constants.obj_tree(), data)
    end

    test "invalid: mode not octal 2" do
      data = entry("Z a")
      assert_corrupt("invalid mode character", Constants.obj_tree(), data)
      assert_skiplist_rejects("invalid mode character", Constants.obj_tree(), data)
    end

    test "invalid: mode not supported mode 1" do
      data = entry("1 a")
      assert_corrupt("invalid mode 1", Constants.obj_tree(), data)
      assert_skiplist_rejects("invalid mode 1", Constants.obj_tree(), data)
    end

    test "invalid: mode not supported mode 2" do
      data = entry("170000 a")
      assert_corrupt("invalid mode 61440", Constants.obj_tree(), data)
      assert_skiplist_rejects("invalid mode 61440", Constants.obj_tree(), data)
    end

    test "invalid: name contains slash" do
      data = entry("100644 a/b")
      assert_corrupt("name contains '/'", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{full_pathname: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: name is empty" do
      data = entry("100644 ")
      assert_corrupt("zero length name", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{empty_name: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: name is '.'" do
      data = entry("100644 .")
      assert_corrupt("invalid name '.'", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{has_dot: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: name is '..'" do
      data = entry("100644 ..")
      assert_corrupt("invalid name '..'", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{has_dotdot: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: name is '.git'" do
      data = entry("100644 .git")
      assert_corrupt("invalid name '.git'", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{has_dotgit: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    test "invalid: name is '.git' (mixed case)" do
      data = entry("100644 .GiT")
      assert_corrupt("invalid name '.GiT'", Constants.obj_tree(), data)
      assert_skiplist_accepts(Constants.obj_tree(), data)

      assert {:ok, []} =
               ObjectChecker.check!(
                 %ObjectChecker{ignore_error_types: %{has_dotgit: true}},
                 Constants.obj_tree(),
                 data
               )
    end

    @mac_hfs_git_names [
      ".gi\u200Ct",
      "\u206B.git",
      ".git\uFEFF"
    ]

    test "invalid: name is Mac HFS .git" do
      Enum.each(@mac_hfs_git_names, fn name ->
        data = entry("100644 #{name}")

        # This is fine on Posix.
        assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)

        # Rejected on Mac OS.
        mac_checker = %ObjectChecker{macosx?: true}

        assert_corrupt(
          mac_checker,
          "invalid name '#{name}' contains ignorable Unicode characters",
          Constants.obj_tree(),
          data
        )

        assert_skiplist_accepts(mac_checker, Constants.obj_tree(), data)
      end)
    end

    test "invalid: name is Mac HFS .git with corrupt UTF-8 at end 1" do
      data = '100644 .git' ++ [0xEF] ++ '\0#{@placeholder_object_id}'

      # This is fine on Posix.
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)

      # Rejected on Mac OS.
      mac_checker = %ObjectChecker{macosx?: true}

      assert_corrupt(
        mac_checker,
        "invalid name contains byte sequence '0xef' which is not a valid UTF-8 character",
        Constants.obj_tree(),
        data
      )

      assert_skiplist_accepts(mac_checker, Constants.obj_tree(), data)
    end

    test "invalid: name is Mac HFS .git with corrupt UTF-8 at end 2" do
      data = '100644 .git' ++ [0xE2, 0xAB] ++ '\0#{@placeholder_object_id}'

      # This is fine on Posix.
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)

      # Rejected on Mac OS.
      mac_checker = %ObjectChecker{macosx?: true}

      assert_corrupt(
        mac_checker,
        "invalid name contains byte sequence '0xe2ab' which is not a valid UTF-8 character",
        Constants.obj_tree(),
        data
      )

      assert_skiplist_accepts(mac_checker, Constants.obj_tree(), data)
    end

    test "valid: name is not Mac HFS .git 1" do
      data = entry("100644 .git\u200Cx")

      assert {:ok, []} =
               ObjectChecker.check!(%ObjectChecker{macosx?: true}, Constants.obj_tree(), data)
    end

    test "valid: name is not Mac HFS .git 2" do
      data = entry("100644 .kit\u200C")

      assert {:ok, []} =
               ObjectChecker.check!(%ObjectChecker{macosx?: true}, Constants.obj_tree(), data)
    end

    test "valid: name is not Mac HFS .git (other platform)" do
      data = entry("100644 .git\u200C")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    @bad_dot_git_names [".git.", ".git ", ".git. ", ".git . "]

    test "invalid: tree name is variant of .git" do
      Enum.each(@bad_dot_git_names, fn bad_name ->
        data = entry("100644 #{bad_name}")

        assert_corrupt(%ObjectChecker{}, "invalid name '#{bad_name}'", Constants.obj_tree(), data)
        assert_skiplist_accepts(%ObjectChecker{}, Constants.obj_tree(), data)

        assert {:ok, []} =
                 ObjectChecker.check!(
                   %ObjectChecker{ignore_error_types: %{has_dotgit: true}},
                   Constants.obj_tree(),
                   data
                 )
      end)
    end

    test "valid: name is .git.." do
      data = entry("100644 .git..")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: name is .gitsomething" do
      data = entry("100644 .gitfoobar")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: name is .git-space-something" do
      data = entry("100644 .gitfoo bar")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: name is .gitfoobar." do
      data = entry("100644 .gitfoobar.")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "valid: name is .gitfoobar.." do
      data = entry("100644 .gitfoobar..")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    @bad_dot_git_tilde_names ["GIT~1", "GiT~1"]

    test "invalid: tree name is variant of git~1" do
      Enum.each(@bad_dot_git_tilde_names, fn bad_name ->
        data = entry("100644 #{bad_name}")

        assert_corrupt(%ObjectChecker{}, "invalid name '#{bad_name}'", Constants.obj_tree(), data)
        assert_skiplist_accepts(%ObjectChecker{}, Constants.obj_tree(), data)

        assert {:ok, []} =
                 ObjectChecker.check!(
                   %ObjectChecker{ignore_error_types: %{has_dotgit: true}},
                   Constants.obj_tree(),
                   data
                 )
      end)
    end

    test "valid: name is GIT~11" do
      data = entry("100644 GIT~11")
      assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
    end

    test "invalid: tree truncated in name" do
      data = '100644 b'

      assert_corrupt(%ObjectChecker{}, "truncated in name", Constants.obj_tree(), data)
      assert_skiplist_rejects("truncated in name", Constants.obj_tree(), data)
    end

    test "invalid: tree truncated in object ID" do
      data = '100644 b' ++ [0, 1, 2]

      assert_corrupt(%ObjectChecker{}, "truncated in object id", Constants.obj_tree(), data)
      assert_skiplist_rejects("truncated in object id", Constants.obj_tree(), data)
    end

    # @Test
    # public void testInvalidTreeBadSorting1() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 foobar");
    # 	entry(b, "100644 fooaaa");
    # 	byte[] data = encodeASCII(b.toString());
    #
    # 	assertCorrupt("incorrectly sorted", OBJ_TREE, data);
    #
    # 	ObjectId id = idFor(OBJ_TREE, data);
    # 	try {
    # 		checker.check(id, OBJ_TREE, data);
    # 		fail("Did not throw CorruptObjectException");
    # 	} catch (CorruptObjectException e) {
    # 		assertSame(TREE_NOT_SORTED, e.getErrorType());
    # 		assertEquals("treeNotSorted: object " + id.name()
    # 				+ ": incorrectly sorted", e.getMessage());
    # 	}
    #
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(TREE_NOT_SORTED, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeBadSorting2() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "40000 a");
    # 	entry(b, "100644 a.c");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("incorrectly sorted", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(TREE_NOT_SORTED, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeBadSorting3() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a0c");
    # 	entry(b, "40000 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("incorrectly sorted", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(TREE_NOT_SORTED, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames1_File()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "100644 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames1_Tree()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "40000 a");
    # 	entry(b, "40000 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames2() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "100755 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames3() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "40000 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames4() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "100644 a.c");
    # 	entry(b, "100644 a.d");
    # 	entry(b, "100644 a.e");
    # 	entry(b, "40000 a");
    # 	entry(b, "100644 zoo");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames5()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 A");
    # 	entry(b, "100644 a");
    # 	byte[] data = b.toString().getBytes(UTF_8);
    # 	checker.setSafeForWindows(true);
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames6()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 A");
    # 	entry(b, "100644 a");
    # 	byte[] data = b.toString().getBytes(UTF_8);
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames7()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 \u0065\u0301");
    # 	entry(b, "100644 \u00e9");
    # 	byte[] data = b.toString().getBytes(UTF_8);
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt("duplicate entry names", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(DUPLICATE_ENTRIES, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeDuplicateNames8()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 A");
    # 	checker.setSafeForMacOS(true);
    # 	checker.checkTree(b.toString().getBytes(UTF_8));
    # }
    #
    # @Test
    # public void testRejectNulInPathSegment() {
    # 	try {
    # 		checker.checkPathSegment(encodeASCII("a\u0000b"), 0, 3);
    # 		fail("incorrectly accepted NUL in middle of name");
    # 	} catch (CorruptObjectException e) {
    # 		assertEquals("name contains byte 0x00", e.getMessage());
    # 	}
    # }
    #
    # @Test
    # public void testRejectSpaceAtEndOnWindows() {
    # 	checker.setSafeForWindows(true);
    # 	try {
    # 		checkOneName("test ");
    # 		fail("incorrectly accepted space at end");
    # 	} catch (CorruptObjectException e) {
    # 		assertEquals("invalid name ends with ' '", e.getMessage());
    # 	}
    # }
    #
    # @Test
    # public void testBug477090() throws CorruptObjectException {
    # 	checker.setSafeForMacOS(true);
    # 	final byte[] bytes = {
    # 			// U+221E 0xe2889e INFINITY ∞
    # 			(byte) 0xe2, (byte) 0x88, (byte) 0x9e,
    # 			// .html
    # 			0x2e, 0x68, 0x74, 0x6d, 0x6c };
    # 	checker.checkPathSegment(bytes, 0, bytes.length);
    # }
    #
    # @Test
    # public void testRejectDotAtEndOnWindows() {
    # 	checker.setSafeForWindows(true);
    # 	try {
    # 		checkOneName("test.");
    # 		fail("incorrectly accepted dot at end");
    # 	} catch (CorruptObjectException e) {
    # 		assertEquals("invalid name ends with '.'", e.getMessage());
    # 	}
    # }
    #
    # @Test
    # public void testRejectDevicesOnWindows() {
    # 	checker.setSafeForWindows(true);
    #
    # 	String[] bad = { "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3",
    # 			"COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2",
    # 			"LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9" };
    # 	for (String b : bad) {
    # 		try {
    # 			checkOneName(b);
    # 			fail("incorrectly accepted " + b);
    # 		} catch (CorruptObjectException e) {
    # 			assertEquals("invalid name '" + b + "'", e.getMessage());
    # 		}
    # 		try {
    # 			checkOneName(b + ".txt");
    # 			fail("incorrectly accepted " + b + ".txt");
    # 		} catch (CorruptObjectException e) {
    # 			assertEquals("invalid name '" + b + "'", e.getMessage());
    # 		}
    # 	}
    # }
    #
    # @Test
    # public void testRejectInvalidWindowsCharacters() {
    # 	checker.setSafeForWindows(true);
    # 	rejectName('<');
    # 	rejectName('>');
    # 	rejectName(':');
    # 	rejectName('"');
    # 	rejectName('/');
    # 	rejectName('\\');
    # 	rejectName('|');
    # 	rejectName('?');
    # 	rejectName('*');
    #
    # 	for (int i = 1; i <= 31; i++)
    # 		rejectName((byte) i);
    # }
  end

  # private void rejectName(char c) {
  # 	try {
  # 		checkOneName("te" + c + "st");
  # 		fail("incorrectly accepted with " + c);
  # 	} catch (CorruptObjectException e) {
  # 		assertEquals("name contains '" + c + "'", e.getMessage());
  # 	}
  # }
  #
  # private void rejectName(byte c) {
  # 	String h = Integer.toHexString(c);
  # 	try {
  # 		checkOneName("te" + ((char) c) + "st");
  # 		fail("incorrectly accepted with 0x" + h);
  # 	} catch (CorruptObjectException e) {
  # 		assertEquals("name contains byte 0x" + h, e.getMessage());
  # 	}
  # }

  defp check_one_name(name) do
    data = entry("100644 #{name}")
    assert {:ok, []} = ObjectChecker.check!(%ObjectChecker{}, Constants.obj_tree(), data)
  end

  defp entry(mode_name), do: '#{:binary.bin_to_list(mode_name)}\0#{@placeholder_object_id}'

  defp assert_corrupt(checker \\ %ObjectChecker{}, msg, type, data)
       when is_binary(msg) and is_integer(type) and is_list(data) do
    assert_raise CorruptObjectError, "Object (unknown) is corrupt: #{msg}", fn ->
      ObjectChecker.check!(checker, type, data)
    end
  end

  defp assert_skiplist_accepts(checker \\ %ObjectChecker{}, type, data)

  defp assert_skiplist_accepts(checker, 2 = type, data) do
    # type 2 = tree
    id = ObjectId.id_for(type, data)
    skiplist = MapSet.new([id])
    checker = %{checker | skiplist: skiplist}
    assert {:ok, []} = ObjectChecker.check!(checker, type, data)
  end

  defp assert_skiplist_accepts(checker, type, data) do
    id = ObjectId.id_for(type, data)
    skiplist = MapSet.new([id])
    checker = %{checker | skiplist: skiplist}
    assert :ok = ObjectChecker.check!(checker, type, data)
  end

  defp assert_skiplist_rejects(message, type, data) do
    id = ObjectId.id_for(type, data)
    skiplist = MapSet.new([id])
    checker = %ObjectChecker{skiplist: skiplist}

    assert_raise CorruptObjectError, "Object (unknown) is corrupt: #{message}", fn ->
      ObjectChecker.check!(checker, type, data)
    end
  end

  # private static ObjectIdSet set(ObjectId... ids) {
  # 	return new ObjectIdSet() {
  # 		@Override
  # 		public boolean contains(AnyObjectId objectId) {
  # 			for (ObjectId id : ids) {
  # 				if (id.equals(objectId)) {
  # 					return true;
  # 				}
  # 			}
  # 			return false;
  # 		}
  # 	};
  # }
  #
  # @SuppressWarnings("resource")
  # private static ObjectId idFor(int type, byte[] raw) {
  # 	return new ObjectInserter.Formatter().idFor(type, raw);
  # }
end
