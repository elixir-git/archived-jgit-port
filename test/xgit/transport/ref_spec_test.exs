defmodule Xgit.Transport.RefSpecTest do
  use ExUnit.Case

  alias Xgit.Lib.ObjectIdRef
  alias Xgit.Transport.RefSpec

  test "master:master" do
    sn = "refs/heads/master"
    rs = RefSpec.from_string("#{sn}:#{sn}")

    refute rs.force?
    refute RefSpec.wildcard?(rs)

    assert rs.src_name == sn
    assert rs.dst_name == sn
    assert to_string(rs) == "#{sn}:#{sn}"

    r = %ObjectIdRef{storage: :loose, name: sn}
    assert RefSpec.match_source?(rs, r)
    assert RefSpec.match_destination?(rs, r)
    assert rs == RefSpec.expand_from_source(rs, r)

    r = %ObjectIdRef{storage: :loose, name: "#{sn}-and-more"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "split last colon" do
    lhs = ":m:a:i:n:t"
    rhs = "refs/heads/maint"

    rs = RefSpec.from_string("#{lhs}:#{rhs}")

    refute rs.force?
    refute RefSpec.wildcard?(rs)

    assert rs.src_name == lhs
    assert rs.dst_name == rhs
    assert to_string(rs) == "#{lhs}:#{rhs}"
  end

  test "master:master (with force)" do
    sn = "refs/heads/master"
    rs = RefSpec.from_string("+#{sn}:#{sn}")

    assert rs.force? == true
    refute RefSpec.wildcard?(rs)

    assert rs.src_name == sn
    assert rs.dst_name == sn
    assert to_string(rs) == "+#{sn}:#{sn}"

    r = %ObjectIdRef{storage: :loose, name: sn}
    assert RefSpec.match_source?(rs, r)
    assert RefSpec.match_destination?(rs, r)
    assert rs == RefSpec.expand_from_source(rs, r)

    r = %ObjectIdRef{storage: :loose, name: "#{sn}-and-more"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "master" do
    sn = "refs/heads/master"
    rs = RefSpec.from_string(sn)

    refute rs.force?
    refute RefSpec.wildcard?(rs)
    assert rs.dst_name == nil
    assert to_string(rs) == sn

    r = %ObjectIdRef{storage: :loose, name: sn}
    assert RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
    assert RefSpec.expand_from_source(rs, r) == rs

    r = %ObjectIdRef{storage: :loose, name: "#{sn}-and-more"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "force master" do
    sn = "refs/heads/master"
    rs = RefSpec.from_string("+#{sn}")

    assert rs.force? == true
    refute RefSpec.wildcard?(rs)
    assert rs.src_name == sn
    assert rs.dst_name == nil
    assert to_string(rs) == "+#{sn}"

    r = %ObjectIdRef{storage: :loose, name: sn}
    assert RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
    assert RefSpec.expand_from_source(rs, r) == rs

    r = %ObjectIdRef{storage: :loose, name: "#{sn}-and-more"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "delete master" do
    sn = "refs/heads/master"
    rs = RefSpec.from_string(":#{sn}")

    refute rs.force?
    refute RefSpec.wildcard?(rs)
    assert rs.src_name == nil
    assert rs.dst_name == sn
    assert to_string(rs) == ":#{sn}"

    r = %ObjectIdRef{storage: :loose, name: sn}
    refute RefSpec.match_source?(rs, r)
    assert RefSpec.match_destination?(rs, r)
    assert RefSpec.expand_from_source(rs, r) == rs

    r = %ObjectIdRef{storage: :loose, name: "#{sn}-and-more"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "force remotes origin" do
    srcn = "refs/heads/*"
    dstn = "refs/remotes/origin/*"

    rs = RefSpec.from_string("+#{srcn}:#{dstn}")

    assert rs.force? == true
    assert RefSpec.wildcard?(rs)
    assert rs.src_name == srcn
    assert rs.dst_name == dstn

    assert to_string(rs) == "+#{srcn}:#{dstn}"

    r = %ObjectIdRef{storage: :loose, name: "refs/heads/master"}

    assert RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)

    expanded = RefSpec.expand_from_source(rs, r)
    refute rs == expanded
    refute RefSpec.wildcard?(expanded)
    assert r.name == expanded.src_name
    assert "refs/remotes/origin/master" == expanded.dst_name

    r = %ObjectIdRef{storage: :loose, name: "refs/remotes/origin/next"}
    refute RefSpec.match_source?(rs, r)
    assert RefSpec.match_destination?(rs, r)

    r = %ObjectIdRef{storage: :loose, name: "refs/tags/v1.0"}
    refute RefSpec.match_source?(rs, r)
    refute RefSpec.match_destination?(rs, r)
  end

  test "create empty" do
    rs = %RefSpec{}

    refute rs.force?
    refute RefSpec.wildcard?(rs)
    assert rs.src_name == "HEAD"
    assert rs.dst_name == nil
    assert to_string(rs) == "HEAD"
  end

  test "replace_source/2" do
    a = %RefSpec{}
    b = RefSpec.replace_source(a, "refs/heads/master")

    refute a == b
    assert to_string(a) == "HEAD"
    assert to_string(b) == "refs/heads/master"
  end

  test "replace_destination/2" do
    a = %RefSpec{}
    b = RefSpec.replace_destination(a, "refs/heads/master")

    refute a == b
    assert to_string(a) == "HEAD"
    assert to_string(b) == "HEAD:refs/heads/master"
  end

  test "replace_destination/2 and replace_source/2 (nil)" do
    a = %RefSpec{}

    b =
      a
      |> RefSpec.replace_destination("refs/heads/master")
      |> RefSpec.replace_source(nil)

    refute a == b
    assert to_string(b) == ":refs/heads/master"
  end

  test "replace_source_and_destination/3" do
    a = %RefSpec{}
    b = RefSpec.replace_source_and_destination(a, "refs/heads/*", "refs/remotes/origin/*")

    refute a == b
    assert to_string(b) == "refs/heads/*:refs/remotes/origin/*"
  end

  describe "expand_from_soure/2" do
    test "non-wildcard" do
      src = "refs/heads/master"
      dst = "refs/remotes/origin/master"

      a = RefSpec.from_string("#{src}:#{dst}")
      r = RefSpec.expand_from_source(a, src)

      assert a == r
      refute RefSpec.wildcard?(r)
      assert r.src_name == src
      assert r.dst_name == dst
    end

    test "wildcard" do
      src = "refs/heads/master"
      dst = "refs/remotes/origin/master"

      a = RefSpec.from_string("refs/heads/*:refs/remotes/origin/*")
      r = RefSpec.expand_from_source(a, src)

      refute a == r
      refute RefSpec.wildcard?(r)
      assert r.src_name == src
      assert r.dst_name == dst
    end
  end

  describe "expand_from_destination/2" do
    test "non-wildcard" do
      src = "refs/heads/master"
      dst = "refs/remotes/origin/master"

      a = RefSpec.from_string("#{src}:#{dst}")
      r = RefSpec.expand_from_destination(a, dst)

      assert a == r
      refute RefSpec.wildcard?(r)
      assert r.src_name == src
      assert r.dst_name == dst
    end

    test "wildcard" do
      src = "refs/heads/master"
      dst = "refs/remotes/origin/master"

      a = RefSpec.from_string("refs/heads/*:refs/remotes/origin/*")
      r = RefSpec.expand_from_destination(a, dst)

      refute a == r
      refute RefSpec.wildcard?(r)
      assert r.src_name == src
      assert r.dst_name == dst
    end
  end

  test "wildcard?/1 should work for wildcard suffix and component" do
    assert RefSpec.wildcard?("refs/heads/*")
    assert RefSpec.wildcard?("refs/pull/*/head")
    refute RefSpec.wildcard?("refs/heads/a")
  end

  test "wildcard expansion in middle of source" do
    a = RefSpec.from_string("+refs/pull/*/head:refs/remotes/origin/pr/*")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_source?(a, "refs/pull/a/head")
    assert RefSpec.match_source?(a, "refs/pull/foo/head")
    refute RefSpec.match_source?(a, "refs/pull/foo")
    refute RefSpec.match_source?(a, "refs/pull/head")
    refute RefSpec.match_source?(a, "refs/pull/foo/head/more")
    refute RefSpec.match_source?(a, "refs/pullx/head")

    b = RefSpec.expand_from_source(a, "refs/pull/foo/head")
    assert b.dst_name == "refs/remotes/origin/pr/foo"

    c = RefSpec.expand_from_destination(a, "refs/remotes/origin/pr/foo")
    assert c.src_name == "refs/pull/foo/head"
  end

  test "wildcard expansion in middle of destination" do
    a = RefSpec.from_string("+refs/heads/*:refs/remotes/origin/*/head")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_destination?(a, "refs/remotes/origin/a/head")
    assert RefSpec.match_destination?(a, "refs/remotes/origin/foo/head")
    assert RefSpec.match_destination?(a, "refs/remotes/origin/foo/bar/head")
    refute RefSpec.match_destination?(a, "refs/remotes/origin/foo")
    refute RefSpec.match_destination?(a, "refs/remotes/origin/head")
    refute RefSpec.match_destination?(a, "refs/remotes/origin/foo/head/more")
    refute RefSpec.match_destination?(a, "refs/remotes/originx/head")

    b = RefSpec.expand_from_source(a, "refs/heads/foo")
    assert b.dst_name == "refs/remotes/origin/foo/head"

    c = RefSpec.expand_from_destination(a, "refs/remotes/origin/foo/head")
    assert c.src_name == "refs/heads/foo"
  end

  test "wildcard after text 1" do
    a = RefSpec.from_string("refs/heads/*/for-linus:refs/remotes/mine/*-blah")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_destination?(a, "refs/remotes/mine/x-blah")
    assert RefSpec.match_destination?(a, "refs/remotes/mine/foo-blah")
    assert RefSpec.match_destination?(a, "refs/remotes/mine/foo/x-blah")
    refute RefSpec.match_destination?(a, "refs/remotes/origin/foo/x-blah")

    b = RefSpec.expand_from_source(a, "refs/heads/foo/for-linus")
    assert b.dst_name == "refs/remotes/mine/foo-blah"

    c = RefSpec.expand_from_destination(a, "refs/remotes/mine/foo-blah")
    assert c.src_name == "refs/heads/foo/for-linus"
  end

  test "wildcard after text 2" do
    a = RefSpec.from_string("refs/heads*/for-linus:refs/remotes/mine/*")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_source?(a, "refs/headsx/for-linus")
    assert RefSpec.match_source?(a, "refs/headsfoo/for-linus")
    assert RefSpec.match_source?(a, "refs/headsx/foo/for-linus")
    refute RefSpec.match_source?(a, "refs/headx/for-linus")

    b = RefSpec.expand_from_source(a, "refs/headsx/for-linus")
    assert b.dst_name == "refs/remotes/mine/x"

    c = RefSpec.expand_from_destination(a, "refs/remotes/mine/x")
    assert c.src_name == "refs/headsx/for-linus"

    d = RefSpec.expand_from_source(a, "refs/headsx/foo/for-linus")
    assert d.dst_name == "refs/remotes/mine/x/foo"

    e = RefSpec.expand_from_destination(a, "refs/remotes/mine/x/foo")
    assert e.src_name == "refs/headsx/foo/for-linus"
  end

  test "wildcard mirror" do
    a = RefSpec.from_string("*:*")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_source?(a, "a")
    assert RefSpec.match_source?(a, "foo")
    assert RefSpec.match_source?(a, "foo/bar")

    assert RefSpec.match_destination?(a, "a")
    assert RefSpec.match_destination?(a, "foo")
    assert RefSpec.match_destination?(a, "foo/bar")

    b = RefSpec.expand_from_source(a, "refs/heads/foo")
    assert b.dst_name == "refs/heads/foo"

    c = RefSpec.expand_from_source(a, "refs/heads/foo")
    assert c.src_name == "refs/heads/foo"
  end

  test "wildcards at start" do
    a = RefSpec.from_string("*/head:refs/heads/*")
    assert RefSpec.wildcard?(a)

    assert RefSpec.match_source?(a, "a/head")
    assert RefSpec.match_source?(a, "foo/head")
    assert RefSpec.match_source?(a, "foo/bar/head")
    refute RefSpec.match_source?(a, "/head")
    refute RefSpec.match_source?(a, "a/head/extra")

    b = RefSpec.expand_from_source(a, "foo/head")
    assert b.dst_name == "refs/heads/foo"

    c = RefSpec.expand_from_destination(a, "refs/heads/foo")
    assert c.src_name == "foo/head"
  end

  describe "from_string/1 raises error" do
    test "when source ends with slash" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/") end
    end

    test "when destination ends with slash" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/master:refs/heads/") end
    end

    test "when source only and wildcard" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/*") end
    end

    test "when destination only and wildcard" do
      assert_raise ArgumentError, fn -> RefSpec.from_string(":refs/heads/*") end
    end

    test "when only source wildcard" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/*:refs/heads/foo") end
    end

    test "when only destination wildcard" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/foo:refs/heads/*") end
    end

    test "when more than one wildcard in source" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/*/*:refs/heads/*") end
    end

    test "when more than one wildcard in destination" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads/*:refs/heads/*/*") end
    end

    test "when invalid double slashes in source" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("refs/heads//wrong") end
    end

    test "when invalid slash at start of source" do
      assert_raise ArgumentError, fn -> RefSpec.from_string("/foo:/foo") end
    end

    test "when invalid double slashes in destination" do
      assert_raise ArgumentError, fn -> RefSpec.from_string(":refs/heads//wrong") end
    end
  end

  test "replace_source/2 raises when invalid" do
    a = RefSpec.from_string("refs/heads/*:refs/remotes/origin/*")
    assert_raise ArgumentError, fn -> RefSpec.replace_source(a, "refs/heads/*/*") end
  end

  test "replace_destination/2 raises when invalid" do
    a = RefSpec.from_string("refs/heads/*:refs/remotes/origin/*")

    assert_raise ArgumentError, fn ->
      RefSpec.replace_destination(a, "refs/remotes/origin/*/*")
    end
  end

  describe "from_string/2 allow_mismatched_wildcards? option" do
    test "source only has wildcard" do
      a = RefSpec.from_string("refs/heads/*", allow_mismatched_wildcards?: true)
      assert RefSpec.match_source?(a, "refs/heads/master")
      assert a.dst_name == nil
    end

    test "destination with wildcard" do
      a = RefSpec.from_string("refs/heads/master:refs/heads/*", allow_mismatched_wildcards?: true)
      assert RefSpec.match_source?(a, "refs/heads/master")
      assert RefSpec.match_destination?(a, "refs/heads/master")
      assert RefSpec.match_destination?(a, "refs/heads/foo")
    end

    test "only wildcard" do
      a = RefSpec.from_string("*", allow_mismatched_wildcards?: true)
      assert RefSpec.match_source?(a, "refs/heads/master")
      assert a.dst_name == nil
    end
  end
end
