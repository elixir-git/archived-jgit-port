# Copyright (C) 2008-2009, Google Inc.
# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2007-2009, Robin Rosenberg <robin.rosenberg@dewire.com>
# Copyright (C) 2006-2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/PackIndexV1.java
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

defmodule Xgit.Internal.Storage.File.PackIndexV1 do
  @moduledoc false

  @enforce_keys [:idx_header, :idx_data, :object_count, :pack_checksum]
  defstruct [:idx_header, :idx_data, :object_count, :pack_checksum]

  alias Xgit.Internal.Storage.File.PackIndex.Reader
  alias Xgit.Lib.Constants
  alias Xgit.Util.NB

  @index_header_length 1024

  def parse(file_pid, header) when is_pid(file_pid) and is_list(header) do
    fanout_table_suffix = IO.read(file_pid, @index_header_length - length(header))
    fanout_table = header ++ fanout_table_suffix

    idx_header = idx_header_from_fanout_table(fanout_table, [])
    {idx_data, object_count} = Enum.map_reduce(idx_header, 0, &read_index_data(&1, &2, file_pid))
    pack_checksum = IO.read(file_pid, 20)

    %__MODULE__{
      idx_header: List.to_tuple(idx_header),
      idx_data: idx_data,
      object_count: object_count,
      pack_checksum: pack_checksum
    }
  end

  defp idx_header_from_fanout_table([], acc), do: Enum.reverse(acc)

  defp idx_header_from_fanout_table([_a, _b, _c, _d | _tail] = fanout_table, acc) do
    {value, tail} = NB.decode_uint32(fanout_table)
    idx_header_from_fanout_table(tail, [value | acc])
  end

  defp read_index_data(acc = _item, acc, _file_pid), do: {[], acc}

  defp read_index_data(item, acc, file_pid) do
    bytes_to_read = (item - acc) * (Constants.object_id_length() + 4)
    # TO DO: Enforce safety limit for size of index array?
    # throw new IOException(JGitText.get().indexFileIsTooLargeForJgit);

    {IO.read(file_pid, bytes_to_read), item}
  end

  # /** {@inheritDoc} */
  # @Override
  # public ObjectId getObjectId(long nthPosition) {
  # 	final int levelOne = findLevelOne(nthPosition);
  # 	final int p = getLevelTwo(nthPosition, levelOne);
  # 	final int dataIdx = idOffset(p);
  # 	return ObjectId.fromRaw(idxdata[levelOne], dataIdx);
  # }

  # /** {@inheritDoc} */
  # @Override
  # public long findOffset(AnyObjectId objId) {
  #   final int levelOne = objId.getFirstByte();
  #   byte[] data = idxdata[levelOne];
  #   if (data == null)
  #     return -1;
  #   int high = data.length / (4 + Constants.OBJECT_ID_LENGTH);
  #   int low = 0;
  #   do {
  #     final int mid = (low + high) >>> 1;
  #     final int pos = idOffset(mid);
  #     final int cmp = objId.compareTo(data, pos);
  #     if (cmp < 0)
  #       high = mid;
  #     else if (cmp == 0) {
  #       int b0 = data[pos - 4] & 0xff;
  #       int b1 = data[pos - 3] & 0xff;
  #       int b2 = data[pos - 2] & 0xff;
  #       int b3 = data[pos - 1] & 0xff;
  #       return (((long) b0) << 24) | (b1 << 16) | (b2 << 8) | (b3);
  #     } else
  #       low = mid + 1;
  #   } while (low < high);
  #   return -1;
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public void resolve(Set<ObjectId> matches, AbbreviatedObjectId id,
  #     int matchLimit) throws IOException {
  #   byte[] data = idxdata[id.getFirstByte()];
  #   if (data == null)
  #     return;
  #   int max = data.length / (4 + Constants.OBJECT_ID_LENGTH);
  #   int high = max;
  #   int low = 0;
  #   do {
  #     int p = (low + high) >>> 1;
  #     final int cmp = id.prefixCompare(data, idOffset(p));
  #     if (cmp < 0)
  #       high = p;
  #     else if (cmp == 0) {
  #       // We may have landed in the middle of the matches.  Move
  #       // backwards to the start of matches, then walk forwards.
  #       //
  #       while (0 < p && id.prefixCompare(data, idOffset(p - 1)) == 0)
  #         p--;
  #       for (; p < max && id.prefixCompare(data, idOffset(p)) == 0; p++) {
  #         matches.add(ObjectId.fromRaw(data, idOffset(p)));
  #         if (matches.size() > matchLimit)
  #           break;
  #       }
  #       return;
  #     } else
  #       low = p + 1;
  #   } while (low < high);
  # }
  #
  # private static int idOffset(int mid) {
  #   return ((4 + Constants.OBJECT_ID_LENGTH) * mid) + 4;
  # }

  defimpl Enumerable do
    alias Xgit.Internal.Storage.File.PackIndex.Entry
    alias Xgit.Internal.Storage.File.PackIndexV1
    alias Xgit.Lib.ObjectId

    def count(_), do: {:error, PackIndexV1}
    def member?(_, _), do: {:error, PackIndexV1}
    def slice(_), do: {:error, PackIndexV1}

    def reduce(%PackIndexV1{idx_data: idx_data}, acc, fun) when is_list(idx_data),
      do: reduce(idx_data, [], acc, fun)

    defp reduce(level1, level2, acc, fun)

    defp reduce(_level1, _leve2, {:halt, acc}, _fun), do: {:halted, acc}

    # TO DO: Restore this case if we find that we actually use suspended enumerations.
    # For now, I don't see a use case for it.
    # defp reduce(level1, level2, {:suspend, acc}, fun),
    #   do: {:suspended, acc, &reduce(level1, level2, &1, fun)}

    defp reduce([] = _level1, [] = _level2, {:cont, acc}, _fun), do: {:done, acc}

    defp reduce([l1_head | l1_tail], [] = _level2, {:cont, _} = acc, fun),
      do: reduce(l1_tail, l1_head, acc, fun)

    defp reduce(level1, level2, {:cont, acc}, fun) do
      entry = %Entry{
        name: level2 |> Enum.drop(4) |> ObjectId.from_raw_bytes(),
        offset: level2 |> NB.decode_uint32() |> elem(0)
      }

      reduce(level1, Enum.drop(level2, Constants.object_id_length() + 4), fun.(entry, acc), fun)
    end
  end

  defimpl Reader do
    alias Xgit.Errors.UnsupportedOperationError
    alias Xgit.Lib.ObjectId
    alias Xgit.Util.TupleUtils

    @impl true
    def get_object_id_at_index(%{idx_header: idx_header, idx_data: idx_data}, nth_position) do
      level_one =
        idx_header
        |> find_level_one(nth_position)

      level_one
      |> find_level_two(idx_header, nth_position)
      |> read_object_id_at_index(level_one, idx_data)
    end

    @impl true
    def get_offset_at_index(%{idx_header: idx_header, idx_data: idx_data}, nth_position) do
      level_one =
        idx_header
        |> find_level_one(nth_position)

      level_one
      |> find_level_two(idx_header, nth_position)
      |> read_offset_at_index(level_one, idx_data)
    end

    defp find_level_one(idx_header, nth_position) do
      idx_header
      |> TupleUtils.binary_search(nth_position + 1)
      |> to_level_one_bucket(idx_header)
    end

    defp to_level_one_bucket(level_one, _idx_header) when level_one < 0,
      do: -(level_one + 1)

    defp to_level_one_bucket(0, _idx_header), do: 0

    defp to_level_one_bucket(level_one, idx_header) do
      if elem(idx_header, level_one) == elem(idx_header, level_one - 1) do
        to_level_one_bucket(level_one - 1, idx_header)
      else
        level_one
      end
    end

    defp find_level_two(level_one, idx_header, nth_position) do
      base =
        if level_one > 0 do
          elem(idx_header, level_one - 1)
        else
          0
        end

      nth_position - base
    end

    defp read_offset_at_index(level_two, level_one, idx_data) do
      byte_offset = level_two * (4 + Constants.object_id_length())

      idx_data
      |> Enum.at(level_one)
      |> Enum.drop(byte_offset)
      |> NB.decode_uint32()
      |> elem(0)
    end

    defp read_object_id_at_index(level_two, level_one, idx_data) do
      byte_offset = level_two * (4 + Constants.object_id_length()) + 4

      idx_data
      |> Enum.at(level_one)
      |> Enum.drop(byte_offset)
      |> ObjectId.from_raw_bytes()
    end

    @impl true
    def crc32_checksum_for_object(_index, _object_id) do
      raise UnsupportedOperationError,
        message: "CRC32 checksums not available for V1 pack index."
    end

    @impl true
    def has_crc32_support?(_index), do: false
  end
end
