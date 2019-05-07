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

defmodule Xgit.Util.CompressedBitmapTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.CompressedBitmap

  test "sparse example" do
    cb =
      CompressedBitmap.new()
      |> CompressedBitmap.put(63)
      |> CompressedBitmap.put(64)
      |> CompressedBitmap.put(128)

    refute Enum.empty?(cb)
    assert Enum.count(cb) == 3
    assert Enum.to_list(cb) == [63, 64, 128]

    refute Enum.member?(cb, 0)
    assert Enum.member?(cb, 63)
    assert Enum.member?(cb, 64)
    refute Enum.member?(cb, 65)
    assert Enum.member?(cb, 128)
    refute Enum.member?(cb, 129)
  end

  @illegal_values [
    -1,
    -1000,
    3.14,
    "string",
    false,
    true,
    :atom
  ]

  test "rejects illegal values" do
    cb = CompressedBitmap.new()

    for value <- @illegal_values do
      assert_raise FunctionClauseError, fn ->
        CompressedBitmap.put(cb, value)
      end
    end
  end

  test "empty example" do
    cb = CompressedBitmap.new()

    assert Enum.empty?(cb)
    assert Enum.count(cb) == 0
    assert Enum.to_list(cb) == []

    refute Enum.member?(cb, 0)
    refute Enum.member?(cb, 63)
    refute Enum.member?(cb, 64)
    refute Enum.member?(cb, 65)
    refute Enum.member?(cb, 128)
    refute Enum.member?(cb, 129)
  end

  describe "new/1" do
    test "valid case" do
      cb = CompressedBitmap.new([1, 2, 3, 5])
      assert Enum.to_list(cb) == [1, 2, 3, 5]
    end

    test "optimized case" do
      cb =
        CompressedBitmap.new()
        |> CompressedBitmap.put(63)
        |> CompressedBitmap.put(64)
        |> CompressedBitmap.put(128)

      assert CompressedBitmap.new(cb) == cb
    end

    test "rejects illegal values" do
      for value <- @illegal_values do
        assert_raise ArgumentError, fn ->
          CompressedBitmap.new([1, 2, value, 4])
        end
      end
    end
  end

  describe "equality tests" do
    test "happy path after equivalent puts" do
      cb1 = CompressedBitmap.new([100, 101])

      cb2 =
        [101]
        |> CompressedBitmap.new()
        |> CompressedBitmap.put(100)

      assert cb1 == cb2
    end

    test "negative case" do
      cb1 = CompressedBitmap.new([100, 102])

      cb2 =
        [101]
        |> CompressedBitmap.new()
        |> CompressedBitmap.put(100)

      refute cb1 == cb2
    end
  end

  describe "union/2" do
    test "some overlap" do
      cb1 = CompressedBitmap.new([1, 2, 3, 5])
      cb2 = CompressedBitmap.new([3, 4, 5, 8])

      cb_or = CompressedBitmap.union(cb1, cb2)
      assert Enum.to_list(cb_or) == [1, 2, 3, 4, 5, 8]
    end

    test "no overlap" do
      cb1 = CompressedBitmap.new([1, 2, 3, 4])
      cb2 = CompressedBitmap.new([5, 6, 7, 8])

      cb_or = CompressedBitmap.union(cb1, cb2)
      assert Enum.to_list(cb_or) == [1, 2, 3, 4, 5, 6, 7, 8]
    end

    test "all overlap" do
      cb = CompressedBitmap.new([1, 2, 3, 4])
      cb_or = CompressedBitmap.union(cb, cb)

      assert Enum.to_list(cb_or) == [1, 2, 3, 4]
    end
  end

  describe "xor/2" do
    test "some overlap" do
      cb1 = CompressedBitmap.new([1, 2, 3, 5])
      cb2 = CompressedBitmap.new([3, 4, 5, 8])

      xor = CompressedBitmap.xor(cb1, cb2)

      assert Enum.to_list(xor) == [1, 2, 4, 8]
    end

    test "no overlap" do
      cb1 = CompressedBitmap.new([1, 2, 3, 4])
      cb2 = CompressedBitmap.new([5, 6, 7, 8])

      xor = CompressedBitmap.xor(cb1, cb2)

      assert Enum.to_list(xor) == [1, 2, 3, 4, 5, 6, 7, 8]
    end

    test "all overlap" do
      cb = CompressedBitmap.new([1, 2, 3, 4])
      xor = CompressedBitmap.xor(cb, cb)

      assert Enum.to_list(xor) == []
    end
  end
end
