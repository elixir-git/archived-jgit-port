# Copyright (C) 2007, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/FileMode.java
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

defmodule Xgit.Lib.FileMode do
  @moduledoc ~S"""
  Describes the various file modes recognized by git.

  git uses a subset of the available Unix file permission bits. This module
  provides access to constants defining the modes actually used by git.
  """

  @typedoc ~S"""
  Retains information about a given git file mode.

  ## Struct Members

  * `:mode_bits`: (integer) the actual file mode
  * `:object_type`: (integer) the file type (as an `obj_*` value from `Xgit.Lib.Constants`)
  * `:octal_bytes`: (charlist) `:mode_bits` rendered as an octal value
  """
  @type t :: %__MODULE__{
          mode_bits: non_neg_integer,
          object_type: Xgit.Lib.Constants.obj_type(),
          octal_bytes: charlist
        }

  @enforce_keys [:mode_bits, :object_type, :octal_bytes]
  defstruct [:mode_bits, :object_type, :octal_bytes]

  use Bitwise, skip_operators: true

  alias Xgit.Lib.Constants

  @doc "Mask to apply to a file mode to obtain its type bits."
  @spec type_mask :: integer
  def type_mask, do: 0o170000

  @doc "Bit pattern for `type_mask/0` matching `tree/0`."
  @spec type_tree :: integer
  def type_tree, do: 0o040000

  @doc "Bit pattern for `type_mask/0` matching `symlink/0`."
  @spec type_symlink :: integer
  def type_symlink, do: 0o120000

  @doc "Bit pattern for `type_mask/0` matching `regular_file/0`."
  @spec type_file :: integer
  def type_file, do: 0o100000

  @doc "Bit pattern for `type_mask/0` matching `gitlink/0`."
  @spec type_gitlink :: integer
  def type_gitlink, do: 0o160000

  @doc "Bit pattern for `type_mask/0` matching `missing/0`."
  @spec type_missing :: integer
  def type_missing, do: 0o000000

  @doc "Mode indicating an entry is a tree (aka directory)."
  @spec tree :: t
  def tree, do: new(type_tree(), Constants.obj_tree())

  @doc "Mode indicating an entry is a symbolic link."
  @spec symlink :: t
  def symlink, do: new(type_symlink(), Constants.obj_blob())

  @doc "Mode indicating an entry is a non-executable file."
  @spec regular_file :: t
  def regular_file, do: new(0o100644, Constants.obj_blob())

  @doc "Mode indicating an entry is an executable file."
  @spec executable_file :: t
  def executable_file, do: new(0o100755, Constants.obj_blob())

  @doc "Mode indicating an entry is a submodule commit in another repository."
  @spec gitlink :: t
  def gitlink, do: new(type_gitlink(), Constants.obj_commit())

  @doc "Mode indicating an entry is missing during parallel walks."
  @spec missing :: t
  def missing, do: new(type_missing(), Constants.obj_bad())

  @doc ~S"""
  Return `true` if the `Xgit.Lib.FileMode` struct matches the file mode value.
  """
  @spec match_mode_bits?(file_mode :: t, mode_bits :: integer) :: boolean
  def match_mode_bits?(file_mode, mode_bits)

  def match_mode_bits?(%__MODULE__{mode_bits: 0o100644}, mode_bits),
    do: band(mode_bits, type_mask()) == type_file() && band(mode_bits, 0o111) == 0

  def match_mode_bits?(%__MODULE__{mode_bits: 0o100755}, mode_bits),
    do: band(mode_bits, type_mask()) == type_file() && band(mode_bits, 0o111) != 0

  def match_mode_bits?(%__MODULE__{mode_bits: 0o000000}, mode_bits),
    do: mode_bits == 0

  def match_mode_bits?(%__MODULE__{mode_bits: self_mode_bits}, other_mode_bits),
    do: self_mode_bits == other_mode_bits

  @doc ~S"""
  Convert a set of mode bits into an `Xgit.Lib.FileMode` enumerated value.
  """
  @spec from_bits(mode_bits :: integer) :: t
  def from_bits(bits), do: bits |> band(type_mask()) |> from_type_bits(bits)

  defp from_type_bits(0o000000, 0), do: missing()
  defp from_type_bits(0o040000, _), do: tree()
  defp from_type_bits(0o100000, bits) when band(bits, 0o111) != 0, do: executable_file()
  defp from_type_bits(0o100000, _), do: regular_file()
  defp from_type_bits(0o120000, _), do: symlink()
  defp from_type_bits(0o160000, _), do: gitlink()
  defp from_type_bits(_, bits), do: new(bits, Constants.obj_bad())

  defp new(mode, object_type) do
    %__MODULE__{
      mode_bits: mode,
      object_type: object_type,
      octal_bytes: octal_bytes_from_mode(mode)
    }
  end

  defp octal_bytes_from_mode(0), do: '0'
  defp octal_bytes_from_mode(mode), do: octal_bytes_from_mode(mode, [])

  defp octal_bytes_from_mode(0, bytes), do: bytes

  defp octal_bytes_from_mode(mode, bytes),
    do: octal_bytes_from_mode(bsr(mode, 3), [band(mode, 0x7) + ?0 | bytes])

  defimpl String.Chars do
    def to_string(%Xgit.Lib.FileMode{octal_bytes: octal_bytes}), do: Kernel.to_string(octal_bytes)
  end
end
