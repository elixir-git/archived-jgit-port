# Copyright (C) 2008, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/lib/AbbreviatedObjectIdTest.java
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

defmodule Xgit.Lib.AbbreviatedObjectIdTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.AbbreviatedObjectId

  doctest Xgit.Lib.AbbreviatedObjectId

  test "empty ID is not valid or complete" do
    refute AbbreviatedObjectId.valid?("")
    refute AbbreviatedObjectId.complete?("")
  end

  test "full ID id valid and complete" do
    id = "7b6e8067ec96acef9a4184b43210d583b6d2f99a"

    assert AbbreviatedObjectId.valid?(id)
    assert AbbreviatedObjectId.complete?(id)
  end

  test "one-digit ID is not valid or complete" do
    id = "7"

    refute AbbreviatedObjectId.valid?(id)
    refute AbbreviatedObjectId.complete?(id)
  end

  @valid_ids [
    "7b",
    "7b6",
    "7b6e",
    "7b6e8",
    "7b6e80",
    "7b6e806",
    "7b6e8067",
    "7b6e8067e",
    "7b6e8067ec96acef9"
  ]

  test "short IDs of various lengths are valid but not complete" do
    Enum.each(@valid_ids, fn id ->
      assert AbbreviatedObjectId.valid?(id)
      refute AbbreviatedObjectId.complete?(id)
    end)
  end

  describe "prefix_compare/2" do
    test "full IDs, different at last character" do
      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a"
             ) == :eq

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99b"
             ) == :lt

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a",
               "7b6e8067ec96acef9a4184b43210d583b6d2f999"
             ) == :gt
    end

    test "1-char prefix" do
      assert AbbreviatedObjectId.prefix_compare("7", "7b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :eq

      assert AbbreviatedObjectId.prefix_compare("7", "8b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :lt

      assert AbbreviatedObjectId.prefix_compare("7", "6b6e8067ec96acef9a4184b43210d583b6d2f99a") ==
               :gt
    end

    test "7-char prefix" do
      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8067ec96acef9a4184b43210d583b6d2f99a"
             ) == :eq

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8167ec86acef9a4184b43210d583b6d2f99a"
             ) == :lt

      assert AbbreviatedObjectId.prefix_compare(
               "7b6e806",
               "7b6e8057eca6acef9a4184b43210d583b6d2f99a"
             ) == :gt
    end
  end
end
