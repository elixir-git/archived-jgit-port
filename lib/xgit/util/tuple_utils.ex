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

defmodule Xgit.Util.TupleUtils do
  @moduledoc ~S"""
  Some utilities for working with Elixir tuples.
  """

  @doc ~S"""
  Binary-search a tuple (which must be sorted) for a specific value.

  This function returns the index of the specified value if it is contained in the tuple.
  If the value does not exist in the tuple, it returns `-(insertion point + 1)`.

  The insertion point is defined as the point at which the value would be inserted
  into the tuple; in other words, the index of the first element in the tuple
  greater than the key, or `tuple_size(tuple)` if all elements in the tuple are
  less than the specified key.

  This function is intended to match the semantics of Java's `Arrays.binarySearch`
  method.
  """
  @spec binary_search(tuple :: tuple, value :: term) :: integer
  def binary_search(tuple, value) when is_tuple(tuple),
    do: binary_search(tuple, value, 0, tuple_size(tuple))

  defp binary_search({}, _value, _min_index, _max_index), do: -1

  defp binary_search(_tuple, _value, index, index), do: -(index + 1)

  defp binary_search(tuple, value, min_index, max_index) when max_index > min_index do
    mid_index = div(min_index + max_index, 2)

    case elem(tuple, mid_index) do
      ^value -> mid_index
      x when x > value -> binary_search(tuple, value, min_index, mid_index)
      x when x < value -> binary_search(tuple, value, mid_index + 1, max_index)
    end
  end
end
