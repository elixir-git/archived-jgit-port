# Copyright (C) 2009-2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/revwalk/RevObjectTest.java
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

defmodule Xgit.RevWalk.RevObjectTest do
  use ExUnit.Case, async: true

  alias Xgit.RevWalk.RevObject

  # public class RevObjectTest extends RevWalkTestCase {

  @commit_id "5cd8074ac04156d8f3663b42a40ddcad7d2574b1"
  @unparsed_commit %Xgit.RevWalk.RevObject.Unparsed{id: @commit_id, type: 1}

  describe "Unparsed" do
    test "object_id/1" do
      assert RevObject.object_id(@unparsed_commit) == @commit_id
    end

    test "type/1" do
      assert RevObject.type(@unparsed_commit) == 1
    end
  end

  describe "flags" do
    @unparsed_commit_with_flags %Xgit.RevWalk.RevObject.Unparsed{
      id: @commit_id,
      type: 1,
      flags: MapSet.new([:blah, :boop, :biff])
    }

    test "add_flag/2" do
      refute RevObject.has_flag?(@unparsed_commit, :blah)

      with_blah = RevObject.add_flag(@unparsed_commit, :blah)
      assert RevObject.has_flag?(with_blah, :blah)
    end

    test "add_flags/2" do
      refute RevObject.has_flag?(@unparsed_commit, :blah)
      refute RevObject.has_flag?(@unparsed_commit, :boop)
      refute RevObject.has_flag?(@unparsed_commit, :biff)

      with_flags = RevObject.add_flags(@unparsed_commit, MapSet.new([:blah, :boop]))

      assert RevObject.has_flag?(with_flags, :blah)
      assert RevObject.has_flag?(with_flags, :boop)
      refute RevObject.has_flag?(with_flags, :biff)
    end

    test "remove_flag/2" do
      assert RevObject.has_flag?(@unparsed_commit_with_flags, :blah)

      without_blah = RevObject.remove_flag(@unparsed_commit_with_flags, :blah)

      refute RevObject.has_flag?(without_blah, :blah)
      assert RevObject.has_flag?(without_blah, :boop)
      assert RevObject.has_flag?(without_blah, :biff)
    end

    test "remove_flags/2" do
      assert RevObject.has_flag?(@unparsed_commit_with_flags, :blah)
      assert RevObject.has_flag?(@unparsed_commit_with_flags, :boop)
      assert RevObject.has_flag?(@unparsed_commit_with_flags, :biff)

      without_flags =
        RevObject.remove_flags(@unparsed_commit_with_flags, MapSet.new([:blah, :boop]))

      refute RevObject.has_flag?(without_flags, :blah)
      refute RevObject.has_flag?(without_flags, :boop)
      assert RevObject.has_flag?(without_flags, :biff)
    end

    test "has_any_flag?/2" do
      refute RevObject.has_any_flag?(@unparsed_commit_with_flags, MapSet.new([:jaskdlf]))
      assert RevObject.has_any_flag?(@unparsed_commit_with_flags, MapSet.new([:jaskdlf, :blah]))
    end

    test "has_all_flags?/2" do
      refute RevObject.has_all_flags?(@unparsed_commit_with_flags, MapSet.new([:jaskdlf]))
      refute RevObject.has_all_flags?(@unparsed_commit_with_flags, MapSet.new([:jaskdlf, :blah]))
      assert RevObject.has_all_flags?(@unparsed_commit_with_flags, MapSet.new([:blah, :boop]))

      assert RevObject.has_all_flags?(
               @unparsed_commit_with_flags,
               MapSet.new([:blah, :boop, :biff])
             )

      refute RevObject.has_all_flags?(
               @unparsed_commit_with_flags,
               MapSet.new([:blah, :boop, :biff, :more])
             )
    end

    test "to_string/1" do
      assert to_string(@unparsed_commit) == "commit #{@commit_id} ------"

      c = RevObject.add_flag(@unparsed_commit, :rewrite)
      assert to_string(c) == "commit #{@commit_id} --r---"
    end
  end

  # @SuppressWarnings("unlikely-arg-type")
  # @Test
  # public void testEquals() throws Exception {
  #   final RevCommit a1 = commit();
  #   final RevCommit b1 = commit();
  #
  #   assertTrue(a1.equals(a1));
  #   assertTrue(a1.equals((Object) a1));
  #   assertFalse(a1.equals(b1));
  #
  #   assertTrue(a1.equals(a1));
  #   assertTrue(a1.equals((Object) a1));
  #   assertFalse(a1.equals(""));
  #
  #   final RevCommit a2;
  #   final RevCommit b2;
  #   try (RevWalk rw2 = new RevWalk(db)) {
  #     a2 = rw2.parseCommit(a1);
  #     b2 = rw2.parseCommit(b1);
  #   }
  #   assertNotSame(a1, a2);
  #   assertNotSame(b1, b2);
  #
  #   assertTrue(a1.equals(a2));
  #   assertTrue(b1.equals(b2));
  #
  #   assertEquals(a1.hashCode(), a2.hashCode());
  #   assertEquals(b1.hashCode(), b2.hashCode());
  #
  #   assertTrue(AnyObjectId.equals(a1, a2));
  #   assertTrue(AnyObjectId.equals(b1, b2));
  # }
end
