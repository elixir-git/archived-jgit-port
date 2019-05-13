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

defmodule Xgit.Util.TupleUtilsTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.TupleUtils, as: TU

  describe "binary_search/2" do
    test "FunctionClauseError if tuple is actually an array" do
    end

    test "empty tuple" do
      assert TU.binary_search({}, 42) == -1
    end

    test "one-element tuple (match)" do
      assert TU.binary_search({42}, 42) == 0
    end

    test "one-element tuple (mismatch)" do
      assert TU.binary_search({0}, 42) == -2
      assert TU.binary_search({99}, 42) == -1
    end

    test "exact match in longer tuple" do
      assert TU.binary_search({0, 1, 4, 9, 16}, 4) == 2
      assert TU.binary_search({0, 1, 4, 9, 16}, 16) == 4
      assert TU.binary_search({0, 1, 4, 9, 16}, 1) == 1
      assert TU.binary_search({0, 1, 4, 9}, 9) == 3
      assert TU.binary_search({0, 1, 4, 9, 16}, 0) == 0
    end

    test "insertion-point response in longer tuple" do
      assert TU.binary_search({0, 1, 4, 9, 16}, 3) == -3
      assert TU.binary_search({0, 1, 4, 9, 16}, 15) == -5
      assert TU.binary_search({0, 1, 4, 9, 16}, 84) == -6
      assert TU.binary_search({0, 1, 4, 9, 16}, 2) == -3
      assert TU.binary_search({0, 1, 4, 9, 16}, -1) == -1
    end
  end
end
