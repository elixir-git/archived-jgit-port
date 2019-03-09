defmodule Xgit.Lib.ObjectCheckerTest do
  use ExUnit.Case, async: true

  alias Xgit.Errors.CorruptObjectError
  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectChecker
  alias Xgit.Lib.ObjectChecker.SecretKeyCheckerStrategy
  alias Xgit.Lib.ObjectId

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

    test "valid tree with .gitmodules" do
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

    # @Test
    # public void testValidTreeWithGitmodules() throws CorruptObjectException {
    # 	ObjectId treeId = ObjectId
    # 			.fromString("0123012301230123012301230123012301230123");
    # 	StringBuilder b = new StringBuilder();
    # 	ObjectId blobId = entry(b, "100644 .gitmodules");
    #
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(treeId, data);
    # 	assertEquals(1, checker.getGitsubmodules().size());
    # 	assertEquals(treeId, checker.getGitsubmodules().get(0).getTreeId());
    # 	assertEquals(blobId, checker.getGitsubmodules().get(0).getBlobId());
    # }
    #
    # /*
    #  * Windows case insensitivity and long file name handling
    #  * means that .gitmodules has many synonyms.
    #  *
    #  * Examples inspired by git.git's t/t0060-path-utils.sh, by
    #  * Johannes Schindelin and Congyi Wu.
    #  */
    # @Test
    # public void testNTFSGitmodules() throws CorruptObjectException {
    # 	for (String gitmodules : new String[] {
    # 		".GITMODULES",
    # 		".gitmodules",
    # 		".Gitmodules",
    # 		".gitmoduleS",
    # 		"gitmod~1",
    # 		"GITMOD~1",
    # 		"gitmod~4",
    # 		"GI7EBA~1",
    # 		"gi7eba~9",
    # 		"GI7EB~10",
    # 		"GI7E~123",
    # 		"~1000000",
    # 		"~9999999"
    # 	}) {
    # 		checker = new ObjectChecker(); // Reset the ObjectChecker state.
    # 		checker.setSafeForWindows(true);
    # 		ObjectId treeId = ObjectId
    # 				.fromString("0123012301230123012301230123012301230123");
    # 		StringBuilder b = new StringBuilder();
    # 		ObjectId blobId = entry(b, "100644 " + gitmodules);
    #
    # 		byte[] data = encodeASCII(b.toString());
    # 		checker.checkTree(treeId, data);
    # 		assertEquals(1, checker.getGitsubmodules().size());
    # 		assertEquals(treeId, checker.getGitsubmodules().get(0).getTreeId());
    # 		assertEquals(blobId, checker.getGitsubmodules().get(0).getBlobId());
    # 	}
    # }
    #
    # @Test
    # public void testNotGitmodules() throws CorruptObjectException {
    # 	for (String notGitmodules : new String[] {
    # 		".gitmodu",
    # 		".gitmodules oh never mind",
    # 	}) {
    # 		checker = new ObjectChecker(); // Reset the ObjectChecker state.
    # 		checker.setSafeForWindows(true);
    # 		ObjectId treeId = ObjectId
    # 				.fromString("0123012301230123012301230123012301230123");
    # 		StringBuilder b = new StringBuilder();
    # 		entry(b, "100644 " + notGitmodules);
    #
    # 		byte[] data = encodeASCII(b.toString());
    # 		checker.checkTree(treeId, data);
    # 		assertEquals(0, checker.getGitsubmodules().size());
    # 	}
    # }
    #
    # /*
    #  * TODO HFS: match ".gitmodules" case-insensitively, after stripping out
    #  * certain zero-length Unicode code points that HFS+ strips out
    #  */
    #
    # @Test
    # public void testValidTreeWithGitmodulesUppercase()
    # 		throws CorruptObjectException {
    # 	ObjectId treeId = ObjectId
    # 			.fromString("0123012301230123012301230123012301230123");
    # 	StringBuilder b = new StringBuilder();
    # 	ObjectId blobId = entry(b, "100644 .GITMODULES");
    #
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.setSafeForWindows(true);
    # 	checker.checkTree(treeId, data);
    # 	assertEquals(1, checker.getGitsubmodules().size());
    # 	assertEquals(treeId, checker.getGitsubmodules().get(0).getTreeId());
    # 	assertEquals(blobId, checker.getGitsubmodules().get(0).getBlobId());
    # }
    #
    # @Test
    # public void testTreeWithInvalidGitmodules() throws CorruptObjectException {
    # 	ObjectId treeId = ObjectId
    # 			.fromString("0123012301230123012301230123012301230123");
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gitmodulez");
    #
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(treeId, data);
    # 	checker.setSafeForWindows(true);
    # 	assertEquals(0, checker.getGitsubmodules().size());
    # }
    #
    # @Test
    # public void testNullSha1InTreeEntry() throws CorruptObjectException {
    # 	byte[] data = concat(
    # 			encodeASCII("100644 A"), new byte[] { '\0' },
    # 			new byte[OBJECT_ID_LENGTH]);
    # 	assertCorrupt("entry points to null SHA-1", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(NULL_SHA1, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testValidPosixTree() throws CorruptObjectException {
    # 	checkOneName("a<b>c:d|e");
    # 	checkOneName("test ");
    # 	checkOneName("test.");
    # 	checkOneName("NUL");
    # }
    #
    # @Test
    # public void testValidTreeSorting1() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 fooaaa");
    # 	entry(b, "100755 foobar");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting2() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100755 fooaaa");
    # 	entry(b, "100644 foobar");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting3() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "40000 a");
    # 	entry(b, "100644 b");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting4() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "40000 b");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting5() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a.c");
    # 	entry(b, "40000 a");
    # 	entry(b, "100644 a0c");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting6() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "40000 a");
    # 	entry(b, "100644 apple");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting7() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "40000 an orang");
    # 	entry(b, "40000 an orange");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testValidTreeSorting8() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a");
    # 	entry(b, "100644 a0c");
    # 	entry(b, "100644 b");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testAcceptTreeModeWithZero() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "040000 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.setAllowLeadingZeroFileMode(true);
    # 	checker.checkTree(data);
    #
    # 	checker.setAllowLeadingZeroFileMode(false);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    #
    # 	checker.setIgnore(ZERO_PADDED_FILEMODE, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeModeStartsWithZero1() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "0 a");
    # 	assertCorrupt("mode starts with '0'", OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeModeStartsWithZero2() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "0100644 a");
    # 	assertCorrupt("mode starts with '0'", OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeModeStartsWithZero3() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "040000 a");
    # 	assertCorrupt("mode starts with '0'", OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeModeNotOctal1() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "8 a");
    # 	assertCorrupt("invalid mode character", OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeModeNotOctal2() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "Z a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid mode character", OBJ_TREE, data);
    # 	assertSkipListRejects("invalid mode character", OBJ_TREE, data);
    # }
    #
    # @Test
    # public void testInvalidTreeModeNotSupportedMode1() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "1 a");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid mode 1", OBJ_TREE, data);
    # 	assertSkipListRejects("invalid mode 1", OBJ_TREE, data);
    # }
    #
    # @Test
    # public void testInvalidTreeModeNotSupportedMode2() {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "170000 a");
    # 	assertCorrupt("invalid mode " + 0170000, OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeModeMissingName() {
    # 	StringBuilder b = new StringBuilder();
    # 	b.append("100644");
    # 	assertCorrupt("truncated in mode", OBJ_TREE, b);
    # }
    #
    # @Test
    # public void testInvalidTreeNameContainsSlash()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 a/b");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("name contains '/'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(FULL_PATHNAME, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsEmpty() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 ");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("zero length name", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(EMPTY_NAME, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDot() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotDot() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 ..");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '..'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTDOT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsGit() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.git'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsMixedCaseGit()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .GiT");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.GiT'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsMacHFSGit() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gi\u200Ct");
    # 	byte[] data = encode(b.toString());
    #
    # 	// Fine on POSIX.
    # 	checker.checkTree(data);
    #
    # 	// Rejected on Mac OS.
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt(
    # 			"invalid name '.gi\u200Ct' contains ignorable Unicode characters",
    # 			OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsMacHFSGit2()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 \u206B.git");
    # 	byte[] data = encode(b.toString());
    #
    # 	// Fine on POSIX.
    # 	checker.checkTree(data);
    #
    # 	// Rejected on Mac OS.
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt(
    # 			"invalid name '\u206B.git' contains ignorable Unicode characters",
    # 			OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsMacHFSGit3()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git\uFEFF");
    # 	byte[] data = encode(b.toString());
    #
    # 	// Fine on POSIX.
    # 	checker.checkTree(data);
    #
    # 	// Rejected on Mac OS.
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt(
    # 			"invalid name '.git\uFEFF' contains ignorable Unicode characters",
    # 			OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    #
    #
    # @Test
    # public void testInvalidTreeNameIsMacHFSGitCorruptUTF8AtEnd()
    # 		throws CorruptObjectException {
    # 	byte[] data = concat(encode("100644 .git"),
    # 			new byte[] { (byte) 0xef });
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "");
    # 	data = concat(data, encode(b.toString()));
    #
    # 	// Fine on POSIX.
    # 	checker.checkTree(data);
    #
    # 	// Rejected on Mac OS.
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt(
    # 			"invalid name contains byte sequence '0xef' which is not a valid UTF-8 character",
    # 			OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsMacHFSGitCorruptUTF8AtEnd2()
    # 		throws CorruptObjectException {
    # 	byte[] data = concat(encode("100644 .git"),
    # 			new byte[] {
    # 			(byte) 0xe2, (byte) 0xab });
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "");
    # 	data = concat(data, encode(b.toString()));
    #
    # 	// Fine on POSIX.
    # 	checker.checkTree(data);
    #
    # 	// Rejected on Mac OS.
    # 	checker.setSafeForMacOS(true);
    # 	assertCorrupt(
    # 			"invalid name contains byte sequence '0xe2ab' which is not a valid UTF-8 character",
    # 			OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsNotMacHFSGit()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git\u200Cx");
    # 	byte[] data = encode(b.toString());
    # 	checker.setSafeForMacOS(true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsNotMacHFSGit2()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .kit\u200C");
    # 	byte[] data = encode(b.toString());
    # 	checker.setSafeForMacOS(true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsNotMacHFSGitOtherPlatform()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git\u200C");
    # 	byte[] data = encode(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitDot() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git.");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.git.'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testValidTreeNameIsDotGitDotDot()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git..");
    # 	checker.checkTree(encodeASCII(b.toString()));
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSpace()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git ");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.git '", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSomething()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gitfoobar");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSomethingSpaceSomething()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gitfoo bar");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSomethingDot()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gitfoobar.");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSomethingDotDot()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .gitfoobar..");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitDotSpace()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git. ");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.git. '", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsDotGitSpaceDot()
    # 		throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 .git . ");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name '.git . '", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsGITTilde1() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 GIT~1");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name 'GIT~1'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeNameIsGiTTilde1() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 GiT~1");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("invalid name 'GiT~1'", OBJ_TREE, data);
    # 	assertSkipListAccepts(OBJ_TREE, data);
    # 	checker.setIgnore(HAS_DOTGIT, true);
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testValidTreeNameIsGitTilde11() throws CorruptObjectException {
    # 	StringBuilder b = new StringBuilder();
    # 	entry(b, "100644 GIT~11");
    # 	byte[] data = encodeASCII(b.toString());
    # 	checker.checkTree(data);
    # }
    #
    # @Test
    # public void testInvalidTreeTruncatedInName() {
    # 	StringBuilder b = new StringBuilder();
    # 	b.append("100644 b");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("truncated in name", OBJ_TREE, data);
    # 	assertSkipListRejects("truncated in name", OBJ_TREE, data);
    # }
    #
    # @Test
    # public void testInvalidTreeTruncatedInObjectId() {
    # 	StringBuilder b = new StringBuilder();
    # 	b.append("100644 b\0\1\2");
    # 	byte[] data = encodeASCII(b.toString());
    # 	assertCorrupt("truncated in object id", OBJ_TREE, data);
    # 	assertSkipListRejects("truncated in object id", OBJ_TREE, data);
    # }
    #
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
  #
  # private void checkOneName(String name) throws CorruptObjectException {
  # 	StringBuilder b = new StringBuilder();
  # 	entry(b, "100644 " + name);
  # 	checker.checkTree(encodeASCII(b.toString()));
  # }

  @placeholder_object_id 0..19 |> Enum.to_list()

  defp entry(mode_name), do: '#{mode_name}\0#{@placeholder_object_id}'

  defp assert_corrupt(msg, type, data)
       when is_binary(msg) and is_integer(type) and is_list(data) do
    assert_raise CorruptObjectError, "Object (unknown) is corrupt: #{msg}", fn ->
      ObjectChecker.check!(%ObjectChecker{}, type, data)
    end
  end

  defp assert_skiplist_accepts(type, data) do
    id = ObjectId.id_for(type, data)
    skiplist = MapSet.new([id])
    checker = %ObjectChecker{skiplist: skiplist}
    assert :ok = ObjectChecker.check!(checker, type, data)
  end

  # private void assertSkipListRejects(String msg, int type, byte[] data) {
  # 	ObjectId id = idFor(type, data);
  # 	checker.setSkipList(set(id));
  # 	try {
  # 		checker.check(id, type, data);
  # 		fail("Did not throw CorruptObjectException");
  # 	} catch (CorruptObjectException e) {
  # 		assertEquals(msg, e.getMessage());
  # 	}
  # 	checker.setSkipList(null);
  # }
  #
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
