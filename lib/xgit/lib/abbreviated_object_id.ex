# Copyright (C) 2008-2009, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/AbbreviatedObjectId.java
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

defmodule Xgit.Lib.AbbreviatedObjectId do
  @moduledoc ~S"""
  A prefix abbreviation of an `Xgit.Lib.ObjectId`.

  Sometimes git produces abbreviated SHA-1 strings, using sufficient leading
  digits from the `ObjectId` name to still be unique within the repository the
  string was generated from. These IDs are likely to be unique for a useful
  period of time, especially if they contain at least 6-10 hex digits.
  """

  @type t :: String.t()

  @doc ~S"""
  Return `true` if a string of characters is a valid abbreviated ID.
  """
  @spec valid?(id :: t) :: boolean
  def valid?(id) when is_binary(id) do
    length = String.length(id)
    length >= 2 && length <= 40 && String.match?(id, ~r/^[0-9a-f]+$/)
  end

  @doc ~S"""
  Return `true` if this abbreviated object ID actually a complete ID.
  """
  @spec complete?(id :: t) :: boolean
  def complete?(id) when is_binary(id), do: String.length(id) == 40

  @doc ~S"""
  Compares this abbreviation to a full object ID.

  Returns:
  * `:lt` if the abbreviation `a` names an object that is less than `other`
  * `:eq` if the abbreviation `a` exactly matches the first `length/1` digits of `other`
  * `:gt` if the abbreviation `a` names an object that is after `other`
  """
  @spec prefix_compare(a :: t, other :: t) :: :lt | :eq | :gt
  def prefix_compare(a, other) when is_binary(a) and is_binary(other) do
    if String.starts_with?(other, a),
      do: :eq,
      else: compare_charlists(String.to_charlist(a), String.to_charlist(other))
  end

  defp compare_charlists([c | a], [c | other]), do: compare_charlists(a, other)

  defp compare_charlists([c1 | _], [c2 | _]) when c1 < c2, do: :lt
  defp compare_charlists([c1 | _], [c2 | _]) when c1 > c2, do: :gt

  defp compare_charlists([], _), do: :eq
end
