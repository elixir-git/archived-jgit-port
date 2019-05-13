# Copyright (C) 2009, Google Inc.
# Copyright (C) 2008, Jonas Fonseca <fonseca@diku.dk>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/lib/ObjectIdTest.java
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

defmodule Xgit.Lib.ObjectIdTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants
  alias Xgit.Lib.ObjectId

  doctest Xgit.Lib.ObjectId

  test "zero/0" do
    zero = ObjectId.zero()
    assert is_binary(zero)
    assert String.length(zero) == 40
    assert ObjectId.valid?(zero)
    assert String.match?(zero, ~r/^0+$/)
  end

  test "valid?/1" do
    assert ObjectId.valid?("1234567890abcdef12341234567890abcdef1234")
    refute ObjectId.valid?("1234567890abcdef1231234567890abcdef1234")
    refute ObjectId.valid?("1234567890abcdef123451234567890abcdef1234")
    refute ObjectId.valid?("1234567890abCdef12341234567890abcdef1234")
    refute ObjectId.valid?("1234567890abXdef12341234567890abcdef1234")

    assert ObjectId.valid?('1234567890abcdef12341234567890abcdef1234')
    refute ObjectId.valid?('1234567890abcdef1231234567890abcdef1234')
    refute ObjectId.valid?('1234567890abcdef123451234567890abcdef1234')
    refute ObjectId.valid?('1234567890abCdef12341234567890abcdef1234')
    refute ObjectId.valid?('1234567890abXdef12341234567890abcdef1234')

    refute ObjectId.valid?(nil)
  end

  test "from_raw_bytes/1" do
    assert 0..19 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "000102030405060708090a0b0c0d0e0f10111213"

    assert 1..25 |> Enum.to_list() |> ObjectId.from_raw_bytes() ==
             "0102030405060708090a0b0c0d0e0f1011121314"
  end

  test "to_raw_bytes/1" do
    assert ObjectId.to_raw_bytes("000102030405060708090a0b0c0d0e0f10111213") ==
             Enum.to_list(0..19)

    assert ObjectId.to_raw_bytes("ff0102030405060708090a0b0c0d0e0f10111213") == [
             255 | Enum.to_list(1..19)
           ]

    assert_raise ArgumentError, fn ->
      ObjectId.to_raw_bytes("FF0102030405060708090a0b0c0d0e0f10111213")
    end

    assert_raise FunctionClauseError, fn ->
      ObjectId.to_raw_bytes("f0102030405060708090a0b0c0d0e0f10111213")
    end
  end

  test "from_hex_charlist/1" do
    assert ObjectId.from_hex_charlist('1234567890abcdef12341234567890abcdef1234') ==
             {'1234567890abcdef12341234567890abcdef1234', []}

    assert ObjectId.from_hex_charlist('1234567890abcdef1231234567890abcdef1234') == false

    assert ObjectId.from_hex_charlist('1234567890abcdef123451234567890abcdef1234') ==
             {'1234567890abcdef123451234567890abcdef123', '4'}

    assert ObjectId.from_hex_charlist('1234567890abCdef12341234567890abcdef1234') == false

    assert ObjectId.from_hex_charlist('1234567890abXdef12341234567890abcdef1234') == false
  end

  test "id_for/2" do
    data = 'test025 some data, more than 16 bytes to get good coverage'

    assert ObjectId.id_for(Constants.obj_blob(), data) ==
             "4f561df5ecf0dfbd53a0dc0f37262fef075d9dde"
  end
end
