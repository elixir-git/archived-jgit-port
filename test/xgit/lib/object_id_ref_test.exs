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
