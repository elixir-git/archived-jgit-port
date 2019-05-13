# Copyright (C) 2008, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectId.java
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

defmodule Xgit.Lib.ObjectId do
  @moduledoc ~S"""
  An object ID is a string that matches the format for a SHA-1 hash.

  PORTING NOTE: Compared to jgit's ObjectID, we do not implement a separate data
  type. Instead an ObjectID is simply an Elixir string. In this module, we provide
  mechanisms for manipulating and validating such strings.
  """

  alias Xgit.Lib.Constants

  @type t :: String.t()

  @doc ~S"""
  Get the special all-null ObjectId, often used to stand-in for no object.
  """
  def zero, do: "0000000000000000000000000000000000000000"

  @doc ~S"""
  Return true if the string or charlist is a valid ObjectID. (In other words,
  is it 40 characters of lowercase hex?)
  """
  def valid?(s) when is_binary(s), do: String.length(s) == 40 && String.match?(s, ~r/^[0-9a-f]+$/)
  def valid?(b) when is_list(b), do: Enum.count(b) == 40 && Enum.all?(b, &valid_hex_digit?/1)
  def valid?(nil), do: false

  defp valid_hex_digit?(c), do: (c >= ?0 && c <= ?9) || (c >= ?a && c <= ?f)

  @doc ~S"""
  Read a raw ObjectID from a byte list.

  Ignores any content in the byte list beyond the first 20 bytes.
  """
  def from_raw_bytes(b) when length(b) >= 20 do
    b
    |> Enum.take(20)
    |> :erlang.list_to_binary()
    |> Base.encode16(case: :lower)
  end

  @doc ~S"""
  Convert a ObjectID to a raw byte list.
  """
  def to_raw_bytes(<<id::binary-size(40)>>) do
    id
    |> Base.decode16!(case: :lower)
    |> :erlang.binary_to_list()
  end

  @doc ~S"""
  Read an ObjectID from a hex string (charlist).

  If a valid ID is found, returns `{id, next}` where `id` is the matched ID string
  and `next` is the remainder of the charlist after the matched ID.

  If no such ID is found, returns `false`.
  """
  def from_hex_charlist(b) when is_list(b) do
    {maybe_id, remainder} = Enum.split(b, 40)

    if valid?(maybe_id),
      do: {maybe_id, remainder},
      else: false
  end

  @doc ~S"""
  Compute the git "name" of an object.

  `obj_type` is the type of the object. Must be one of the `obj_*()` values from
  `Xgit.Lib.Constants`.
  """
  def id_for(obj_type, data) when is_integer(obj_type) and is_list(data) do
    # FYI :sha in Erlang parlance == SHA-1.

    :sha
    |> :crypto.hash_init()
    |> :crypto.hash_update(Constants.encoded_type_string(obj_type))
    |> :crypto.hash_update(' ')
    |> :crypto.hash_update('#{Enum.count(data)}')
    |> :crypto.hash_update([0])
    |> :crypto.hash_update(data)
    |> :crypto.hash_final()
    |> Base.encode16()
    |> String.downcase()
  end
end
