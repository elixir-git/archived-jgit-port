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

  @enforce_keys [:object_count, :fanout_table, :names, :crc32, :offset32, :offset64, :pack_checksum]
  defstruct [:object_count, :fanout_table, :names, :crc32, :offset32, :offset64, :pack_checksum]

  # alias Xgit.Internal.Storage.File.PackIndex.Reader
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

    IO.inspect(size_of_offset32_list, label: "offset32 bytes")

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

  # # /** {@inheritDoc} */
  # # @Override
  # # public void resolve(Set<ObjectId> matches, AbbreviatedObjectId id,
  # #     int matchLimit) throws IOException {
  # #   byte[] data = idxdata[id.getFirstByte()];
  # #   if (data == null)
  # #     return;
  # #   int max = data.length / (4 + Constants.OBJECT_ID_LENGTH);
  # #   int high = max;
  # #   int low = 0;
  # #   do {
  # #     int p = (low + high) >>> 1;
  # #     final int cmp = id.prefixCompare(data, idOffset(p));
  # #     if (cmp < 0)
  # #       high = p;
  # #     else if (cmp == 0) {
  # #       // We may have landed in the middle of the matches.  Move
  # #       // backwards to the start of matches, then walk forwards.
  # #       //
  # #       while (0 < p && id.prefixCompare(data, idOffset(p - 1)) == 0)
  # #         p--;
  # #       for (; p < max && id.prefixCompare(data, idOffset(p)) == 0; p++) {
  # #         matches.add(ObjectId.fromRaw(data, idOffset(p)));
  # #         if (matches.size() > matchLimit)
  # #           break;
  # #       }
  # #       return;
  # #     } else
  # #       low = p + 1;
  # #   } while (low < high);
  # # }
  # #
  # # private static int idOffset(int mid) {
  # #   return ((4 + Constants.OBJECT_ID_LENGTH) * mid) + 4;
  # # }
  #
  # defimpl Enumerable do
  #   alias Xgit.Internal.Storage.File.PackIndex.Entry
  #   alias Xgit.Internal.Storage.File.PackIndexV1
  #   alias Xgit.Lib.ObjectId
  #
  #   def count(_), do: {:error, PackIndexV1}
  #   def member?(_, _), do: {:error, PackIndexV1}
  #   def slice(_), do: {:error, PackIndexV1}
  #
  #   def reduce(%PackIndexV1{idx_data: idx_data}, acc, fun) when is_list(idx_data),
  #     do: reduce(idx_data, [], acc, fun)
  #
  #   defp reduce(level1, level2, acc, fun)
  #
  #   defp reduce(_level1, _leve2, {:halt, acc}, _fun), do: {:halted, acc}
  #
  #   # TO DO: Restore this case if we find that we actually use suspended enumerations.
  #   # For now, I don't see a use case for it.
  #   # defp reduce(level1, level2, {:suspend, acc}, fun),
  #   #   do: {:suspended, acc, &reduce(level1, level2, &1, fun)}
  #
  #   defp reduce([] = _level1, [] = _level2, {:cont, acc}, _fun), do: {:done, acc}
  #
  #   defp reduce([l1_head | l1_tail], [] = _level2, {:cont, _} = acc, fun),
  #     do: reduce(l1_tail, l1_head, acc, fun)
  #
  #   defp reduce(level1, level2, {:cont, acc}, fun) do
  #     entry = %Entry{
  #       name: level2 |> Enum.drop(4) |> ObjectId.from_raw_bytes(),
  #       offset: level2 |> NB.decode_uint32() |> elem(0)
  #     }
  #
  #     reduce(level1, Enum.drop(level2, Constants.object_id_length() + 4), fun.(entry, acc), fun)
  #   end
  # end
  #
  # defimpl Reader do
  #   alias Xgit.Errors.UnsupportedOperationError
  #   alias Xgit.Lib.ObjectId
  #   alias Xgit.Util.TupleUtils
  #
  #   @impl true
  #   def get_object_id_at_index(%{idx_header: idx_header, idx_data: idx_data}, nth_position) do
  #     level_one =
  #       idx_header
  #       |> find_level_one(nth_position)
  #
  #     level_one
  #     |> find_level_two(idx_header, nth_position)
  #     |> read_object_id_at_index(level_one, idx_data)
  #   end
  #
  #   @impl true
  #   def get_offset_at_index(%{idx_header: idx_header, idx_data: idx_data}, nth_position) do
  #     level_one =
  #       idx_header
  #       |> find_level_one(nth_position)
  #
  #     level_one
  #     |> find_level_two(idx_header, nth_position)
  #     |> read_offset_at_index(level_one, idx_data)
  #   end
  #
  #   defp find_level_one(idx_header, nth_position) do
  #     idx_header
  #     |> TupleUtils.binary_search(nth_position + 1)
  #     |> to_level_one_bucket(idx_header)
  #   end
  #
  #   defp to_level_one_bucket(level_one, _idx_header) when level_one < 0,
  #     do: -(level_one + 1)
  #
  #   defp to_level_one_bucket(0, _idx_header), do: 0
  #
  #   defp to_level_one_bucket(level_one, idx_header) do
  #     if elem(idx_header, level_one) == elem(idx_header, level_one - 1) do
  #       to_level_one_bucket(level_one - 1, idx_header)
  #     else
  #       level_one
  #     end
  #   end
  #
  #   defp find_level_two(level_one, idx_header, nth_position) do
  #     base =
  #       if level_one > 0 do
  #         elem(idx_header, level_one - 1)
  #       else
  #         0
  #       end
  #
  #     nth_position - base
  #   end
  #
  #   defp read_offset_at_index(level_two, level_one, idx_data) do
  #     byte_offset = level_two * (4 + Constants.object_id_length())
  #
  #     idx_data
  #     |> Enum.at(level_one)
  #     |> Enum.drop(byte_offset)
  #     |> NB.decode_uint32()
  #     |> elem(0)
  #   end
  #
  #   defp read_object_id_at_index(level_two, level_one, idx_data) do
  #     byte_offset = level_two * (4 + Constants.object_id_length()) + 4
  #
  #     idx_data
  #     |> Enum.at(level_one)
  #     |> Enum.drop(byte_offset)
  #     |> ObjectId.from_raw_bytes()
  #   end
  #
  #   @impl true
  #   def find_offset(%{idx_data: idx_data}, object_id) do
  #     raw_object_id = ObjectId.to_raw_bytes(object_id)
  #     level_one = List.first(raw_object_id)
  #
  #     # TO DO: Watch this for performance. Do we need to convert this to a binary
  #     # right off the bat, or is per `find_offset` call acceptable?
  #     data =
  #       idx_data
  #       |> Enum.at(level_one)
  #       |> :erlang.list_to_binary()
  #
  #     find_offset_in_level_two_index(
  #       data,
  #       :erlang.list_to_binary(raw_object_id),
  #       0,
  #       div(byte_size(data), 24)
  #     )
  #   end
  #
  #   defp find_offset_in_level_two_index(_data, _raw_object_id, index, index), do: -1
  #
  #   defp find_offset_in_level_two_index(data, raw_object_id, min_index, max_index) do
  #     mid_index = div(min_index + max_index, 2)
  #     id_offset = mid_index * 24 + 4
  #     raw_id_at_index = :erlang.binary_part(data, id_offset, 20)
  #
  #     cond do
  #       raw_id_at_index == raw_object_id ->
  #         data
  #         |> String.slice(id_offset - 4, 4)
  #         |> :erlang.binary_to_list()
  #         |> NB.decode_uint32()
  #         |> elem(0)
  #
  #       raw_id_at_index < raw_object_id ->
  #         find_offset_in_level_two_index(data, raw_object_id, min_index, mid_index)
  #
  #       true ->
  #         find_offset_in_level_two_index(data, raw_object_id, mid_index + 1, max_index)
  #     end
  #   end
  #
  #   @impl true
  #   def crc32_checksum_for_object(_index, _object_id) do
  #     raise UnsupportedOperationError,
  #       message: "CRC32 checksums not available for V1 pack index."
  #   end
  #
  #   @impl true
  #   def has_crc32_support?(_index), do: false
  # end
end

# /** Support for the pack index v2 format. */
# class PackIndexV2 extends PackIndex {
#   private static final long IS_O64 = 1L << 31;
#
#     // CRC32 table.
#     for (int k = 0; k < FANOUT; k++)
#       IO.readFully(fd, crc32[k], 0, crc32[k].length);
#
#     // 32 bit offset table. Any entries with the most significant bit
#     // set require a 64 bit offset entry in another table.
#     //
#     int o64cnt = 0;
#     for (int k = 0; k < FANOUT; k++) {
#       final byte[] ofs = offset32[k];
#       IO.readFully(fd, ofs, 0, ofs.length);
#       for (int p = 0; p < ofs.length; p += 4)
#         if (ofs[p] < 0)
#           o64cnt++;
#     }
#
#     // 64 bit offset table. Most objects should not require an entry.
#     //
#     if (o64cnt > 0) {
#       offset64 = new byte[o64cnt * 8];
#       IO.readFully(fd, offset64, 0, offset64.length);
#     } else {
#       offset64 = NO_BYTES;
#     }
#
#     packChecksum = new byte[20];
#     IO.readFully(fd, packChecksum, 0, packChecksum.length);
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public long getObjectCount() {
#     return objectCnt;
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public long getOffset64Count() {
#     return offset64.length / 8;
#   }
#
#   private int findLevelOne(long nthPosition) {
#     int levelOne = Arrays.binarySearch(fanoutTable, nthPosition + 1);
#     if (levelOne >= 0) {
#       // If we hit the bucket exactly the item is in the bucket, or
#       // any bucket before it which has the same object count.
#       //
#       long base = fanoutTable[levelOne];
#       while (levelOne > 0 && base == fanoutTable[levelOne - 1])
#         levelOne--;
#     } else {
#       // The item is in the bucket we would insert it into.
#       //
#       levelOne = -(levelOne + 1);
#     }
#     return levelOne;
#   }
#
#   private int getLevelTwo(long nthPosition, int levelOne) {
#     final long base = levelOne > 0 ? fanoutTable[levelOne - 1] : 0;
#     return (int) (nthPosition - base);
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public ObjectId getObjectId(long nthPosition) {
#     final int levelOne = findLevelOne(nthPosition);
#     final int p = getLevelTwo(nthPosition, levelOne);
#     final int p4 = p << 2;
#     return ObjectId.fromRaw(names[levelOne], p4 + p); // p * 5
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public long getOffset(long nthPosition) {
#     final int levelOne = findLevelOne(nthPosition);
#     final int levelTwo = getLevelTwo(nthPosition, levelOne);
#     return getOffset(levelOne, levelTwo);
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public long findOffset(AnyObjectId objId) {
#     final int levelOne = objId.getFirstByte();
#     final int levelTwo = binarySearchLevelTwo(objId, levelOne);
#     if (levelTwo == -1)
#       return -1;
#     return getOffset(levelOne, levelTwo);
#   }
#
#   private long getOffset(int levelOne, int levelTwo) {
#     final long p = NB.decodeUInt32(offset32[levelOne], levelTwo << 2);
#     if ((p & IS_O64) != 0)
#       return NB.decodeUInt64(offset64, (8 * (int) (p & ~IS_O64)));
#     return p;
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public long findCRC32(AnyObjectId objId) throws MissingObjectException {
#     final int levelOne = objId.getFirstByte();
#     final int levelTwo = binarySearchLevelTwo(objId, levelOne);
#     if (levelTwo == -1)
#       throw new MissingObjectException(objId.copy(), "unknown"); //$NON-NLS-1$
#     return NB.decodeUInt32(crc32[levelOne], levelTwo << 2);
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public boolean hasCRC32Support() {
#     return true;
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public Iterator<MutableEntry> iterator() {
#     return new EntriesIteratorV2();
#   }
#
#   /** {@inheritDoc} */
#   @Override
#   public void resolve(Set<ObjectId> matches, AbbreviatedObjectId id,
#       int matchLimit) throws IOException {
#     int[] data = names[id.getFirstByte()];
#     int max = offset32[id.getFirstByte()].length >>> 2;
#     int high = max;
#     if (high == 0)
#       return;
#     int low = 0;
#     do {
#       int p = (low + high) >>> 1;
#       final int cmp = id.prefixCompare(data, idOffset(p));
#       if (cmp < 0)
#         high = p;
#       else if (cmp == 0) {
#         // We may have landed in the middle of the matches.  Move
#         // backwards to the start of matches, then walk forwards.
#         //
#         while (0 < p && id.prefixCompare(data, idOffset(p - 1)) == 0)
#           p--;
#         for (; p < max && id.prefixCompare(data, idOffset(p)) == 0; p++) {
#           matches.add(ObjectId.fromRaw(data, idOffset(p)));
#           if (matches.size() > matchLimit)
#             break;
#         }
#         return;
#       } else
#         low = p + 1;
#     } while (low < high);
#   }
#
#   private static int idOffset(int p) {
#     return (p << 2) + p; // p * 5
#   }
#
#   private int binarySearchLevelTwo(AnyObjectId objId, int levelOne) {
#     final int[] data = names[levelOne];
#     int high = offset32[levelOne].length >>> 2;
#     if (high == 0)
#       return -1;
#     int low = 0;
#     do {
#       final int mid = (low + high) >>> 1;
#       final int mid4 = mid << 2;
#       final int cmp;
#
#       cmp = objId.compareTo(data, mid4 + mid); // mid * 5
#       if (cmp < 0)
#         high = mid;
#       else if (cmp == 0) {
#         return mid;
#       } else
#         low = mid + 1;
#     } while (low < high);
#     return -1;
#   }
#
#   private class EntriesIteratorV2 extends EntriesIterator {
#     int levelOne;
#
#     int levelTwo;
#
#     @Override
#     protected MutableEntry initEntry() {
#       return new MutableEntry() {
#         @Override
#         protected void ensureId() {
#           idBuffer.fromRaw(names[levelOne], levelTwo
#               - Constants.OBJECT_ID_LENGTH / 4);
#         }
#       };
#     }
#
#     @Override
#     public MutableEntry next() {
#       for (; levelOne < names.length; levelOne++) {
#         if (levelTwo < names[levelOne].length) {
#           int idx = levelTwo / (Constants.OBJECT_ID_LENGTH / 4) * 4;
#           long offset = NB.decodeUInt32(offset32[levelOne], idx);
#           if ((offset & IS_O64) != 0) {
#             idx = (8 * (int) (offset & ~IS_O64));
#             offset = NB.decodeUInt64(offset64, idx);
#           }
#           entry.offset = offset;
#
#           levelTwo += Constants.OBJECT_ID_LENGTH / 4;
#           returnedNumber++;
#           return entry;
#         }
#         levelTwo = 0;
#       }
#       throw new NoSuchElementException();
#     }
#   }
#
# }
