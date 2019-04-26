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

defmodule Xgit.Lib.ConfigLineTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.ConfigLine

  doctest Xgit.Lib.ConfigLine

  test "match_section?/3" do
    assert ConfigLine.match_section?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo"},
             "sec",
             "sub"
           )

    assert ConfigLine.match_section?(
             %ConfigLine{section: "sec", subsection: "sub", name: "foo", value: "val"},
             "sec",
             "sub"
           )

    assert ConfigLine.match_section?(
             %ConfigLine{section: "Sec", subsection: "sub", name: "foo"},
             "sec",
             "sub"
           )

    refute ConfigLine.match_section?(
             %ConfigLine{section: "sec", subsection: "sUb", name: "foo"},
             "sec",
             "sub"
           )

    assert ConfigLine.match_section?(
             %ConfigLine{section: "sec", subsection: "sub", name: "Foo"},
             "sec",
             "sub"
           )

    refute ConfigLine.match_section?(
             %ConfigLine{subsection: "sub", name: "foo"},
             "sec",
             "sub"
           )

    refute ConfigLine.match_section?(
             %ConfigLine{section: "sec", name: "foo"},
             "sec",
             "sub"
           )

    assert ConfigLine.match_section?(
             %ConfigLine{section: "sec", subsection: "sub"},
             "sec",
             "sub"
           )
  end

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
    assert to_string(%ConfigLine{}) == "<empty>"

    assert to_string(%ConfigLine{section: "foo"}) == "foo"

    assert to_string(%ConfigLine{section: "foo", subsection: "bar"}) == "foo.bar"

    assert to_string(%ConfigLine{section: "foo", name: "joe"}) == "foo.joe"

    assert to_string(%ConfigLine{section: "foo", subsection: "bar", name: "bob"}) ==
             "foo.bar.bob"

    assert to_string(%ConfigLine{section: "foo", value: "abc"}) == "foo=abc"

    assert to_string(%ConfigLine{section: "foo", subsection: "bar", value: "abc"}) ==
             "foo.bar=abc"

    assert to_string(%ConfigLine{section: "foo", name: "joe", value: "abc"}) ==
             "foo.joe=abc"

    assert to_string(%ConfigLine{
             section: "foo",
             subsection: "bar",
             name: "bob",
             value: "abc"
           }) == "foo.bar.bob=abc"
  end
end
