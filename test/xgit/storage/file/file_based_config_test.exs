# Copyright (C) 2012, Marc Strapetz
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/storage/file/FileBasedConfigTest.java
#
# Copyright (C) 2019, Eric Scouten <eric+xgit@scouten.com>
#
# This program and the accompanying materials are made available
# under the terms of the Eclipse Distribution License v1.0 which
# accompanies this distribution, is reproduced below, and is
# available at http://www.eclipse.org/org/documents/edl-v10.php
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# - Neither the name of the Eclipse Foundation, Inc. nor the
#   names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior
#   written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

defmodule Xgit.Storage.File.FileBasedConfigTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Config
  alias Xgit.Storage.File.FileBasedConfig

  doctest Xgit.Storage.File.FileBasedConfig

  @user "user"
  @name "name"

  # TO DO: https://github.com/elixir-git/xgit/issues/148

  # private static final String EMAIL = "email";

  @alice "Alice"
  @bob "Bob"

  # private static final String ALICE_EMAIL = "alice@home";

  @content1 '[#{@user}]\n\t#{@name} = #{@alice}\n'
  @content2 '[#{@user}]\n\t#{@name} = #{@bob}\n'

  # private static final String CONTENT3 = "[" + USER + "]\n\t" + NAME + " = "
  #     + ALICE + "\n" + "[" + USER + "]\n\t" + EMAIL + " = " + ALICE_EMAIL;

  setup do
    Temp.track!()
    temp_file_path = Temp.mkdir!(prefix: "tmp_")
    {:ok, trash: temp_file_path}
  end

  test "UTF-8 encoding", %{trash: trash} do
    path = create_file!(trash, @content1)

    config = FileBasedConfig.config_for_path(path)
    assert :ok = Config.load(config)

    assert Config.get_string(config, @user, @name) == @alice

    Config.set_string(config, @user, @name, @bob)
    assert :ok = Config.save(config)

    assert File.read!(path) == to_string(@content2)
  end

  test "UTF-8 encoding preserves BOM", %{trash: trash} do
    path = create_file!(trash, [239, 187, 191 | @content1])

    config = FileBasedConfig.config_for_path(path)
    assert :ok = Config.load(config)

    assert Config.get_string(config, @user, @name) == @alice

    Config.set_string(config, @user, @name, @bob)
    assert :ok = Config.save(config)

    assert File.read!(path) == "\uFEFF" <> to_string(@content2)
  end

  test "preserves leading whitespace", %{trash: trash} do
    path = create_file!(trash, ' \n\t' ++ @content1)

    config = FileBasedConfig.config_for_path(path)
    assert :ok = Config.load(config)

    assert Config.get_string(config, @user, @name) == @alice

    Config.set_string(config, @user, @name, @bob)
    assert :ok = Config.save(config)

    assert File.read!(path) == to_string(' \n\t' ++ @content2)
  end

  test "file doesn't exist", %{trash: trash} do
    path = create_file!(trash, @content1)
    File.rm!(path)

    config = FileBasedConfig.config_for_path(path)
    assert :ok = Config.load(config)

    assert Config.get_string(config, @user, @name) == nil

    Config.set_string(config, @user, @name, @bob)
    assert :ok = Config.save(config)

    assert File.read!(path) == to_string(@content2)
  end

  describe "outdated?/1" do
    test "not outdated after first read", %{trash: trash} do
      path = create_file!(trash, @content1)

      Process.sleep(3000)
      # Make sure the file is definitively seen as dirty.

      config = FileBasedConfig.config_for_path(path)
      assert :ok = Config.load(config)

      assert FileBasedConfig.outdated?(config) == false
    end

    test "outdated after rewrite", %{trash: trash} do
      path = create_file!(trash, @content1)

      config = FileBasedConfig.config_for_path(path)
      assert :ok = Config.load(config)

      # Rewrite the file long enough after first write
      # that we can be sure it will be seen as dirty.

      Process.sleep(3000)
      File.write!(path, @content2)

      assert FileBasedConfig.outdated?(config) == true
    end

    test "other config is never outdated" do
      config = Config.new()
      assert FileBasedConfig.outdated?(config) == false
    end
  end

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

  defp create_file!(trash, content, subdir \\ nil) do
    dir =
      if subdir == nil,
        do: trash,
        else: Path.join(trash, subdir)

    File.mkdir_p!(dir)
    path = Path.join(dir, "FileBasedConfigTest-#{:rand.uniform(1_000_000_000)}")
    File.write!(path, content)
    path
  end
end
