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

defmodule Xgit.Lib.FileModeTest do
  use ExUnit.Case, async: true

  alias Xgit.Lib.FileMode

  doctest Xgit.Lib.FileMode

  test "tree/0" do
    assert %FileMode{mode_bits: 0o040000, object_type: 2, octal_bytes: '40000'} =
             tree = FileMode.tree()

    assert FileMode.match_mode_bits?(tree, 0o040000)
    refute FileMode.match_mode_bits?(tree, 0o100755)

    assert to_string(tree) == "40000"
  end

  test "symlink/0" do
    assert %FileMode{mode_bits: 0o120000, object_type: 3, octal_bytes: '120000'} =
             symlink = FileMode.symlink()

    assert FileMode.match_mode_bits?(symlink, 0o120000)
    refute FileMode.match_mode_bits?(symlink, 0o100755)

    assert to_string(symlink) == "120000"
  end

  test "regular_file/0" do
    assert %FileMode{mode_bits: 0o100644, object_type: 3, octal_bytes: '100644'} =
             regular_file = FileMode.regular_file()

    assert FileMode.match_mode_bits?(regular_file, 0o100644)
    refute FileMode.match_mode_bits?(regular_file, 0o100755)

    assert to_string(regular_file) == "100644"
  end

  test "executable_file/0" do
    assert %FileMode{mode_bits: 0o100755, object_type: 3, octal_bytes: '100755'} =
             executable_file = FileMode.executable_file()

    assert FileMode.match_mode_bits?(executable_file, 0o100755)
    refute FileMode.match_mode_bits?(executable_file, 0o100644)

    assert to_string(executable_file) == "100755"
  end

  test "gitlink/0" do
    assert %FileMode{mode_bits: 0o160000, object_type: 1, octal_bytes: '160000'} =
             gitlink = FileMode.gitlink()

    assert FileMode.match_mode_bits?(gitlink, 0o160000)
    refute FileMode.match_mode_bits?(gitlink, 0o100644)

    assert to_string(gitlink) == "160000"
  end

  test "missing/0" do
    assert %FileMode{mode_bits: 0, object_type: -1, octal_bytes: '0'} =
             missing = FileMode.missing()

    assert FileMode.match_mode_bits?(missing, 0)
    refute FileMode.match_mode_bits?(missing, 0o100644)

    assert to_string(missing) == "0"
  end

  test "from_bits/1" do
    assert FileMode.from_bits(0) == FileMode.missing()
    assert FileMode.from_bits(0o040000) == FileMode.tree()
    assert FileMode.from_bits(0o100755) == FileMode.executable_file()
    assert FileMode.from_bits(0o100645) == FileMode.executable_file()
    assert FileMode.from_bits(0o100644) == FileMode.regular_file()
    assert FileMode.from_bits(0o100600) == FileMode.regular_file()
    assert FileMode.from_bits(0o120000) == FileMode.symlink()
    assert FileMode.from_bits(0o160000) == FileMode.gitlink()

    assert FileMode.from_bits(0o140000) == %FileMode{
             mode_bits: 0o140000,
             object_type: -1,
             octal_bytes: '140000'
           }
  end
end
