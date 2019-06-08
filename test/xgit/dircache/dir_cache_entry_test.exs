# Copyright (C) 2009, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/dircache/DirCacheEntryTest.java
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

defmodule Xgit.DirCache.DirCacheEntryTest do
  use ExUnit.Case, async: true

  alias Xgit.DirCache.DirCacheEntry
  alias Xgit.Errors.InvalidPathError
  alias Xgit.Lib.FileMode

  describe "new/1" do
    test "valid path" do
      assert valid_path?("a")
      assert valid_path?("a/b")
      assert valid_path?("ab/cd/ef")

      refute valid_path?("")
      refute valid_path?("/a")
      refute valid_path?("a//b")
      refute valid_path?("ab/cd//ef")
      refute valid_path?("a/")
      refute valid_path?("ab/cd/ef/")
      refute valid_path?("a\u0000b")
    end
  end

  defp valid_path?(path) do
    try do
      DirCacheEntry.new(path)
      true
    rescue
      _ -> false
    end
  end

  test "new/2" do
    e = DirCacheEntry.new("a", 0)
    assert DirCacheEntry.path(e) == "a"
    assert DirCacheEntry.stage(e) == 0

    e = DirCacheEntry.new("a/b", 1)
    assert DirCacheEntry.path(e) == "a/b"
    assert DirCacheEntry.stage(e) == 1

    e = DirCacheEntry.new("a/c", 2)
    assert DirCacheEntry.path(e) == "a/c"
    assert DirCacheEntry.stage(e) == 2

    e = DirCacheEntry.new("a/d", 3)
    assert DirCacheEntry.path(e) == "a/d"
    assert DirCacheEntry.stage(e) == 3

    e =
      DirCacheEntry.new(
        "a/very/long/path/that/is/more/than/64/characters/long/to/cover/an/edge/case",
        1
      )

    assert DirCacheEntry.path(e) ==
             "a/very/long/path/that/is/more/than/64/characters/long/to/cover/an/edge/case"

    assert DirCacheEntry.stage(e) == 1

    assert_raise InvalidPathError, "Invalid path: /a", fn ->
      DirCacheEntry.new("/a", 1)
    end

    assert_raise FunctionClauseError, fn ->
      DirCacheEntry.new("a", -11)
    end

    assert_raise FunctionClauseError, fn ->
      DirCacheEntry.new("a", 4)
    end
  end

  @valid_file_modes [
    FileMode.regular_file(),
    FileMode.executable_file(),
    FileMode.symlink(),
    FileMode.gitlink()
  ]

  @invalid_file_modes [
    FileMode.missing(),
    FileMode.tree()
  ]

  describe "set_assume_valid/2" do
    test "happy path" do
      e = DirCacheEntry.new("a")
      assert DirCacheEntry.assume_valid?(e) == false

      e2 = DirCacheEntry.set_assume_valid(e, true)
      assert DirCacheEntry.assume_valid?(e2) == true

      e3 = DirCacheEntry.set_assume_valid(e2, false)
      assert DirCacheEntry.assume_valid?(e3) == false
    end

    test "disallows non-boolean values" do
      e = DirCacheEntry.new("a")

      assert_raise FunctionClauseError, fn ->
        DirCacheEntry.set_assume_valid(e, 1)
      end
    end
  end

  describe "set_file_mode/2" do
    test "happy paths" do
      e = DirCacheEntry.new("a")
      assert DirCacheEntry.raw_file_mode_bits(e) == 0

      Enum.each(@valid_file_modes, fn file_mode ->
        e2 = DirCacheEntry.set_file_mode(e, file_mode)
        assert DirCacheEntry.file_mode(e2) == file_mode
        assert DirCacheEntry.raw_file_mode_bits(e2) == file_mode.mode_bits
      end)
    end

    test "disallows certain file modes" do
      e = DirCacheEntry.new("a")
      assert DirCacheEntry.raw_file_mode_bits(e) == 0

      Enum.each(@invalid_file_modes, fn file_mode ->
        assert_raise ArgumentError, "Invalid mode #{inspect(file_mode)} for path a", fn ->
          DirCacheEntry.set_file_mode(e, file_mode)
        end
      end)
    end
  end

  test "set_creation_time/2" do
    e = DirCacheEntry.new("a")
    assert DirCacheEntry.creation_time(e) == 0

    e2 = DirCacheEntry.set_creation_time(e, 2)
    assert DirCacheEntry.creation_time(e2) == 2

    e3 = DirCacheEntry.set_creation_time(e2, 15_422)
    assert DirCacheEntry.creation_time(e3) == 15_422
  end

  test "set_last_modified_time/2" do
    e = DirCacheEntry.new("a")
    assert DirCacheEntry.last_modified_time(e) == 0

    e2 = DirCacheEntry.set_last_modified_time(e, 2)
    assert DirCacheEntry.last_modified_time(e2) == 2

    e3 = DirCacheEntry.set_last_modified_time(e2, 15_422)
    assert DirCacheEntry.last_modified_time(e3) == 15_422
  end

  # @Test
  # public void testCopyMetaDataWithStage() {
  #   copyMetaDataHelper(false);
  # }
  #
  # @Test
  # public void testCopyMetaDataWithoutStage() {
  #   copyMetaDataHelper(true);
  # }
  #
  # private static void copyMetaDataHelper(boolean keepStage) {
  #   DirCacheEntry e = new DirCacheEntry("some/path", DirCacheEntry.STAGE_2);
  #   e.setAssumeValid(false);
  #   e.setCreationTime(2L);
  #   e.setFileMode(FileMode.EXECUTABLE_FILE);
  #   e.setLastModified(3L);
  #   e.setLength(100L);
  #   e.setObjectId(ObjectId
  #       .fromString("0123456789012345678901234567890123456789"));
  #   e.setUpdateNeeded(true);
  #
  #   DirCacheEntry f = new DirCacheEntry("someother/path",
  #       DirCacheEntry.STAGE_1);
  #   f.setAssumeValid(true);
  #   f.setCreationTime(10L);
  #   f.setFileMode(FileMode.SYMLINK);
  #   f.setLastModified(20L);
  #   f.setLength(100000000L);
  #   f.setObjectId(ObjectId
  #       .fromString("1234567890123456789012345678901234567890"));
  #   f.setUpdateNeeded(true);
  #
  #   e.copyMetaData(f, keepStage);
  #   assertTrue(e.isAssumeValid());
  #   assertEquals(10L, e.getCreationTime());
  #   assertEquals(
  #       ObjectId.fromString("1234567890123456789012345678901234567890"),
  #       e.getObjectId());
  #   assertEquals(FileMode.SYMLINK, e.getFileMode());
  #   assertEquals(20L, e.getLastModified());
  #   assertEquals(100000000L, e.getLength());
  #   if (keepStage)
  #     assertEquals(DirCacheEntry.STAGE_2, e.getStage());
  #   else
  #     assertEquals(DirCacheEntry.STAGE_1, e.getStage());
  #   assertTrue(e.isUpdateNeeded());
  #   assertEquals("some/path", e.getPathString());
  # }
end
