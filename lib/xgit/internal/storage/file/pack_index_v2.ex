# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/PackIndexV2.java
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

defmodule Xgit.Internal.Storage.File.PackIndexV2 do
  @moduledoc false

  # Struct members:
  #
  # object_count: (integer) number of objects in pack
  #
  # fanout_table: (256-element tuple, each element being an integer)
  #   cumulative number of objects in pack for this fanout
  #
  # names: (256-element tuple, each element being a binary)
  #   object IDs in raw form as one large Erlang binary
  #   IMPORTANT: This is different from jgit, which parses the names into
  #   an array of 32-bit integers (5 for each object ID).
  #
  # crc32: (256-element tuple, each element being a binary)
  #   CRCs are in raw form as one large Erlang binary
  #
  # offset32: (256-element tuple, each element being a binary)
  #   32-bit offsets are in raw form as one large Erlang binary
  #
  # offset64: (binary) a single Erlang binary containing the all of the
  #   64-bit offset values that were bumped out from the 32-bit table
  #
  # pack_checksum: (byte list) 20-byte checksum written after all of the above

  @enforce_keys [
    :object_count,
    :fanout_table,
    :names,
    :crc32,
    :offset32,
    :offset64,
    :pack_checksum
  ]
  defstruct [:object_count, :fanout_table, :names, :crc32, :offset32, :offset64, :pack_checksum]

  alias Xgit.Internal.Storage.File.PackIndex.Reader
  alias Xgit.Lib.Constants
  alias Xgit.Util.NB

  @fanout 256

  def parse(file_pid) when is_pid(file_pid) do
    fanout_table =
      file_pid
      |> IO.read(@fanout * 4)
      |> fanout_table_from_raw_bytes([])

    object_count = List.last(fanout_table)

    names = read_object_name_table(file_pid, fanout_table)

    crc32 = read_crc32s(file_pid, names)

    offset32 = read_offset32s(file_pid, names)

    offset64 = read_offset64s(file_pid, offset32)

    pack_checksum = IO.read(file_pid, 20)

    %__MODULE__{
      object_count: object_count,
      fanout_table: List.to_tuple(fanout_table),
      names: List.to_tuple(names),
      crc32: List.to_tuple(crc32),
      offset32: List.to_tuple(offset32),
      offset64: offset64,
      pack_checksum: pack_checksum
    }
  end

  defp fanout_table_from_raw_bytes([], acc), do: Enum.reverse(acc)

  defp fanout_table_from_raw_bytes([_a, _b, _c, _d | _tail] = raw_fanout, acc) do
    {value, tail} = NB.decode_uint32(raw_fanout)
    fanout_table_from_raw_bytes(tail, [value | acc])
  end

  defp read_object_name_table(file_pid, fanout_table) do
    fanout_table
    |> Enum.reduce({[], file_pid, 0}, &read_one_fanout_bucket/2)
    |> elem(0)
    |> Enum.reverse()
  end

  defp read_one_fanout_bucket(
         new_cumulative_object_count,
         {names, file_pid, previous_cumulative_object_count}
       ) do
    # TO DO: Do we have a limit on fanout-buckets similar to the one in JVM?
    # // Object name table. The size we can permit per fan-out bucket
    # // is limited to Java's 2 GB per byte array limitation. That is
    # // no more than 107,374,182 objects per fan-out.

    bucket_count = new_cumulative_object_count - previous_cumulative_object_count

    {[read_fanout_bucket(bucket_count, file_pid) | names], file_pid, new_cumulative_object_count}
  end

  defp read_fanout_bucket(0, _file_pid), do: ""

  defp read_fanout_bucket(bucket_count, _file_pid) when bucket_count < 0 do
    raise File.Error,
      message: "Invalid negative bucket count read from pack v2 index file: #{bucket_count}"
  end

  defp read_fanout_bucket(bucket_count, file_pid) when is_integer(bucket_count) do
    size_of_object_ids_list = bucket_count * Constants.object_id_length()

    # TO DO: Do we need to enforce this limit?
    # if (nameLen > Integer.MAX_VALUE - 8) // see http://stackoverflow.com/a/8381338
    #   throw new IOException(JGitText.get().indexFileIsTooLargeForJgit);

    file_pid
    |> IO.read(size_of_object_ids_list)
    |> :erlang.list_to_binary()
  end

  defp read_crc32s(file_pid, names) do
    # Tricky piece here: We're using `names` merely to get the number of
    # ObjectIDs that are in this bucket. Easier than doing the delta-based
    # calculation that we did in fanout_table_from_raw_bytes/2 above.

    Enum.map(names, fn names_for_bucket ->
      read_crc32s_for_bucket(names_for_bucket, file_pid)
    end)
  end

  defp read_crc32s_for_bucket("", _file_pid), do: ""

  defp read_crc32s_for_bucket(names, file_pid) do
    size_of_crc32_list = Kernel.div(byte_size(names), 5)

    file_pid
    |> IO.read(size_of_crc32_list)
    |> :erlang.list_to_binary()
  end

  defp read_offset32s(file_pid, names) do
    # Tricky piece here: We're using `names` merely to get the number of
    # ObjectIDs that are in this bucket. Easier than doing the delta-based
    # calculation that we did in fanout_table_from_raw_bytes/2 above.

    Enum.map(names, fn names_for_bucket ->
      read_offset32s_for_bucket(names_for_bucket, file_pid)
    end)
  end

  defp read_offset32s_for_bucket("", _file_pid), do: ""

  defp read_offset32s_for_bucket(names, file_pid) do
    size_of_offset32_list = Kernel.div(byte_size(names), 5)

    file_pid
    |> IO.read(size_of_offset32_list)
    |> :erlang.list_to_binary()
  end

  defp read_offset64s(file_pid, offset32s) do
    # Any entries in the 32-bit offset table with the most significant bit
    # require an entry in the 64-bit offset table. Typically, this will be
    # an empty list.

    offset32s
    |> Enum.reduce(0, &count_64_bit_offsets/2)
    |> read_n_offset_64s(file_pid)
  end

  defp count_64_bit_offsets("", acc), do: acc

  defp count_64_bit_offsets(offset32_bucket, acc) do
    items_in_bucket =
      offset32_bucket
      |> byte_size()
      |> Kernel.div(4)

    acc +
      Enum.reduce(0..(items_in_bucket - 1), 0, fn i, acc ->
        if :binary.at(offset32_bucket, i * 4) >= 128 do
          acc + 1
        else
          acc
        end
      end)
  end

  defp read_n_offset_64s(0, _file_pid), do: ""

  defp read_n_offset_64s(n, file_pid) do
    file_pid
    |> IO.read(n * 8)
    |> :erlang.list_to_binary()
  end

  # public void resolve(Set<ObjectId> matches, AbbreviatedObjectId id,
  #     int matchLimit) throws IOException {
  #   int[] data = names[id.getFirstByte()];
  #   int max = offset32[id.getFirstByte()].length >>> 2;
  #   int high = max;
  #   if (high == 0)
  #     return;
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
  # private static int idOffset(int p) {
  #   return (p << 2) + p; // p * 5
  # }

  defimpl Enumerable do
    alias Xgit.Internal.Storage.File.PackIndex.Entry
    alias Xgit.Internal.Storage.File.PackIndexV2
    alias Xgit.Lib.ObjectId

    def count(_), do: {:error, PackIndexV2}
    def member?(_, _), do: {:error, PackIndexV2}
    def slice(_), do: {:error, PackIndexV2}

    def reduce(%PackIndexV2{} = index, acc, fun), do: reduce(index, 0, 0, acc, fun)

    defp reduce(index, level1_idx, level2_idx, acc, fun)

    defp reduce(_index, _level1_idx, _level2_idx, {:halt, acc}, _fun), do: {:halted, acc}

    # TO DO: Restore this case if we find that we actually use suspended enumerations.
    # For now, I don't see a use case for it.
    # defp reduce(_index, _level1_idx, level2_idx, {:suspend, acc}, fun),
    #   do: {:suspended, acc, &reduce(level1, level2, &1, fun)}

    defp reduce(_index, 256 = _level1_idx, _level2_idx, {:cont, acc}, _fun), do: {:done, acc}

    defp reduce(
           %PackIndexV2{names: names, offset32: offset32} = index,
           level1_index,
           level2_index,
           {:cont, acc},
           fun
         ) do
      # TO DO: A lot of indexing into tuples and binaries here. Improve perf?
      names_bucket = elem(names, level1_index)
      bucket_offset = level2_index * Constants.object_id_length()

      if bucket_offset >= byte_size(names_bucket) do
        reduce(index, level1_index + 1, 0, {:cont, acc}, fun)
      else
        name =
          names_bucket
          |> :binary.bin_to_list(bucket_offset, Constants.object_id_length())
          |> ObjectId.from_raw_bytes()

        offset =
          offset32
          |> elem(level1_index)
          |> :binary.bin_to_list(level2_index * 4, 4)
          |> NB.decode_uint32()
          |> elem(0)

        if offset >= 0x80000000 do
          raise "64-bit offsets not yet supported"

          # if ((offset & IS_O64) != 0) {
          #   idx = (8 * (int) (offset & ~IS_O64));
          #   offset = NB.decodeUInt64(offset64, idx);
          # }
        end

        entry = %Entry{name: name, offset: offset}
        reduce(index, level1_index, level2_index + 1, fun.(entry, acc), fun)
      end
    end
  end

  defimpl Reader do
    alias Xgit.Errors.MissingObjectError
    alias Xgit.Lib.ObjectId
    alias Xgit.Util.TupleUtils

    @impl true
    def get_object_id_at_index(
          %{fanout_table: fanout_table, names: names},
          nth_position
        ) do
      level_one =
        fanout_table
        |> find_level_one(nth_position)

      level_one
      |> find_level_two(fanout_table, nth_position)
      |> read_object_id_at_index(level_one, names)
    end

    defp read_object_id_at_index(level_two, level_one, names) do
      names
      |> elem(level_one)
      |> :binary.bin_to_list(
        level_two * Constants.object_id_length(),
        Constants.object_id_length()
      )
      |> ObjectId.from_raw_bytes()
    end

    @impl true
    def get_offset_at_index(
          %{fanout_table: fanout_table, offset32: offset32, offset64: offset64},
          nth_position
        ) do
      level_one =
        fanout_table
        |> find_level_one(nth_position)

      level_one
      |> find_level_two(fanout_table, nth_position)
      |> read_offset_at_index(level_one, offset32, offset64)
    end

    defp find_level_one(fanout_table, nth_position) do
      fanout_table
      |> TupleUtils.binary_search(nth_position + 1)
      |> to_level_one_bucket(fanout_table)
    end

    defp to_level_one_bucket(level_one, _fanout_table) when level_one < 0,
      do: -(level_one + 1)

    defp to_level_one_bucket(0, _fanout_table), do: 0

    defp to_level_one_bucket(level_one, fanout_table) do
      if elem(fanout_table, level_one) == elem(fanout_table, level_one - 1) do
        to_level_one_bucket(level_one - 1, fanout_table)
      else
        level_one
      end
    end

    defp find_level_two(level_one, fanout_table, nth_position) do
      base =
        if level_one > 0 do
          elem(fanout_table, level_one - 1)
        else
          0
        end

      nth_position - base
    end

    defp read_offset_at_index(-1, _level_one, _offset32, _offset64), do: -1

    defp read_offset_at_index(level_two, level_one, offset32, offset64) do
      offset32
      |> elem(level_one)
      |> :binary.bin_to_list(level_two * 4, 4)
      |> NB.decode_uint32()
      |> elem(0)
      |> maybe_decode_offset64(offset64)
    end

    defp maybe_decode_offset64(offset, _offset64) when offset < 0x80000000, do: offset

    # TO DO: Implement 64-bit case:
    # if ((p & IS_O64) != 0)
    #   return NB.decodeUInt64(offset64, (8 * (int) (p & ~IS_O64)));

    @impl true
    def find_offset(%{names: names, offset32: offset32, offset64: offset64}, object_id) do
      raw_object_id = ObjectId.to_raw_bytes(object_id)
      level_one = List.first(raw_object_id)
      l2_names = elem(names, level_one)

      l2_names
      |> find_object_in_level_two_index(
        :erlang.list_to_binary(raw_object_id),
        0,
        div(byte_size(l2_names), Constants.object_id_length())
      )
      |> read_offset_at_index(level_one, offset32, offset64)
    end

    defp find_object_in_level_two_index(_data, _raw_object_id, index, index), do: -1

    defp find_object_in_level_two_index(data, raw_object_id, min_index, max_index) do
      mid_index = div(min_index + max_index, 2)
      id_offset = mid_index * Constants.object_id_length()
      raw_id_at_index = :erlang.binary_part(data, id_offset, 20)

      cond do
        raw_id_at_index == raw_object_id ->
          mid_index

        raw_object_id < raw_id_at_index ->
          find_object_in_level_two_index(data, raw_object_id, min_index, mid_index)

        true ->
          find_object_in_level_two_index(data, raw_object_id, mid_index + 1, max_index)
      end
    end

    @impl true
    def crc32_checksum_for_object(%{names: names, crc32: crc32}, object_id) do
      raw_object_id = ObjectId.to_raw_bytes(object_id)
      level_one = List.first(raw_object_id)
      l2_names = elem(names, level_one)

      l2_names
      |> find_object_in_level_two_index(
        :erlang.list_to_binary(raw_object_id),
        0,
        div(byte_size(l2_names), Constants.object_id_length())
      )
      |> read_crc32_at_index(level_one, object_id, crc32)
    end

    defp read_crc32_at_index(-1, _level_one, object_id, _crc32) do
      raise MissingObjectError, object_id: object_id, type: "unknown"
    end

    defp read_crc32_at_index(level_two, level_one, _object_id, crc32) do
      crc32
      |> elem(level_one)
      |> :binary.bin_to_list(level_two * 4, 4)
      |> NB.decode_uint32()
      |> elem(0)
    end

    @impl true
    def has_crc32_support?(_index), do: true
  end
end
