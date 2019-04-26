# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/lib/ObjectIdRefTest.java
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

defmodule Xgit.Lib.ObjectIdRefTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.ObjectIdRef
  alias Xgit.Lib.Ref

  doctest Xgit.Lib.ObjectIdRef

  @object_id_1 "41eb0d88f833b558bddeb269b7ab77399cdf98ed"
  @object_id_2 "698dd0b8d0c299f080559a1cffc7fe029479a408"
  @name "refs/heads/a.test.ref"

  test "peeled status not known" do
    r = %ObjectIdRef{storage: :loose, name: @name, object_id: @object_id_1}

    assert Ref.storage(r) == :loose
    assert Ref.name(r) == @name
    assert Ref.object_id(r) == @object_id_1
    refute Ref.peeled?(r)
    assert Ref.peeled_object_id(r) == nil
    assert Ref.leaf(r) == r
    assert Ref.target(r) == r
    refute Ref.symbolic?(r)

    r = %ObjectIdRef{storage: :packed, name: @name, object_id: @object_id_1}
    assert Ref.storage(r) == :packed

    r = %ObjectIdRef{storage: :new, name: @name}
    assert Ref.storage(r) == :new
    assert Ref.name(r) == @name
    assert Ref.object_id(r) == nil
    refute Ref.peeled?(r)
    assert Ref.peeled_object_id(r) == nil
    assert Ref.leaf(r) == r
    assert Ref.target(r) == r
    refute Ref.symbolic?(r)
  end

  test "peeled non-tag" do
    r = %ObjectIdRef{storage: :loose, name: @name, object_id: @object_id_1, peeled?: true}
    assert Ref.peeled?(r) == true
    assert Ref.peeled_object_id(r) == nil

    r = %ObjectIdRef{
      storage: :loose,
      name: @name,
      object_id: @object_id_1,
      peeled_object_id: @object_id_2
    }

    assert Ref.peeled?(r) == true
    assert Ref.peeled_object_id(r) == nil
  end

  test "peeled tag" do
    r = %ObjectIdRef{
      storage: :loose,
      name: @name,
      object_id: @object_id_1,
      peeled_object_id: @object_id_2,
      tag?: true
    }

    assert Ref.peeled?(r) == true
    assert Ref.peeled_object_id(r) == @object_id_2
  end

  test "Ref.update_index/1" do
    r = %ObjectIdRef{storage: :loose, name: @name, object_id: @object_id_1, update_index: 3}
    assert Ref.update_index(r) == 3

    r = %ObjectIdRef{
      storage: :loose,
      name: @name,
      object_id: @object_id_1,
      peeled_object_id: @object_id_2,
      tag?: true,
      update_index: 4
    }

    assert Ref.update_index(r) == 4

    r = %ObjectIdRef{
      storage: :loose,
      name: @name,
      object_id: @object_id_1,
      peeled_object_id: @object_id_2,
      update_index: 5
    }

    assert Ref.update_index(r) == 5
  end

  test "Ref.update_index/1 when not set" do
    assert_raise RuntimeError, fn ->
      Ref.update_index(%ObjectIdRef{storage: :loose, name: @name, object_id: @object_id_1})
    end
  end

  test "to_string/1" do
    r = %ObjectIdRef{storage: :loose, name: @name, object_id: @object_id_1}
    assert to_string(r) == "Ref[#{@name}=#{@object_id_1}(undefined)]"
  end
end
