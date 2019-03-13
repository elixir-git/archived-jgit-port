defmodule Xgit.Storage.File.FileBasedConfigTest do
  use ExUnit.Case, async: true

  alias Xgit.Storage.File.FileBasedConfig
  doctest Xgit.Storage.File.FileBasedConfig

  # private static final String USER = "user";
  #
  # private static final String NAME = "name";
  #
  # private static final String EMAIL = "email";
  #
  # private static final String ALICE = "Alice";
  #
  # private static final String BOB = "Bob";
  #
  # private static final String ALICE_EMAIL = "alice@home";
  #
  # private static final String CONTENT1 = "[" + USER + "]\n\t" + NAME + " = "
  #     + ALICE + "\n";
  #
  # private static final String CONTENT2 = "[" + USER + "]\n\t" + NAME + " = "
  #     + BOB + "\n";
  #
  # private static final String CONTENT3 = "[" + USER + "]\n\t" + NAME + " = "
  #     + ALICE + "\n" + "[" + USER + "]\n\t" + EMAIL + " = " + ALICE_EMAIL;
  #
  # private File trash;
  #
  # @Before
  # public void setUp() throws Exception {
  #   trash = File.createTempFile("tmp_", "");
  #   trash.delete();
  #   assertTrue("mkdir " + trash, trash.mkdir());
  # }
  #
  # @After
  # public void tearDown() throws Exception {
  #   FileUtils.delete(trash, FileUtils.RECURSIVE | FileUtils.SKIP_MISSING);
  # }
  #
  # @Test
  # public void testSystemEncoding() throws IOException, ConfigInvalidException {
  #   final File file = createFile(CONTENT1.getBytes(UTF_8));
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #
  #   config.setString(USER, null, NAME, BOB);
  #   config.save();
  #   assertArrayEquals(CONTENT2.getBytes(UTF_8), IO.readFully(file));
  # }
  #
  # @Test
  # public void testUTF8withoutBOM() throws IOException, ConfigInvalidException {
  #   final File file = createFile(CONTENT1.getBytes(UTF_8));
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #
  #   config.setString(USER, null, NAME, BOB);
  #   config.save();
  #   assertArrayEquals(CONTENT2.getBytes(UTF_8), IO.readFully(file));
  # }
  #
  # @Test
  # public void testUTF8withBOM() throws IOException, ConfigInvalidException {
  #   final ByteArrayOutputStream bos1 = new ByteArrayOutputStream();
  #   bos1.write(0xEF);
  #   bos1.write(0xBB);
  #   bos1.write(0xBF);
  #   bos1.write(CONTENT1.getBytes(UTF_8));
  #
  #   final File file = createFile(bos1.toByteArray());
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #
  #   config.setString(USER, null, NAME, BOB);
  #   config.save();
  #
  #   final ByteArrayOutputStream bos2 = new ByteArrayOutputStream();
  #   bos2.write(0xEF);
  #   bos2.write(0xBB);
  #   bos2.write(0xBF);
  #   bos2.write(CONTENT2.getBytes(UTF_8));
  #   assertArrayEquals(bos2.toByteArray(), IO.readFully(file));
  # }
  #
  # @Test
  # public void testLeadingWhitespaces() throws IOException, ConfigInvalidException {
  #   final ByteArrayOutputStream bos1 = new ByteArrayOutputStream();
  #   bos1.write(" \n\t".getBytes(UTF_8));
  #   bos1.write(CONTENT1.getBytes(UTF_8));
  #
  #   final File file = createFile(bos1.toByteArray());
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #
  #   config.setString(USER, null, NAME, BOB);
  #   config.save();
  #
  #   final ByteArrayOutputStream bos2 = new ByteArrayOutputStream();
  #   bos2.write(" \n\t".getBytes(UTF_8));
  #   bos2.write(CONTENT2.getBytes(UTF_8));
  #   assertArrayEquals(bos2.toByteArray(), IO.readFully(file));
  # }
  #
  # @Test
  # public void testIncludeAbsolute()
  #     throws IOException, ConfigInvalidException {
  #   final File includedFile = createFile(CONTENT1.getBytes(UTF_8));
  #   final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #   bos.write("[include]\npath=".getBytes(UTF_8));
  #   bos.write(pathToString(includedFile).getBytes(UTF_8));
  #
  #   final File file = createFile(bos.toByteArray());
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  # }
  #
  # @Test
  # public void testIncludeRelativeDot()
  #     throws IOException, ConfigInvalidException {
  #   final File includedFile = createFile(CONTENT1.getBytes(UTF_8), "dir1");
  #   final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #   bos.write("[include]\npath=".getBytes(UTF_8));
  #   bos.write(("./" + includedFile.getName()).getBytes(UTF_8));
  #
  #   final File file = createFile(bos.toByteArray(), "dir1");
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  # }
  #
  # @Test
  # public void testIncludeRelativeDotDot()
  #     throws IOException, ConfigInvalidException {
  #   final File includedFile = createFile(CONTENT1.getBytes(UTF_8), "dir1");
  #   final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #   bos.write("[include]\npath=".getBytes(UTF_8));
  #   bos.write(("../" + includedFile.getParentFile().getName() + "/"
  #       + includedFile.getName()).getBytes(UTF_8));
  #
  #   final File file = createFile(bos.toByteArray(), "dir2");
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  # }
  #
  # @Test
  # public void testIncludeRelativeDotDotNotFound()
  #     throws IOException, ConfigInvalidException {
  #   final File includedFile = createFile(CONTENT1.getBytes(UTF_8));
  #   final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #   bos.write("[include]\npath=".getBytes(UTF_8));
  #   bos.write(("../" + includedFile.getName()).getBytes(UTF_8));
  #
  #   final File file = createFile(bos.toByteArray());
  #   final FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #   assertEquals(null, config.getString(USER, null, NAME));
  # }
  #
  # @Test
  # public void testIncludeWithTilde()
  #     throws IOException, ConfigInvalidException {
  #   final File includedFile = createFile(CONTENT1.getBytes(UTF_8), "home");
  #   final ByteArrayOutputStream bos = new ByteArrayOutputStream();
  #   bos.write("[include]\npath=".getBytes(UTF_8));
  #   bos.write(("~/" + includedFile.getName()).getBytes(UTF_8));
  #
  #   final File file = createFile(bos.toByteArray(), "repo");
  #   final FS fs = FS.DETECTED.newInstance();
  #   fs.setUserHome(includedFile.getParentFile());
  #
  #   final FileBasedConfig config = new FileBasedConfig(file, fs);
  #   config.load();
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  # }
  #
  # @Test
  # public void testIncludeDontInlineIncludedLinesOnSave()
  #     throws IOException, ConfigInvalidException {
  #   // use a content with multiple sections and multiple key/value pairs
  #   // because code for first line works different than for subsequent lines
  #   final File includedFile = createFile(CONTENT3.getBytes(UTF_8), "dir1");
  #
  #   final File file = createFile(new byte[0], "dir2");
  #   FileBasedConfig config = new FileBasedConfig(file, FS.DETECTED);
  #   config.setString("include", null, "path",
  #       ("../" + includedFile.getParentFile().getName() + "/"
  #           + includedFile.getName()));
  #
  #   // just by setting the include.path, it won't be included
  #   assertEquals(null, config.getString(USER, null, NAME));
  #   assertEquals(null, config.getString(USER, null, EMAIL));
  #   config.save();
  #
  #   // and it won't be included after saving
  #   assertEquals(null, config.getString(USER, null, NAME));
  #   assertEquals(null, config.getString(USER, null, EMAIL));
  #
  #   final String expectedText = config.toText();
  #   assertEquals(2,
  #       new StringTokenizer(expectedText, "\n", false).countTokens());
  #
  #   config = new FileBasedConfig(file, FS.DETECTED);
  #   config.load();
  #
  #   String actualText = config.toText();
  #   assertEquals(expectedText, actualText);
  #   // but it will be included after (re)loading
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #   assertEquals(ALICE_EMAIL, config.getString(USER, null, EMAIL));
  #
  #   config.save();
  #
  #   actualText = config.toText();
  #   assertEquals(expectedText, actualText);
  #   // and of course preserved after saving
  #   assertEquals(ALICE, config.getString(USER, null, NAME));
  #   assertEquals(ALICE_EMAIL, config.getString(USER, null, EMAIL));
  # }
  #
  # private File createFile(byte[] content) throws IOException {
  #   return createFile(content, null);
  # }
  #
  # private File createFile(byte[] content, String subdir) throws IOException {
  #   File dir = subdir != null ? new File(trash, subdir) : trash;
  #   dir.mkdirs();
  #
  #   File f = File.createTempFile(getClass().getName(), null, dir);
  #   try (FileOutputStream os = new FileOutputStream(f, true)) {
  #     os.write(content);
  #   }
  #   return f;
  # }
end
