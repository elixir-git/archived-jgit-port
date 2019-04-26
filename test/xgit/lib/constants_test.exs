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

defmodule Xgit.Lib.ConstantsTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.Constants

  doctest Xgit.Lib.Constants

  test "object_id_string_length/0" do
    assert Constants.object_id_string_length() == 40
  end

  test "obj_bad/0" do
    assert Constants.obj_bad() == -1
  end

  test "r_notes_commits/0" do
    assert Constants.r_notes_commits() == "refs/notes/commits"
  end

  test "r_stash/0" do
    assert Constants.r_stash() == "refs/stash"
  end

  describe "type_string/1" do
    test "commit" do
      assert Constants.type_string(1) == "commit"
    end

    test "tree" do
      assert Constants.type_string(2) == "tree"
    end

    test "blob" do
      assert Constants.type_string(3) == "blob"
    end

    test "tag" do
      assert Constants.type_string(4) == "tag"
    end

    test "error" do
      assert_raise(FunctionClauseError, fn -> Constants.type_string(5) end)
    end
  end

  describe "encoded_type_string/1" do
    test "commit" do
      assert Constants.encoded_type_string(1) == 'commit'
    end

    test "tree" do
      assert Constants.encoded_type_string(2) == 'tree'
    end

    test "blob" do
      assert Constants.encoded_type_string(3) == 'blob'
    end

    test "tag" do
      assert Constants.encoded_type_string(4) == 'tag'
    end

    test "error" do
      assert_raise FunctionClauseError, fn -> Constants.encoded_type_string(5) end
    end
  end

  describe "decode_type_string/3" do
    test "commit" do
      assert Constants.decode_type_string(nil, 'commit\nmumble', ?\n) == {1, 'mumble'}
    end

    test "tree" do
      assert Constants.decode_type_string(nil, 'tree\noak', ?\n) == {2, 'oak'}
    end

    test "blob" do
      assert Constants.decode_type_string(nil, 'blob 42', ?\s) == {3, '42'}
    end

    test "tag" do
      assert Constants.decode_type_string(nil, 'tag yup', ?\s) == {4, 'yup'}
    end

    test "error" do
      assert_raise Xgit.Errors.CorruptObjectError, fn ->
        Constants.decode_type_string("whatever", 'not_a_tag 42', ?\s)
      end
    end
  end

  describe "encode_ascii/1" do
    test "converts integers" do
      assert Constants.encode_ascii(42) == '42'
      assert Constants.encode_ascii(0) == '0'
      assert Constants.encode_ascii(-110) == '-110'
    end

    test "converts a simple ASCII string to charlist" do
      assert Constants.encode_ascii("abc") == 'abc'
    end

    test "raises ArgumentError on non-ASCII input" do
      assert_raise(ArgumentError, fn ->
        Constants.encode_ascii("Ūnĭcōde̽")
      end)
    end
  end
end
