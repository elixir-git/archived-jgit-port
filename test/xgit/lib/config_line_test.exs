defmodule Xgit.Lib.ConfigLineTest do
  use ExUnit.Case

  alias Xgit.Lib.ConfigLine
  doctest Xgit.Lib.ConfigLine

  test "match?/3" do
    assert ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo"},
             "sec",
             "sub",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo", value: "val"},
             "sec",
             "sub",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "Sec", subsection: "sub", name: "foo"},
             "sec",
             "sub",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sUb", name: "foo"},
             "sec",
             "sub",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub", name: "Foo"},
             "sec",
             "sub",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{subsection: "sub", name: "foo"},
             "sec",
             "sub",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{section: "sec", name: "foo"},
             "sec",
             "sub",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub"},
             "sec",
             "sub",
             "foo"
           )
  end

  test "match?/2" do
    assert ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo"},
             "sec",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "sec", name: "foo"},
             "sec",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo", value: "val"},
             "sec",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "Sec", subsection: "sub", name: "foo"},
             "sec",
             "foo"
           )

    assert ConfigLine.match?(
             %ConfigLine{section: "sec", name: "Foo"},
             "sec",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{name: "foo"},
             "sec",
             "foo"
           )

    refute ConfigLine.match?(
             %ConfigLine{section: "sec"},
             "sec",
             "foo"
           )
  end

  test "to_string/1" do
    assert ConfigLine.to_string(%ConfigLine{}) == "<empty>"

    assert ConfigLine.to_string(%ConfigLine{section: "foo"}) == "foo"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", subsection: "bar"}) == "foo.bar"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", name: "joe"}) == "foo.joe"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", subsection: "bar", name: "bob"}) ==
             "foo.bar.bob"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", value: "abc"}) == "foo=abc"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", subsection: "bar", value: "abc"}) ==
             "foo.bar=abc"

    assert ConfigLine.to_string(%ConfigLine{section: "foo", name: "joe", value: "abc"}) ==
             "foo.joe=abc"

    assert ConfigLine.to_string(%ConfigLine{
             section: "foo",
             subsection: "bar",
             name: "bob",
             value: "abc"
           }) == "foo.bar.bob=abc"
  end
end
