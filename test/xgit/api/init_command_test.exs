defmodule Xgit.Api.InitCommandTest do
  use Xgit.Test.RepositoryTestCase

  alias Xgit.Api.InitCommand
  alias Xgit.Lib.Repository

  setup do
    RepositoryTestCase.setup_test()
  end

  test "basic case" do
    dir = Temp.mkdir!()

    repo =
      %InitCommand{dir: dir}
      |> InitCommand.run()

    assert Repository.valid?(repo)
  end

  test "non-empty repository" do
    dir = Temp.mkdir!(prefix: "testInitRepository2")

    some_file = Path.join(dir, "someFile")
    File.touch!(some_file)

    assert File.regular?(some_file)

    repo = InitCommand.run(%InitCommand{dir: dir})
    assert Repository.valid?(repo)
  end

  test "bare repository" do
    dir = Temp.mkdir!(prefix: "testInitBareRepository")

    repo = InitCommand.run(%InitCommand{dir: dir, bare?: true})

    assert Repository.valid?(repo)
    assert Repository.bare?(repo)
  end

  # @Test
  # public void testInitBareRepository() throws IOException,
  #     JGitInternalException, GitAPIException {
  #   File directory = createTempDirectory("testInitBareRepository");
  #   InitCommand command = new InitCommand();
  #   command.setDirectory(directory);
  #   command.setBare(true);
  #   try (Git git = command.call()) {
  #     Repository repository = git.getRepository();
  #     assertNotNull(repository);
  #     assertTrue(repository.isBare());
  #   }
  # }
  #
  # // non-bare repos where gitDir and directory is set. Same as
  # // "git init --separate-git-dir /tmp/a /tmp/b"
  # @Test
  # public void testInitWithExplicitGitDir() throws IOException,
  #     JGitInternalException, GitAPIException {
  #   File wt = createTempDirectory("testInitRepositoryWT");
  #   File gitDir = createTempDirectory("testInitRepositoryGIT");
  #   InitCommand command = new InitCommand();
  #   command.setDirectory(wt);
  #   command.setGitDir(gitDir);
  #   try (Git git = command.call()) {
  #     Repository repository = git.getRepository();
  #     assertNotNull(repository);
  #     assertEqualsFile(wt, repository.getWorkTree());
  #     assertEqualsFile(gitDir, repository.getDirectory());
  #   }
  # }
  #
  # // non-bare repos where only gitDir is set. Same as
  # // "git init --separate-git-dir /tmp/a"
  # @Test
  # public void testInitWithOnlyExplicitGitDir() throws IOException,
  #     JGitInternalException, GitAPIException {
  #   MockSystemReader reader = (MockSystemReader) SystemReader.getInstance();
  #   reader.setProperty(Constants.OS_USER_DIR, getTemporaryDirectory()
  #       .getAbsolutePath());
  #   File gitDir = createTempDirectory("testInitRepository/.git");
  #   InitCommand command = new InitCommand();
  #   command.setGitDir(gitDir);
  #   try (Git git = command.call()) {
  #     Repository repository = git.getRepository();
  #     assertNotNull(repository);
  #     assertEqualsFile(gitDir, repository.getDirectory());
  #     assertEqualsFile(new File(reader.getProperty("user.dir")),
  #         repository.getWorkTree());
  #   }
  # }
  #
  # // Bare repos where gitDir and directory is set will only work if gitDir and
  # // directory is pointing to same dir. Same as
  # // "git init --bare --separate-git-dir /tmp/a /tmp/b"
  # // (works in native git but I guess that's more a bug)
  # @Test(expected = IllegalStateException.class)
  # public void testInitBare_DirAndGitDirMustBeEqual() throws IOException,
  #     JGitInternalException, GitAPIException {
  #   File gitDir = createTempDirectory("testInitRepository.git");
  #   InitCommand command = new InitCommand();
  #   command.setBare(true);
  #   command.setDirectory(gitDir);
  #   command.setGitDir(new File(gitDir, ".."));
  #   command.call();
  # }
  #
  # // If neither directory nor gitDir is set in a non-bare repo make sure
  # // worktree and gitDir are set correctly. Standard case. Same as
  # // "git init"
  # @Test
  # public void testInitWithDefaultsNonBare() throws JGitInternalException,
  #     GitAPIException, IOException {
  #   MockSystemReader reader = (MockSystemReader) SystemReader.getInstance();
  #   reader.setProperty(Constants.OS_USER_DIR, getTemporaryDirectory()
  #       .getAbsolutePath());
  #   InitCommand command = new InitCommand();
  #   command.setBare(false);
  #   try (Git git = command.call()) {
  #     Repository repository = git.getRepository();
  #     assertNotNull(repository);
  #     assertEqualsFile(new File(reader.getProperty("user.dir"), ".git"),
  #         repository.getDirectory());
  #     assertEqualsFile(new File(reader.getProperty("user.dir")),
  #         repository.getWorkTree());
  #   }
  # }
  #
  # // If neither directory nor gitDir is set in a bare repo make sure
  # // worktree and gitDir are set correctly. Standard case. Same as
  # // "git init --bare"
  # @Test(expected = NoWorkTreeException.class)
  # public void testInitWithDefaultsBare() throws JGitInternalException,
  #     GitAPIException, IOException {
  #   MockSystemReader reader = (MockSystemReader) SystemReader.getInstance();
  #   reader.setProperty(Constants.OS_USER_DIR, getTemporaryDirectory()
  #       .getAbsolutePath());
  #   InitCommand command = new InitCommand();
  #   command.setBare(true);
  #   try (Git git = command.call()) {
  #     Repository repository = git.getRepository();
  #     assertNotNull(repository);
  #     assertEqualsFile(new File(reader.getProperty("user.dir")),
  #         repository.getDirectory());
  #     assertNull(repository.getWorkTree());
  #   }
  # }
  #
  # // In a non-bare repo when directory and gitDir is set then they shouldn't
  # // point to the same dir. Same as
  # // "git init --separate-git-dir /tmp/a /tmp/a"
  # // (works in native git but I guess that's more a bug)
  # @Test(expected = IllegalStateException.class)
  # public void testInitNonBare_GitdirAndDirShouldntBeSame()
  #     throws JGitInternalException, GitAPIException, IOException {
  #   File gitDir = createTempDirectory("testInitRepository.git");
  #   InitCommand command = new InitCommand();
  #   command.setBare(false);
  #   command.setGitDir(gitDir);
  #   command.setDirectory(gitDir);
  #   command.call().getRepository();
  # }
end
