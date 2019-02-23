defmodule Xgit.Lib.ConfigTest do
  use ExUnit.Case

  alias Xgit.Errors.ConfigInvalidError
  alias Xgit.Lib.Config

  doctest Xgit.Lib.Config

  # A non-ASCII whitespace character: U+2002 EN QUAD.
  @ws "\u2002"

  # private static final String REFS_ORIGIN = "+refs/heads/*:refs/remotes/origin/*";
  #
  # private static final String REFS_UPSTREAM = "+refs/heads/*:refs/remotes/upstream/*";
  #
  # private static final String REFS_BACKUP = "+refs/heads/*:refs/remotes/backup/*";
  #
  # @Rule
  # public ExpectedException expectedEx = ExpectedException.none();
  #
  # @Rule
  # public TemporaryFolder tmp = new TemporaryFolder();
  #
  # @After
  # public void tearDown() {
  # 	SystemReader.setInstance(null);
  # }

  test "read bare key" do
    c = parse("[foo]\nbar\n")
    assert Config.get_boolean(c, "foo", "bar", false) == true
    assert Config.get_string(c, "foo", "bar") == ""
  end

  test "read with subsection" do
    c = parse("[foo \"zip\"]\nbar\n[foo \"zap\"]\nbar=false\nn=3\n")
    assert Config.get_boolean(c, "foo", "zip", "bar", false) == true
    assert Config.get_string(c, "foo", "zip", "bar") == ""
    assert Config.get_boolean(c, "foo", "zap", "bar", true) == false
    assert Config.get_string(c, "foo", "zap", "bar") == "false"
    assert Config.get_int(c, "foo", "zap", "n", 4) == 3
    assert Config.get_int(c, "foo", "zap", "m", 4) == 4
  end

  test "put remote" do
    c =
      Config.new()
      |> Config.set_string("sec", "ext", "name", "value")
      |> Config.set_string("sec", "ext", "name2", "value2")

    assert Config.to_text(c) == "[sec \"ext\"]\n\tname = value\n\tname2 = value2\n"
  end

  test "put+get simple" do
    c =
      Config.new()
      |> Config.set_string("my", "somename", "false")

    assert Config.get_string(c, "my", "somename") == "false"
    assert Config.to_text(c) == "[my]\n\tsomename = false\n"
  end

  test "put+get replacing existing values" do
    c =
      "[my]\nsomename = sam"
      |> parse()
      |> Config.set_string("my", "somename", "fred")

    assert Config.get_string(c, "my", "somename") == "fred"
    assert Config.to_text(c) == "[my]\n\tsomename = fred\n"
  end

  test "put+get string list" do
    c =
      Config.new()
      |> Config.set_string_list("my", "somename", ["value1", "value2"])

    assert Config.get_string_list(c, "my", "somename") == ["value1", "value2"]
    assert Config.to_text(c) == "[my]\n\tsomename = value1\n\tsomename = value2\n"
  end

  test "section and key names are case-insensitive" do
    c = parse("[Foo]\nBar\n")

    assert Config.get_boolean(c, "foo", "bar", false) == true
    assert Config.get_string(c, "foo", "bar") == ""
  end

  test "raises error if key name is invalid" do
    assert_raise ConfigInvalidError, fn ->
      parse("[Foo]\nbar%=42\n")
    end
  end

  test "raises error if kev/value delimiter is invalid" do
    assert_raise ConfigInvalidError, fn ->
      parse("[Foo]\nbar > 42\n")
    end
  end

  test "value can span multiple lines with \\ escaping" do
    c = parse("[Foo]\nBar=abc\\\ndef\n")

    assert Config.get_boolean(c, "foo", "bar", false) == true
    assert Config.get_string(c, "foo", "bar") == "abcdef"
  end

  # @Test
  # public void test007_readUserConfig() {
  # 	final MockSystemReader mockSystemReader = new MockSystemReader();
  # 	SystemReader.setInstance(mockSystemReader);
  # 	final String hostname = mockSystemReader.getHostname();
  # 	final Config userGitConfig = mockSystemReader.openUserConfig(null,
  # 			FS.DETECTED);
  # 	final Config localConfig = new Config(userGitConfig);
  # 	mockSystemReader.clearProperties();
  #
  # 	String authorName;
  # 	String authorEmail;
  #
  # 	// no values defined nowhere
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 	assertEquals(Constants.UNKNOWN_USER_DEFAULT, authorName);
  # 	assertEquals(Constants.UNKNOWN_USER_DEFAULT + "@" + hostname, authorEmail);
  # 	assertTrue(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  # 	assertTrue(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  #
  # 	// the system user name is defined
  # 	mockSystemReader.setProperty(Constants.OS_USER_NAME_KEY, "os user name");
  # 	localConfig.uncache(UserConfig.KEY);
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	assertEquals("os user name", authorName);
  # 	assertTrue(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  #
  # 	if (hostname != null && hostname.length() != 0) {
  # 		authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 		assertEquals("os user name@" + hostname, authorEmail);
  # 	}
  # 	assertTrue(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  #
  # 	// the git environment variables are defined
  # 	mockSystemReader.setProperty(Constants.GIT_AUTHOR_NAME_KEY, "git author name");
  # 	mockSystemReader.setProperty(Constants.GIT_AUTHOR_EMAIL_KEY, "author@email");
  # 	localConfig.uncache(UserConfig.KEY);
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 	assertEquals("git author name", authorName);
  # 	assertEquals("author@email", authorEmail);
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  #
  # 	// the values are defined in the global configuration
  # 	// first clear environment variables since they would override
  # 	// configuration files
  # 	mockSystemReader.clearProperties();
  # 	userGitConfig.setString("user", null, "name", "global username");
  # 	userGitConfig.setString("user", null, "email", "author@globalemail");
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 	assertEquals("global username", authorName);
  # 	assertEquals("author@globalemail", authorEmail);
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  #
  # 	// the values are defined in the local configuration
  # 	localConfig.setString("user", null, "name", "local username");
  # 	localConfig.setString("user", null, "email", "author@localemail");
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 	assertEquals("local username", authorName);
  # 	assertEquals("author@localemail", authorEmail);
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  #
  # 	authorName = localConfig.get(UserConfig.KEY).getCommitterName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getCommitterEmail();
  # 	assertEquals("local username", authorName);
  # 	assertEquals("author@localemail", authorEmail);
  # 	assertFalse(localConfig.get(UserConfig.KEY).isCommitterNameImplicit());
  # 	assertFalse(localConfig.get(UserConfig.KEY).isCommitterEmailImplicit());
  #
  # 	// also git environment variables are defined
  # 	mockSystemReader.setProperty(Constants.GIT_AUTHOR_NAME_KEY,
  # 			"git author name");
  # 	mockSystemReader.setProperty(Constants.GIT_AUTHOR_EMAIL_KEY,
  # 			"author@email");
  # 	localConfig.setString("user", null, "name", "local username");
  # 	localConfig.setString("user", null, "email", "author@localemail");
  # 	authorName = localConfig.get(UserConfig.KEY).getAuthorName();
  # 	authorEmail = localConfig.get(UserConfig.KEY).getAuthorEmail();
  # 	assertEquals("git author name", authorName);
  # 	assertEquals("author@email", authorEmail);
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorNameImplicit());
  # 	assertFalse(localConfig.get(UserConfig.KEY).isAuthorEmailImplicit());
  # }
  #
  # @Test
  # public void testReadUserConfigWithInvalidCharactersStripped() {
  # 	final MockSystemReader mockSystemReader = new MockSystemReader();
  # 	final Config localConfig = new Config(mockSystemReader.openUserConfig(
  # 			null, FS.DETECTED));
  #
  # 	localConfig.setString("user", null, "name", "foo<bar");
  # 	localConfig.setString("user", null, "email", "baz>\nqux@example.com");
  #
  # 	UserConfig userConfig = localConfig.get(UserConfig.KEY);
  # 	assertEquals("foobar", userConfig.getAuthorName());
  # 	assertEquals("bazqux@example.com", userConfig.getAuthorEmail());
  # }

  describe "read boolean" do
    test "from lowercase true/false values" do
      c = parse("[s]\na = true\nb = false\n")

      assert Config.get_string(c, "s", "a") == "true"
      assert Config.get_string(c, "s", "b") == "false"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end

    test "from mix-case true/false values" do
      c = parse("[s]\na = TrUe\nb = fAlSe\n")

      assert Config.get_string(c, "s", "a") == "TrUe"
      assert Config.get_string(c, "s", "b") == "fAlSe"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end

    test "from lowercase yes/no values" do
      c = parse("[s]\na = yes\nb = no\n")

      assert Config.get_string(c, "s", "a") == "yes"
      assert Config.get_string(c, "s", "b") == "no"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end

    test "from mixed-case yes/no values" do
      c = parse("[s]\na = yEs\nb = NO\n")

      assert Config.get_string(c, "s", "a") == "yEs"
      assert Config.get_string(c, "s", "b") == "NO"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end

    test "from lowercase on/off values" do
      c = parse("[s]\na = on\nb = off\n")

      assert Config.get_string(c, "s", "a") == "on"
      assert Config.get_string(c, "s", "b") == "off"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end

    test "from uppercase on/off values" do
      c = parse("[s]\na = ON\nb = OFF\n")

      assert Config.get_string(c, "s", "a") == "ON"
      assert Config.get_string(c, "s", "b") == "OFF"

      assert Config.get_boolean(c, "s", "a", false) == true
      assert Config.get_boolean(c, "s", "b", true) == false
    end
  end

  # static enum TestEnum {
  # 	ONE_TWO;
  # }
  #
  # @Test
  # public void testGetEnum() throws ConfigInvalidException {
  # 	Config c = parse("[s]\na = ON\nb = input\nc = true\nd = off\n");
  # 	assertSame(CoreConfig.AutoCRLF.TRUE, c.getEnum("s", null, "a",
  # 			CoreConfig.AutoCRLF.FALSE));
  #
  # 	assertSame(CoreConfig.AutoCRLF.INPUT, c.getEnum("s", null, "b",
  # 			CoreConfig.AutoCRLF.FALSE));
  #
  # 	assertSame(CoreConfig.AutoCRLF.TRUE, c.getEnum("s", null, "c",
  # 			CoreConfig.AutoCRLF.FALSE));
  #
  # 	assertSame(CoreConfig.AutoCRLF.FALSE, c.getEnum("s", null, "d",
  # 			CoreConfig.AutoCRLF.TRUE));
  #
  # 	c = new Config();
  # 	assertSame(CoreConfig.AutoCRLF.FALSE, c.getEnum("s", null, "d",
  # 			CoreConfig.AutoCRLF.FALSE));
  #
  # 	c = parse("[s \"b\"]\n\tc = one two\n");
  # 	assertSame(TestEnum.ONE_TWO, c.getEnum("s", "b", "c", TestEnum.ONE_TWO));
  #
  # 	c = parse("[s \"b\"]\n\tc = one-two\n");
  # 	assertSame(TestEnum.ONE_TWO, c.getEnum("s", "b", "c", TestEnum.ONE_TWO));
  # }
  #
  # @Test
  # public void testGetInvalidEnum() throws ConfigInvalidException {
  # 	Config c = parse("[a]\n\tb = invalid\n");
  # 	try {
  # 		c.getEnum("a", null, "b", TestEnum.ONE_TWO);
  # 		fail();
  # 	} catch (IllegalArgumentException e) {
  # 		assertEquals("Invalid value: a.b=invalid", e.getMessage());
  # 	}
  #
  # 	c = parse("[a \"b\"]\n\tc = invalid\n");
  # 	try {
  # 		c.getEnum("a", "b", "c", TestEnum.ONE_TWO);
  # 		fail();
  # 	} catch (IllegalArgumentException e) {
  # 		assertEquals("Invalid value: a.b.c=invalid", e.getMessage());
  # 	}
  # }
  #
  # @Test
  # public void testSetEnum() {
  # 	final Config c = new Config();
  # 	c.setEnum("s", "b", "c", TestEnum.ONE_TWO);
  # 	assertEquals("[s \"b\"]\n\tc = one two\n", c.toText());
  # }
  #
  # @Test
  # public void testGetFastForwardMergeoptions() throws ConfigInvalidException {
  # 	Config c = new Config(null); // not set
  # 	assertSame(FastForwardMode.FF, c.getEnum(
  # 			ConfigConstants.CONFIG_BRANCH_SECTION, "side",
  # 			ConfigConstants.CONFIG_KEY_MERGEOPTIONS, FastForwardMode.FF));
  # 	MergeConfig mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF, mergeConfig.getFastForwardMode());
  # 	c = parse("[branch \"side\"]\n\tmergeoptions = --ff-only\n");
  # 	assertSame(FastForwardMode.FF_ONLY, c.getEnum(
  # 			ConfigConstants.CONFIG_BRANCH_SECTION, "side",
  # 			ConfigConstants.CONFIG_KEY_MERGEOPTIONS,
  # 			FastForwardMode.FF_ONLY));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF_ONLY, mergeConfig.getFastForwardMode());
  # 	c = parse("[branch \"side\"]\n\tmergeoptions = --ff\n");
  # 	assertSame(FastForwardMode.FF, c.getEnum(
  # 			ConfigConstants.CONFIG_BRANCH_SECTION, "side",
  # 			ConfigConstants.CONFIG_KEY_MERGEOPTIONS, FastForwardMode.FF));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF, mergeConfig.getFastForwardMode());
  # 	c = parse("[branch \"side\"]\n\tmergeoptions = --no-ff\n");
  # 	assertSame(FastForwardMode.NO_FF, c.getEnum(
  # 			ConfigConstants.CONFIG_BRANCH_SECTION, "side",
  # 			ConfigConstants.CONFIG_KEY_MERGEOPTIONS, FastForwardMode.NO_FF));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.NO_FF, mergeConfig.getFastForwardMode());
  # }
  #
  # @Test
  # public void testSetFastForwardMergeoptions() {
  # 	final Config c = new Config();
  # 	c.setEnum("branch", "side", "mergeoptions", FastForwardMode.FF);
  # 	assertEquals("[branch \"side\"]\n\tmergeoptions = --ff\n", c.toText());
  # 	c.setEnum("branch", "side", "mergeoptions", FastForwardMode.FF_ONLY);
  # 	assertEquals("[branch \"side\"]\n\tmergeoptions = --ff-only\n",
  # 			c.toText());
  # 	c.setEnum("branch", "side", "mergeoptions", FastForwardMode.NO_FF);
  # 	assertEquals("[branch \"side\"]\n\tmergeoptions = --no-ff\n",
  # 			c.toText());
  # }
  #
  # @Test
  # public void testGetFastForwardMerge() throws ConfigInvalidException {
  # 	Config c = new Config(null); // not set
  # 	assertSame(FastForwardMode.Merge.TRUE, c.getEnum(
  # 			ConfigConstants.CONFIG_KEY_MERGE, null,
  # 			ConfigConstants.CONFIG_KEY_FF, FastForwardMode.Merge.TRUE));
  # 	MergeConfig mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF, mergeConfig.getFastForwardMode());
  # 	c = parse("[merge]\n\tff = only\n");
  # 	assertSame(FastForwardMode.Merge.ONLY, c.getEnum(
  # 			ConfigConstants.CONFIG_KEY_MERGE, null,
  # 			ConfigConstants.CONFIG_KEY_FF, FastForwardMode.Merge.ONLY));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF_ONLY, mergeConfig.getFastForwardMode());
  # 	c = parse("[merge]\n\tff = true\n");
  # 	assertSame(FastForwardMode.Merge.TRUE, c.getEnum(
  # 			ConfigConstants.CONFIG_KEY_MERGE, null,
  # 			ConfigConstants.CONFIG_KEY_FF, FastForwardMode.Merge.TRUE));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF, mergeConfig.getFastForwardMode());
  # 	c = parse("[merge]\n\tff = false\n");
  # 	assertSame(FastForwardMode.Merge.FALSE, c.getEnum(
  # 			ConfigConstants.CONFIG_KEY_MERGE, null,
  # 			ConfigConstants.CONFIG_KEY_FF, FastForwardMode.Merge.FALSE));
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.NO_FF, mergeConfig.getFastForwardMode());
  # }
  #
  # @Test
  # public void testCombinedMergeOptions() throws ConfigInvalidException {
  # 	Config c = new Config(null); // not set
  # 	MergeConfig mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF, mergeConfig.getFastForwardMode());
  # 	assertTrue(mergeConfig.isCommit());
  # 	assertFalse(mergeConfig.isSquash());
  # 	// branch..mergeoptions should win over merge.ff
  # 	c = parse("[merge]\n\tff = false\n"
  # 			+ "[branch \"side\"]\n\tmergeoptions = --ff-only\n");
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF_ONLY, mergeConfig.getFastForwardMode());
  # 	assertTrue(mergeConfig.isCommit());
  # 	assertFalse(mergeConfig.isSquash());
  # 	// merge.ff used for ff setting if not set via mergeoptions
  # 	c = parse("[merge]\n\tff = only\n"
  # 			+ "[branch \"side\"]\n\tmergeoptions = --squash\n");
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF_ONLY, mergeConfig.getFastForwardMode());
  # 	assertTrue(mergeConfig.isCommit());
  # 	assertTrue(mergeConfig.isSquash());
  # 	// mergeoptions wins if it has ff options amongst other options
  # 	c = parse("[merge]\n\tff = false\n"
  # 			+ "[branch \"side\"]\n\tmergeoptions = --ff-only --no-commit\n");
  # 	mergeConfig = c.get(MergeConfig.getParser("side"));
  # 	assertSame(FastForwardMode.FF_ONLY, mergeConfig.getFastForwardMode());
  # 	assertFalse(mergeConfig.isCommit());
  # 	assertFalse(mergeConfig.isSquash());
  # }
  #
  # @Test
  # public void testSetFastForwardMerge() {
  # 	final Config c = new Config();
  # 	c.setEnum("merge", null, "ff",
  # 			FastForwardMode.Merge.valueOf(FastForwardMode.FF));
  # 	assertEquals("[merge]\n\tff = true\n", c.toText());
  # 	c.setEnum("merge", null, "ff",
  # 			FastForwardMode.Merge.valueOf(FastForwardMode.FF_ONLY));
  # 	assertEquals("[merge]\n\tff = only\n", c.toText());
  # 	c.setEnum("merge", null, "ff",
  # 			FastForwardMode.Merge.valueOf(FastForwardMode.NO_FF));
  # 	assertEquals("[merge]\n\tff = false\n", c.toText());
  # }

  test "read integer with g/m/k notation" do
    assert_read_integer(1)
    assert_read_integer(-1)

    assert_read_integer(-9_223_372_036_854_775_808)
    assert_read_integer(9_223_372_036_854_775_807)

    assert_read_integer(4 * 1024 * 1024 * 1024, "4g")
    assert_read_integer(3 * 1024 * 1024, "3 m")
    assert_read_integer(8 * 1024, "8 k")

    assert_raise ConfigInvalidError, fn -> assert_read_integer(-1, "1.5g") end
  end

  test "read boolean with no value" do
    c = parse("[my]\n\tempty\n")

    assert Config.get_string(c, "my", "empty") == ""
    assert Config.get_string_list(c, "my", "empty") == [""]
    assert Config.get_boolean(c, "my", "empty", false) == true

    assert Config.to_text(c) == "[my]\n\tempty\n"
  end

  describe "unset_section/3" do
    test "branch section" do
      c =
        parse("""
        [branch "keep"]
          merge = master.branch.to.keep.in.the.file

        [branch "remove"]
          merge = this.will.get.deleted
          remote = origin-for-some-long-gone-place

        [core-section-not-to-remove-in-test]
          packedGitLimit = 14
        """)
        |> Config.unset_section("branch", "does.not.exist")
        |> Config.unset_section("branch", "remove")

      assert Config.to_text(c) ==
               "[branch \"keep\"]\n" <>
                 "  merge = master.branch.to.keep.in.the.file\n" <>
                 "\n" <>
                 "[core-section-not-to-remove-in-test]\n" <>
                 "  packedGitLimit = 14\n"
    end

    test "single section" do
      c =
        parse("""
        [branch "keep"]
          merge = master.branch.to.keep.in.the.file

        [single]
          merge = this.will.get.deleted
          remote = origin-for-some-long-gone-place

        [core-section-not-to-remove-in-test]
          packedGitLimit = 14
        """)
        |> Config.unset_section("single")

      assert Config.to_text(c) ==
               "[branch \"keep\"]\n" <>
                 "  merge = master.branch.to.keep.in.the.file\n" <>
                 "\n" <>
                 "[core-section-not-to-remove-in-test]\n" <>
                 "  packedGitLimit = 14\n"
    end
  end

  test "sections/1" do
    c = parse("[a]\n [B]\n")
    assert Config.sections(c) == ["a", "b"]
  end

  test "names_in_section/2" do
    c =
      parse("""
      [core]
      repositoryFormatVersion = 0
      filemode = false
      logAllRefUpdates = true
      """)

    assert Config.names_in_section(c, "core") == [
             "repositoryformatversion",
             "filemode",
             "logallrefupdates"
           ]
  end

  # @Test
  # public void test_ReadNamesInSectionRecursive()
  # 		throws ConfigInvalidException {
  # 	String baseConfigString = "[core]\n" + "logAllRefUpdates = true\n";
  # 	String configString = "[core]\n" + "repositoryFormatVersion = 0\n"
  # 			+ "filemode = false\n";
  # 	final Config c = parse(configString, parse(baseConfigString));
  # 	Set<String> names = c.getNames("core", true);
  # 	assertEquals("Core section size", 3, names.size());
  # 	assertTrue("Core section should contain \"filemode\"",
  # 			names.contains("filemode"));
  # 	assertTrue("Core section should contain \"repositoryFormatVersion\"",
  # 			names.contains("repositoryFormatVersion"));
  # 	assertTrue("Core section should contain \"logAllRefUpdates\"",
  # 			names.contains("logAllRefUpdates"));
  # 	assertTrue("Core section should contain \"logallrefupdates\"",
  # 			names.contains("logallrefupdates"));
  #
  # 	Iterator<String> itr = names.iterator();
  # 	assertEquals("filemode", itr.next());
  # 	assertEquals("repositoryFormatVersion", itr.next());
  # 	assertEquals("logAllRefUpdates", itr.next());
  # 	assertFalse(itr.hasNext());
  # }

  test "names_in_subsection/3" do
    c =
      parse("""
      [a "sub1"]
      x = 0
      y = false
      z = true
      [a "sub2"]
      a=0
      b=1
      """)

    assert Config.names_in_subsection(c, "a", "sub1") == ["x", "y", "z"]
    assert Config.names_in_subsection(c, "a", "sub2") == ["a", "b"]
  end

  # @Test
  # public void readNamesInSubSectionRecursive() throws ConfigInvalidException {
  # 	String baseConfigString = "[a \"sub1\"]\n"//
  # 			+ "x = 0\n" //
  # 			+ "y = false\n"//
  # 			+ "[a \"sub2\"]\n"//
  # 			+ "A=0\n";//
  # 	String configString = "[a \"sub1\"]\n"//
  # 			+ "z = true\n"//
  # 			+ "[a \"sub2\"]\n"//
  # 			+ "B=1\n";
  # 	final Config c = parse(configString, parse(baseConfigString));
  # 	Set<String> names = c.getNames("a", "sub1", true);
  # 	assertEquals("Subsection size", 3, names.size());
  # 	assertTrue("Subsection should contain \"x\"", names.contains("x"));
  # 	assertTrue("Subsection should contain \"y\"", names.contains("y"));
  # 	assertTrue("Subsection should contain \"z\"", names.contains("z"));
  # 	names = c.getNames("a", "sub2", true);
  # 	assertEquals("Subsection size", 2, names.size());
  # 	assertTrue("Subsection should contain \"A\"", names.contains("A"));
  # 	assertTrue("Subsection should contain \"a\"", names.contains("a"));
  # 	assertTrue("Subsection should contain \"B\"", names.contains("B"));
  # }

  test "no final newline" do
    c = parse("[a]\nx = 0\ny = 1")

    assert Config.get_string(c, "a", "x") == "0"
    assert Config.get_string(c, "a", "y") == "1"
  end

  test "explicitly set empty string" do
    c =
      Config.new()
      |> Config.set_string("a", "x", "0")
      |> Config.set_string("a", "y", "")

    assert Config.get_string(c, "a", "x") == "0"
    assert Config.get_int(c, "a", "x", 1) == 0

    assert Config.get_string(c, "a", "y") == ""
    assert Config.get_string_list(c, "a", "y") == [""]
    assert Config.get_int(c, "a", "y", 1) == 1

    assert Config.get_string(c, "a", "z") == nil
    assert Config.get_string_list(c, "a", "z") == []
  end

  test "parsed empty string" do
    c = parse("[a]\nx = 0\ny =\nmissing\n")

    assert Config.get_string(c, "a", "x") == "0"
    assert Config.get_int(c, "a", "x", 1) == 0

    assert Config.get_string(c, "a", "y") == nil
    assert Config.get_string_list(c, "a", "y") == [nil]
    assert Config.get_int(c, "a", "y", 1) == 1

    assert Config.get_string(c, "a", "z") == nil
    assert Config.get_string_list(c, "a", "z") == []

    assert Config.get_string(c, "a", "missing") == ""
    assert Config.get_string_list(c, "a", "missing") == [""]
    assert Config.get_int(c, "a", "y", 2) == 2
  end

  test "get_int with invalid value" do
    c = parse("[a]\nx = abc\n")
    assert_raise ConfigInvalidError, fn -> Config.get_int(c, "a", "x", 44) end
  end

  test "get_int with empty value" do
    c = parse("[a]\nx")
    assert Config.get_int(c, "a", "x", 4) == 4
  end

  test "get/set_string_list with empty value" do
    c =
      Config.new()
      |> Config.set_string_list("a", "x", [""])

    assert Config.get_string_list(c, "a", "x") == [""]
  end

  test "empty value at EOF" do
    c = parse("[a]\nx =")
    assert Config.get_string(c, "a", "x") == nil
    assert Config.get_string_list(c, "a", "x") == [nil]

    c = parse("[a]\nx =\n")
    assert Config.get_string(c, "a", "x") == nil
    assert Config.get_string_list(c, "a", "x") == [nil]
  end

  test "read multiple values for name" do
    c = parse("[foo]\nbar=false\nbar=true\n")
    assert Config.get_boolean(c, "foo", "bar", false) == true
  end

  test "get_boolean with missing value" do
    c = parse("[a]\nx\n")
    assert Config.get_boolean(c, "a", "x", false) == true
  end

  # @Test
  # public void testIncludeInvalidName() throws ConfigInvalidException {
  # 	expectedEx.expect(ConfigInvalidException.class);
  # 	expectedEx.expectMessage(JGitText.get().invalidLineInConfigFile);
  # 	parse("[include]\nbar\n");
  # }
  #
  # @Test
  # public void testIncludeNoValue() throws ConfigInvalidException {
  # 	expectedEx.expect(ConfigInvalidException.class);
  # 	expectedEx.expectMessage(JGitText.get().invalidLineInConfigFile);
  # 	parse("[include]\npath\n");
  # }
  #
  # @Test
  # public void testIncludeEmptyValue() throws ConfigInvalidException {
  # 	expectedEx.expect(ConfigInvalidException.class);
  # 	expectedEx.expectMessage(JGitText.get().invalidLineInConfigFile);
  # 	parse("[include]\npath=\n");
  # }
  #
  # @Test
  # public void testIncludeValuePathNotFound() throws ConfigInvalidException {
  # 	// we do not expect an exception, included path not found are ignored
  # 	String notFound = "/not/found";
  # 	Config parsed = parse("[include]\npath=" + notFound + "\n");
  # 	assertEquals(1, parsed.getSections().size());
  # 	assertEquals(notFound, parsed.getString("include", null, "path"));
  # }
  #
  # @Test
  # public void testIncludeValuePathWithTilde() throws ConfigInvalidException {
  # 	// we do not expect an exception, included path not supported are
  # 	// ignored
  # 	String notSupported = "~/someFile";
  # 	Config parsed = parse("[include]\npath=" + notSupported + "\n");
  # 	assertEquals(1, parsed.getSections().size());
  # 	assertEquals(notSupported, parsed.getString("include", null, "path"));
  # }
  #
  # @Test
  # public void testIncludeValuePathRelative() throws ConfigInvalidException {
  # 	// we do not expect an exception, included path not supported are
  # 	// ignored
  # 	String notSupported = "someRelativeFile";
  # 	Config parsed = parse("[include]\npath=" + notSupported + "\n");
  # 	assertEquals(1, parsed.getSections().size());
  # 	assertEquals(notSupported, parsed.getString("include", null, "path"));
  # }
  #
  # @Test
  # public void testIncludeTooManyRecursions() throws IOException {
  # 	File config = tmp.newFile("config");
  # 	String include = "[include]\npath=" + pathToString(config) + "\n";
  # 	Files.write(config.toPath(), include.getBytes(UTF_8));
  # 	try {
  # 		loadConfig(config);
  # 		fail();
  # 	} catch (ConfigInvalidException cie) {
  # 		for (Throwable t = cie; t != null; t = t.getCause()) {
  # 			if (t.getMessage()
  # 					.equals(JGitText.get().tooManyIncludeRecursions)) {
  # 				return;
  # 			}
  # 		}
  # 		fail("Expected to find expected exception message: "
  # 				+ JGitText.get().tooManyIncludeRecursions);
  # 	}
  # }
  #
  # @Test
  # public void testIncludeIsNoop() throws IOException, ConfigInvalidException {
  # 	File config = tmp.newFile("config");
  #
  # 	String fooBar = "[foo]\nbar=true\n";
  # 	Files.write(config.toPath(), fooBar.getBytes(UTF_8));
  #
  # 	Config parsed = parse("[include]\npath=" + pathToString(config) + "\n");
  # 	assertFalse(parsed.getBoolean("foo", "bar", false));
  # }
  #
  # @Test
  # public void testIncludeCaseInsensitiveSection()
  # 		throws IOException, ConfigInvalidException {
  # 	File included = tmp.newFile("included");
  # 	String content = "[foo]\nbar=true\n";
  # 	Files.write(included.toPath(), content.getBytes(UTF_8));
  #
  # 	File config = tmp.newFile("config");
  # 	content = "[Include]\npath=" + pathToString(included) + "\n";
  # 	Files.write(config.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(config);
  # 	assertTrue(fbConfig.getBoolean("foo", "bar", false));
  # }
  #
  # @Test
  # public void testIncludeCaseInsensitiveKey()
  # 		throws IOException, ConfigInvalidException {
  # 	File included = tmp.newFile("included");
  # 	String content = "[foo]\nbar=true\n";
  # 	Files.write(included.toPath(), content.getBytes(UTF_8));
  #
  # 	File config = tmp.newFile("config");
  # 	content = "[include]\nPath=" + pathToString(included) + "\n";
  # 	Files.write(config.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(config);
  # 	assertTrue(fbConfig.getBoolean("foo", "bar", false));
  # }
  #
  # @Test
  # public void testIncludeExceptionContainsLine() {
  # 	try {
  # 		parse("[include]\npath=\n");
  # 		fail("Expected ConfigInvalidException");
  # 	} catch (ConfigInvalidException e) {
  # 		assertTrue(
  # 				"Expected to find the problem line in the exception message",
  # 				e.getMessage().contains("include.path"));
  # 	}
  # }
  #
  # @Test
  # public void testIncludeExceptionContainsFile() throws IOException {
  # 	File included = tmp.newFile("included");
  # 	String includedPath = pathToString(included);
  # 	String content = "[include]\npath=\n";
  # 	Files.write(included.toPath(), content.getBytes(UTF_8));
  #
  # 	File config = tmp.newFile("config");
  # 	String include = "[include]\npath=" + includedPath + "\n";
  # 	Files.write(config.toPath(), include.getBytes(UTF_8));
  # 	try {
  # 		loadConfig(config);
  # 		fail("Expected ConfigInvalidException");
  # 	} catch (ConfigInvalidException e) {
  # 		// Check that there is some exception in the chain that contains
  # 		// includedPath
  # 		for (Throwable t = e; t != null; t = t.getCause()) {
  # 			if (t.getMessage().contains(includedPath)) {
  # 				return;
  # 			}
  # 		}
  # 		fail("Expected to find the path in the exception message: "
  # 				+ includedPath);
  # 	}
  # }
  #
  # @Test
  # public void testIncludeSetValueMustNotTouchIncludedLines1()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = createAllTypesSampleContent("Alice Parker", false, 11,
  # 			21, 31, CoreConfig.AutoCRLF.FALSE,
  # 			"+refs/heads/*:refs/remotes/origin/*") + "\n[include]\npath="
  # 			+ pathToString(includedFile);
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_ORIGIN, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "user", "core", "remote", "include");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsIncluded(config, REFS_BACKUP, REFS_UPSTREAM);
  # 		assertSections(fbConfig, "user", "core", "remote", "include");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueMustNotTouchIncludedLines2()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[include]\npath=" + pathToString(includedFile) + "\n"
  # 			+ createAllTypesSampleContent("Alice Parker", false, 11, 21, 31,
  # 					CoreConfig.AutoCRLF.FALSE,
  # 					"+refs/heads/*:refs/remotes/origin/*");
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsConfig(fbConfig, REFS_UPSTREAM, REFS_ORIGIN);
  # 	assertSections(fbConfig, "include", "user", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNew(config, REFS_UPSTREAM, REFS_BACKUP);
  # 		assertSections(fbConfig, "include", "user", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueOnFileWithJustContainsInclude()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[include]\npath=" + pathToString(includedFile);
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "include", "user", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNew(config, REFS_UPSTREAM, REFS_BACKUP);
  # 		assertSections(fbConfig, "include", "user", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueOnFileWithJustEmptySection1()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[user]\n[include]\npath="
  # 			+ pathToString(includedFile);
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "user", "include", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNewWithName(config, "Alice Muller", REFS_UPSTREAM,
  # 				REFS_BACKUP);
  # 		assertSections(fbConfig, "user", "include", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueOnFileWithJustEmptySection2()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[include]\npath=" + pathToString(includedFile)
  # 			+ "\n[user]";
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "include", "user", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNew(config, REFS_UPSTREAM, REFS_BACKUP);
  # 		assertSections(fbConfig, "include", "user", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueOnFileWithJustExistingSection1()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[user]\nemail=alice@home\n[include]\npath="
  # 			+ pathToString(includedFile);
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "user", "include", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNewWithName(config, "Alice Muller", REFS_UPSTREAM,
  # 				REFS_BACKUP);
  # 		assertSections(fbConfig, "user", "include", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeSetValueOnFileWithJustExistingSection2()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = createAllTypesIncludedContent();
  #
  # 	File configFile = tmp.newFile("config");
  # 	String content = "[include]\npath=" + pathToString(includedFile)
  # 			+ "\n[user]\nemail=alice@home\n";
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  # 	assertValuesAsIncluded(fbConfig, REFS_UPSTREAM);
  # 	assertSections(fbConfig, "include", "user", "core", "remote");
  #
  # 	setAllValuesNew(fbConfig);
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertValuesAsNew(config, REFS_UPSTREAM, REFS_BACKUP);
  # 		assertSections(fbConfig, "include", "user", "core", "remote");
  # 	});
  # }
  #
  # @Test
  # public void testIncludeUnsetSectionMustNotTouchIncludedLines()
  # 		throws IOException, ConfigInvalidException {
  # 	File includedFile = tmp.newFile("included");
  # 	RefSpec includedRefSpec = new RefSpec(REFS_UPSTREAM);
  # 	String includedContent = "[remote \"origin\"]\n" + "fetch="
  # 			+ includedRefSpec;
  # 	Files.write(includedFile.toPath(), includedContent.getBytes(UTF_8));
  #
  # 	File configFile = tmp.newFile("config");
  # 	RefSpec refSpec = new RefSpec(REFS_ORIGIN);
  # 	String content = "[include]\npath=" + pathToString(includedFile) + "\n"
  # 			+ "[remote \"origin\"]\n" + "fetch=" + refSpec;
  # 	Files.write(configFile.toPath(), content.getBytes(UTF_8));
  #
  # 	FileBasedConfig fbConfig = loadConfig(configFile);
  #
  # 	Consumer<FileBasedConfig> assertion = config -> {
  # 		assertEquals(Arrays.asList(includedRefSpec, refSpec),
  # 				config.getRefSpecs("remote", "origin", "fetch"));
  # 	};
  # 	assertion.accept(fbConfig);
  #
  # 	fbConfig.unsetSection("remote", "origin");
  # 	assertValuesAsIsSaveLoad(fbConfig, config -> {
  # 		assertEquals(Collections.singletonList(includedRefSpec),
  # 				config.getRefSpecs("remote", "origin", "fetch"));
  # 	});
  # }
  #
  # private File createAllTypesIncludedContent() throws IOException {
  # 	File includedFile = tmp.newFile("included");
  # 	String includedContent = createAllTypesSampleContent("Alice Muller",
  # 			true, 10, 20, 30, CoreConfig.AutoCRLF.TRUE,
  # 			"+refs/heads/*:refs/remotes/upstream/*");
  # 	Files.write(includedFile.toPath(), includedContent.getBytes(UTF_8));
  # 	return includedFile;
  # }
  #
  # private static void assertValuesAsIsSaveLoad(FileBasedConfig fbConfig,
  # 		Consumer<FileBasedConfig> assertion)
  # 		throws IOException, ConfigInvalidException {
  # 	assertion.accept(fbConfig);
  #
  # 	fbConfig.save();
  # 	assertion.accept(fbConfig);
  #
  # 	fbConfig = loadConfig(fbConfig.getFile());
  # 	assertion.accept(fbConfig);
  # }
  #
  # private static void setAllValuesNew(Config config) {
  # 	config.setString("user", null, "name", "Alice Bauer");
  # 	config.setBoolean("core", null, "fileMode", false);
  # 	config.setInt("core", null, "deltaBaseCacheLimit", 12);
  # 	config.setLong("core", null, "packedGitLimit", 22);
  # 	config.setLong("core", null, "repositoryCacheExpireAfter", 32);
  # 	config.setEnum("core", null, "autocrlf", CoreConfig.AutoCRLF.FALSE);
  # 	config.setString("remote", "origin", "fetch",
  # 			"+refs/heads/*:refs/remotes/backup/*");
  # }
  #
  # private static void assertValuesAsIncluded(Config config, String... refs) {
  # 	assertAllTypesSampleContent("Alice Muller", true, 10, 20, 30,
  # 			CoreConfig.AutoCRLF.TRUE, config, refs);
  # }
  #
  # private static void assertValuesAsConfig(Config config, String... refs) {
  # 	assertAllTypesSampleContent("Alice Parker", false, 11, 21, 31,
  # 			CoreConfig.AutoCRLF.FALSE, config, refs);
  # }
  #
  # private static void assertValuesAsNew(Config config, String... refs) {
  # 	assertValuesAsNewWithName(config, "Alice Bauer", refs);
  # }
  #
  # private static void assertValuesAsNewWithName(Config config, String name,
  # 		String... refs) {
  # 	assertAllTypesSampleContent(name, false, 12, 22, 32,
  # 			CoreConfig.AutoCRLF.FALSE, config, refs);
  # }
  #
  # private static void assertSections(Config config, String... sections) {
  # 	assertEquals(Arrays.asList(sections),
  # 			new ArrayList<>(config.getSections()));
  # }
  #
  # private static String createAllTypesSampleContent(String name,
  # 		boolean fileMode, int deltaBaseCacheLimit, long packedGitLimit,
  # 		long repositoryCacheExpireAfter, CoreConfig.AutoCRLF autoCRLF,
  # 		String fetchRefSpec) {
  # 	final StringBuilder builder = new StringBuilder();
  # 	builder.append("[user]\n");
  # 	builder.append("name=");
  # 	builder.append(name);
  # 	builder.append("\n");
  #
  # 	builder.append("[core]\n");
  # 	builder.append("fileMode=");
  # 	builder.append(fileMode);
  # 	builder.append("\n");
  #
  # 	builder.append("deltaBaseCacheLimit=");
  # 	builder.append(deltaBaseCacheLimit);
  # 	builder.append("\n");
  #
  # 	builder.append("packedGitLimit=");
  # 	builder.append(packedGitLimit);
  # 	builder.append("\n");
  #
  # 	builder.append("repositoryCacheExpireAfter=");
  # 	builder.append(repositoryCacheExpireAfter);
  # 	builder.append("\n");
  #
  # 	builder.append("autocrlf=");
  # 	builder.append(autoCRLF.name());
  # 	builder.append("\n");
  #
  # 	builder.append("[remote \"origin\"]\n");
  # 	builder.append("fetch=");
  # 	builder.append(fetchRefSpec);
  # 	builder.append("\n");
  # 	return builder.toString();
  # }
  #
  # private static void assertAllTypesSampleContent(String name,
  # 		boolean fileMode, int deltaBaseCacheLimit, long packedGitLimit,
  # 		long repositoryCacheExpireAfter, CoreConfig.AutoCRLF autoCRLF,
  # 		Config config, String... fetchRefSpecs) {
  # 	assertEquals(name, config.getString("user", null, "name"));
  # 	assertEquals(fileMode,
  # 			config.getBoolean("core", "fileMode", !fileMode));
  # 	assertEquals(deltaBaseCacheLimit,
  # 			config.getInt("core", "deltaBaseCacheLimit", -1));
  # 	assertEquals(packedGitLimit,
  # 			config.getLong("core", "packedGitLimit", -1));
  # 	assertEquals(repositoryCacheExpireAfter, config.getTimeUnit("core",
  # 			null, "repositoryCacheExpireAfter", -1, MILLISECONDS));
  # 	assertEquals(autoCRLF, config.getEnum("core", null, "autocrlf",
  # 			CoreConfig.AutoCRLF.INPUT));
  # 	final List<RefSpec> refspecs = new ArrayList<>();
  # 	for (String fetchRefSpec : fetchRefSpecs) {
  # 		refspecs.add(new RefSpec(fetchRefSpec));
  # 	}
  #
  # 	assertEquals(refspecs, config.getRefSpecs("remote", "origin", "fetch"));
  # }

  defp assert_read_integer(n), do: assert_read_integer(n, to_string(n))

  defp assert_read_integer(n, str) do
    c = parse("[s]\na = #{str}\n")
    assert Config.get_int(c, "s", "a", 0) == n
  end

  defp parse(content) do
    Config.new()
    |> Config.from_text(content)
  end

  # private static Config parse(String content, Config baseConfig)
  # 		throws ConfigInvalidException {
  # 	final Config c = new Config(baseConfig);
  # 	c.fromText(content);
  # 	return c;
  # }
  #
  # @Test
  # public void testTimeUnit() throws ConfigInvalidException {
  # 	assertEquals(0, parseTime("0", MILLISECONDS));
  # 	assertEquals(2, parseTime("2ms", MILLISECONDS));
  # 	assertEquals(200, parseTime("200 milliseconds", MILLISECONDS));
  #
  # 	assertEquals(0, parseTime("0s", SECONDS));
  # 	assertEquals(2, parseTime("2s", SECONDS));
  # 	assertEquals(231, parseTime("231sec", SECONDS));
  # 	assertEquals(1, parseTime("1second", SECONDS));
  # 	assertEquals(300, parseTime("300 seconds", SECONDS));
  #
  # 	assertEquals(2, parseTime("2m", MINUTES));
  # 	assertEquals(2, parseTime("2min", MINUTES));
  # 	assertEquals(1, parseTime("1 minute", MINUTES));
  # 	assertEquals(10, parseTime("10 minutes", MINUTES));
  #
  # 	assertEquals(5, parseTime("5h", HOURS));
  # 	assertEquals(5, parseTime("5hr", HOURS));
  # 	assertEquals(1, parseTime("1hour", HOURS));
  # 	assertEquals(48, parseTime("48hours", HOURS));
  #
  # 	assertEquals(5, parseTime("5 h", HOURS));
  # 	assertEquals(5, parseTime("5 hr", HOURS));
  # 	assertEquals(1, parseTime("1 hour", HOURS));
  # 	assertEquals(48, parseTime("48 hours", HOURS));
  # 	assertEquals(48, parseTime("48 \t \r hours", HOURS));
  #
  # 	assertEquals(4, parseTime("4d", DAYS));
  # 	assertEquals(1, parseTime("1day", DAYS));
  # 	assertEquals(14, parseTime("14days", DAYS));
  #
  # 	assertEquals(7, parseTime("1w", DAYS));
  # 	assertEquals(7, parseTime("1week", DAYS));
  # 	assertEquals(14, parseTime("2w", DAYS));
  # 	assertEquals(14, parseTime("2weeks", DAYS));
  #
  # 	assertEquals(30, parseTime("1mon", DAYS));
  # 	assertEquals(30, parseTime("1month", DAYS));
  # 	assertEquals(60, parseTime("2mon", DAYS));
  # 	assertEquals(60, parseTime("2months", DAYS));
  #
  # 	assertEquals(365, parseTime("1y", DAYS));
  # 	assertEquals(365, parseTime("1year", DAYS));
  # 	assertEquals(365 * 2, parseTime("2years", DAYS));
  # }
  #
  # private long parseTime(String value, TimeUnit unit)
  # 		throws ConfigInvalidException {
  # 	Config c = parse("[a]\na=" + value + "\n");
  # 	return c.getTimeUnit("a", null, "a", 0, unit);
  # }
  #
  # @Test
  # public void testTimeUnitDefaultValue() throws ConfigInvalidException {
  # 	// value not present
  # 	assertEquals(20, parse("[a]\na=0\n").getTimeUnit("a", null, "b", 20,
  # 			MILLISECONDS));
  # 	// value is empty
  # 	assertEquals(20, parse("[a]\na=\" \"\n").getTimeUnit("a", null, "a", 20,
  # 			MILLISECONDS));
  #
  # 	// value is not numeric
  # 	assertEquals(20, parse("[a]\na=test\n").getTimeUnit("a", null, "a", 20,
  # 			MILLISECONDS));
  # }
  #
  # @Test
  # public void testTimeUnitInvalid() throws ConfigInvalidException {
  # 	expectedEx.expect(IllegalArgumentException.class);
  # 	expectedEx
  # 			.expectMessage("Invalid time unit value: a.a=1 monttthhh");
  # 	parseTime("1 monttthhh", DAYS);
  # }
  #
  # @Test
  # public void testTimeUnitInvalidWithSection() throws ConfigInvalidException {
  # 	Config c = parse("[a \"b\"]\na=1 monttthhh\n");
  # 	expectedEx.expect(IllegalArgumentException.class);
  # 	expectedEx.expectMessage("Invalid time unit value: a.b.a=1 monttthhh");
  # 	c.getTimeUnit("a", "b", "a", 0, DAYS);
  # }
  #
  # @Test
  # public void testTimeUnitNegative() throws ConfigInvalidException {
  # 	expectedEx.expect(IllegalArgumentException.class);
  # 	parseTime("-1", MILLISECONDS);
  # }

  describe "escape_value/1" do
    test "escape spaces only" do
      # Empty string is read back as nil, so this doesn't round trip.
      assert Config.escape_value("") == ""

      assert_value_round_trip(" ", "\" \"")
      assert_value_round_trip("  ", "\"  \"")
    end

    test "quotes if leading space" do
      assert_value_round_trip("x", "x")
      assert_value_round_trip(" x", "\" x\"")
      assert_value_round_trip("  x", "\"  x\"")
    end

    test "quotes if trailing space" do
      assert_value_round_trip("x", "x")
      assert_value_round_trip("x  ", "\"x  \"")
      assert_value_round_trip("x ", "\"x \"")
    end

    test "quotes if leading and trailing space" do
      assert_value_round_trip(" x ", "\" x \"")
      assert_value_round_trip("  x ", "\"  x \"")
      assert_value_round_trip(" x  ", "\" x  \"")
      assert_value_round_trip("  x  ", "\"  x  \"")
    end

    test "does not quote if internal space" do
      assert_value_round_trip("x y")
      assert_value_round_trip("x  y")
      assert_value_round_trip("x  y")
      assert_value_round_trip("x  y   z")
      assert_value_round_trip("x #{@ws} y")
    end

    test "does not quote if escapeds special characters" do
      assert_value_round_trip("x\\y", "x\\\\y")
      assert_value_round_trip("x\"y", "x\\\"y")
      assert_value_round_trip("x\ny", "x\\ny")
      assert_value_round_trip("x\ty", "x\\ty")
      assert_value_round_trip("x\by", "x\\by")
    end

    test "quotes if comment characters in value" do
      assert_value_round_trip("x#y", "\"x#y\"")
      assert_value_round_trip("x;y", "\"x;y\"")
    end
  end

  test "parse literal backsapce" do
    # This is round-tripped with an escape sequence by xgit, but C gits writes
    # it out as a literal backslash.

    assert parse_escaped_value("x\by") == "x\by"
  end

  test "escape_value/1 raises error on invalid characters" do
    assert_raise ConfigInvalidError, fn -> Config.escape_value("x\0y") end
  end

  test "escape_subsection/1 raises error on invalid characters" do
    assert_raise ConfigInvalidError, fn -> Config.escape_subsection("x\ny") end
    assert_raise ConfigInvalidError, fn -> Config.escape_subsection("x\0y") end
  end

  test "parse multiple quoted regions" do
    assert parse_escaped_value("b\" a\"\" z; \\n\"") == "b a z; \n"
  end

  test "parse comments" do
    assert parse_escaped_value("baz; comment") == "baz"
    assert parse_escaped_value("baz# comment") == "baz"
    assert parse_escaped_value("baz ; comment") == "baz"
    assert parse_escaped_value("baz # comment") == "baz"

    assert parse_escaped_value("baz ; comment") == "baz"
    assert parse_escaped_value("baz # comment") == "baz"
    assert parse_escaped_value("baz #{@ws} ; comment") == "baz"
    assert parse_escaped_value("baz #{@ws} # comment") == "baz"

    assert parse_escaped_value("\"baz \"; comment") == "baz "
    assert parse_escaped_value("\"baz \"# comment") == "baz "
    assert parse_escaped_value("\"baz \" ; comment") == "baz "
    assert parse_escaped_value("\"baz \" # comment") == "baz "
  end

  test "to_text with leading comment" do
    c =
      parse("""
      ; comment on the first line

      [section "the first"]
        value = blah
      """)
      |> Config.unset_section("branch", "does.not.exist")
      |> Config.unset_section("branch", "remove")

    assert Config.to_text(c) ==
             "; comment on the first line\n" <>
               "\n" <>
               "[section \"the first\"]\n" <>
               "  value = blah\n"
  end

  test "escape_subsection/1" do
    assert_subsection_round_trip("", "\"\"")
    assert_subsection_round_trip("x", "\"x\"")
    assert_subsection_round_trip(" x", "\" x\"")
    assert_subsection_round_trip("x ", "\"x \"")
    assert_subsection_round_trip(" x ", "\" x \"")
    assert_subsection_round_trip("x y", "\"x y\"")
    assert_subsection_round_trip("x  y", "\"x  y\"")
    assert_subsection_round_trip("x\\y", "\"x\\\\y\"")
    assert_subsection_round_trip("x\"y", "\"x\\\"y\"")

    # Unlike for values, \b and \t are not escaped.
    assert_subsection_round_trip("x\by", "\"x\by\"")
    assert_subsection_round_trip("x\ty", "\"x\ty\"")
  end

  test "parse invalid values" do
    assert_invalid_value("x\"\n\"y")
    assert_invalid_value("x\\")
    assert_invalid_value("x\\q")
  end

  test "parse error when value precedes section header" do
    assert_raise ConfigInvalidError, fn ->
      parse("x = 42")
    end
  end

  test "parse error with incomplete section header" do
    assert_raise ConfigInvalidError, fn ->
      parse("[incompl")
    end
  end

  test "parse error with missing section name" do
    assert_raise ConfigInvalidError, fn ->
      parse("[\"subsection with nosection\"]")
    end
  end

  test "parse error with incomplete subsection header" do
    assert_raise ConfigInvalidError, fn ->
      parse("[this \"section header is incomplete\"")
    end

    assert_raise ConfigInvalidError, fn ->
      parse("[this \"section header is incompl")
    end
  end

  test "parse invalid subsections" do
    assert_invalid_subsection("\"x\ny\"")
  end

  test "drop backslash from invalid escape sequence in subsection name" do
    assert parse_escaped_subsection("\"x\\0\"") == "x0"
    assert parse_escaped_subsection("\"x\\q\"") == "xq"

    # Unlike for values, \b, \n, and \t are not valid escape sequences.
    assert parse_escaped_subsection("\"x\\b\"") == "xb"
    assert parse_escaped_subsection("\"x\\n\"") == "xn"
    assert parse_escaped_subsection("\"x\\t\"") == "xt"
  end

  defp assert_value_round_trip(value), do: assert_value_round_trip(value, value)

  defp assert_value_round_trip(value, expected_escaped) do
    escaped = Config.escape_value(value)
    assert escaped == expected_escaped
    assert parse_escaped_value(escaped) == value
  end

  defp parse_escaped_value(escaped_value) do
    "[foo]\nbar=#{escaped_value}"
    |> parse()
    |> Config.get_string("foo", "bar")
  end

  defp assert_invalid_value(escaped_value),
    do: assert_raise(ConfigInvalidError, fn -> parse_escaped_value(escaped_value) end)

  defp assert_subsection_round_trip(subsection, expected_escaped) do
    escaped = Config.escape_subsection(subsection)
    assert escaped == expected_escaped
    assert subsection == parse_escaped_subsection(escaped)
  end

  defp parse_escaped_subsection(escaped_subsection) do
    text = "[foo #{escaped_subsection}]\nbar = value"

    c = parse(text)

    subsections = Config.subsections(c, "foo")
    assert length(subsections) == 1
    List.first(subsections)
  end

  defp assert_invalid_subsection(escaped_subsection) do
    assert_raise ConfigInvalidError, fn -> parse_escaped_subsection(escaped_subsection) end
  end

  # private static FileBasedConfig loadConfig(File file)
  # 		throws IOException, ConfigInvalidException {
  # 	final FileBasedConfig config = new FileBasedConfig(null, file,
  # 			FS.DETECTED);
  # 	config.load();
  # 	return config;
  # }

  test "process remains alive after sleep" do
    c = parse("[foo]\nbar\n")

    Process.sleep(Application.get_env(:xgit, :config_idle_timeout, 60_000) * 2)

    assert Config.get_boolean(c, "foo", "bar", false) == true
    assert Config.get_string(c, "foo", "bar") == ""
  end
end
