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

defmodule Xgit.Util.CompressedBitmap do
  @moduledoc ~S"""
  Compressed bitmap similar to Java's BitSet class.

  Placeholder implementation for now based on Elixir's MapSet.

  Hopefully eventually replaced with something as efficient
  as com.googlecode.javaewah.EWAHCompressedBitmap.

  Unlike traditional `MapSet`, values must be non-negative integers.

  Consider replacing with:

  * https://github.com/zambal/rb_sets
  * https://github.com/gausby/bit_field_set
  """
  defstruct mapset: nil, max: 0

  @doc """
  Returns a new set.
  """
  def new(), do: %__MODULE__{mapset: MapSet.new()}

  @doc """
  Creates a new set from an enumerable.
  """
  def new(enumerable)

  def new(%__MODULE__{} = bitmap), do: bitmap

  def new(enumerable) do
    unless Enum.all?(enumerable, &valid?/1) do
      raise ArgumentError, "All values must be non-negative integers"
    end

    %__MODULE__{max: Enum.max(enumerable), mapset: MapSet.new(enumerable)}
  end

  defp valid?(value), do: is_integer(value) and value >= 0

  @doc """
  Inserts `value` into `bitmap` if `bitmap` doesn't already contain it.
  """
  def put(%__MODULE__{max: max_v, mapset: mapset} = bitmap, value)
      when is_integer(value) and value >= 0,
      do: %{bitmap | max: max(max_v, value), mapset: MapSet.put(mapset, value)}

  @doc """
  Removes `value` from `bitmap` if `bitmap` already contains it. (No-op otherwise.)
  """
  def delete(%__MODULE__{mapset: mapset} = bitmap, value) when is_integer(value) and value >= 0,
    do: %{bitmap | mapset: MapSet.delete(mapset, value)}

  @doc """
  Returns the bitwise OR of the two bitmaps.
  """
  def union(%__MODULE__{max: max1, mapset: mapset1}, %__MODULE__{max: max2, mapset: mapset2}),
    do: %__MODULE__{max: max(max1, max2), mapset: MapSet.union(mapset1, mapset2)}

  @doc """
  Returns the bitwise AND of the two bitmaps.
  """
  def intersection(%__MODULE__{max: max1, mapset: mapset1}, %__MODULE__{
        max: max2,
        mapset: mapset2
      }),
      do: %__MODULE__{max: max(max1, max2), mapset: MapSet.intersection(mapset1, mapset2)}

  @doc """
  Returns the bitwise XOR of the two bitmaps.
  """
  def xor(%__MODULE__{max: max1, mapset: mapset1}, %__MODULE__{max: max2, mapset: mapset2}) do
    union = MapSet.union(mapset1, mapset2)
    intersection = MapSet.intersection(mapset1, mapset2)

    %__MODULE__{max: max(max1, max2), mapset: MapSet.difference(union, intersection)}
  end

  @doc """
  Returns the bitwise NOT of the bitmap.
  """
  def not (%__MODULE__{max: max} = mapset) do
    # TO DO: Replace with a more efficient implementation.

    0..max
    |> new()
    |> xor(mapset)
  end

  @doc """
  Returns the bitwise AND NOT of the two bitmaps.
  """
  def and_not(%__MODULE__{} = bitmap1, %__MODULE__{} = bitmap2) do
    bitmap2
    |> __MODULE__.not()
    |> __MODULE__.intersection(bitmap1)
  end

  # TO DO: Serialize / deserialize.

  defimpl Enumerable do
    alias Xgit.Util.CompressedBitmap

    def count(%CompressedBitmap{mapset: mapset}), do: {:ok, MapSet.size(mapset)}

    def member?(%CompressedBitmap{mapset: mapset}, value),
      do: {:ok, MapSet.member?(mapset, value)}

    def slice(%CompressedBitmap{mapset: mapset}),
      do: {:ok, MapSet.size(mapset), &Enumerable.List.slice(MapSet.to_list(mapset), &1, &2)}

    def reduce(%CompressedBitmap{mapset: mapset}, acc, fun),
      do: Enumerable.List.reduce(MapSet.to_list(mapset), acc, fun)
  end

  # defimpl Collectable do
  #   def into(%__MODULE__{mapset: mapset}) do
  #     fun = fn
  #       list, {:cont, x} -> [{x, []} | list]
  #       list, :done -> %{map_set | map: Map.merge(map_set.map, Map.new(list))}
  #       _, :halt -> :ok
  #     end
  #
  #     {[], fun}
  #   end
  # end
end
