# Copyright (C) 2008, Marek Zawirski <marek.zawirski@gmail.com>
# Copyright (C) 2008, Shawn O. Pearce <spearce@spearce.org>
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit.test/tst/org/eclipse/jgit/internal/storage/file/PackIndexV1Test.java
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

defmodule Xgit.Internal.Storage.File.PackIndex do
  @moduledoc ~S"""
  Access path to locate objects by `Xgit.Lib.ObjectId` in a
  `Xgit.Internal.Storage.File.PackFile`.

  Indexes are strictly redundant information in that we can rebuild all of the
  data held in the index file from the on-disk representation of the pack file
  itself, but it is faster to access for random requests because data is stored
  by `ObjectId`.
  """

  alias Xgit.Internal.Storage.File.PackIndexV1

  defprotocol Reader do
    @moduledoc ~S"""
    Provides access to data in the index for different index format versions.
    """

    @doc ~S"""
    Get object ID for the nth object entry returned by enumerating this index.

    This function is a constant-time replacement for the following loop:

    ```
    %{name: name} = entry = Enum.at(index, nth_position)
    name
    ```
    """
    def get_object_id_at_index(pack_index, nth_position)

    @doc ~S"""
    Get offset in a pack for the n-th (zero-based) object entry returned by
    enumerating this index.
    """
    def get_offset_at_index(index, nth_position)

    @doc ~S"""
    Retrieve stored CRC32 checksum of the requested object raw-data (including header).

    Returns CRC32 checksum of specified object (at 32 less significant bits) or
    raises `MissingObjectError` if the requested object ID was not found in this index.

    Raises `UnsupportedOperationError` if this index doesn't support CRC32 checksum.
    """
    def crc32_checksum_for_object(index, object_id)

    @doc ~S"""
    Returns `true` if this index supports (has) CRC32 checksums for objects.
    """
    def has_crc32_support?(index)
  end

  @doc ~S"""
  Open an existing pack `.idx` file for reading.

  The format of the file will be automatically detected and a proper access
  implementation for that format will be constructed and returned to the
  caller. The file may or may not be held open by the returned instance.

  Returns a struct that implements `PackIndex.Reader` and can be used to
  read the requested file.
  """
  def open(idx_file_path) when is_binary(idx_file_path) do
    try do
      idx_file_path
      |> File.open!([:read, :charlist])
      |> read()
    catch
      _ -> raise "Unreadable pack index: #{idx_file_path}"
    end
  end

  @doc ~S"""
  Read an existing pack index file from a file stream.

  The format of the file will be automatically detected and a proper access
  implementation for that format will be constructed and returned to the
  caller. The file may or may not be held open by the returned instance.
  """
  def read(file_pid) when is_pid(file_pid) do
    header = IO.read(file_pid, 8)

    if toc?(header) do
      raise "not ready for V2 or later pack index format"
      #     final int v = NB.decodeInt32(hdr, 4);
      #     switch (v) {
      #     case 2:
      #       return new PackIndexV2(fd);
      #     default:
      #       throw new UnsupportedPackIndexVersionException(v);
      #     }
    else
      PackIndexV1.parse(file_pid, header)
    end
  end

  defp toc?([0xFF, ?t, ?O, ?c | _]), do: true
  defp toc?(_), do: false

  # /** Footer checksum applied on the bottom of the pack file. */
  # protected byte[] packChecksum;
  #
  # /**
  #  * Determine if an object is contained within the pack file.
  #  *
  #  * @param id
  #  *            the object to look for. Must not be null.
  #  * @return true if the object is listed in this index; false otherwise.
  #  */
  # public boolean hasObject(AnyObjectId id) {
  #   return findOffset(id) != -1;
  # }
  #
  # /** {@inheritDoc} */
  # @Override
  # public boolean contains(AnyObjectId id) {
  #   return findOffset(id) != -1;
  # }

  # /**
  #  * Obtain the total number of objects described by this index.
  #  *
  #  * @return number of objects in this index, and likewise in the associated
  #  *         pack that this index was generated from.
  #  */
  # public abstract long getObjectCount();
  #
  # /**
  #  * Obtain the total number of objects needing 64 bit offsets.
  #  *
  #  * @return number of objects in this index using a 64 bit offset; that is an
  #  *         object positioned after the 2 GB position within the file.
  #  */
  # public abstract long getOffset64Count();

  @doc ~S"""
  Get object ID for the nth object entry returned by enumerating this index.

  This function is a constant-time replacement for the following loop:

  ```
  %{name: name} = entry = Enum.at(index, nth_position)
  name
  ```
  """
  defdelegate get_object_id_at_index(pack_index, nth_position), to: __MODULE__.Reader

  @doc ~S"""
  Get offset in a pack for the n-th (zero-based) object entry returned by
  enumerating this index.
  """
  defdelegate get_offset_at_index(pack_index, nth_position), to: __MODULE__.Reader

  # /**
  #  * Locate the file offset position for the requested object.
  #  *
  #  * @param objId
  #  *            name of the object to locate within the pack.
  #  * @return offset of the object's header and compressed content; -1 if the
  #  *         object does not exist in this index and is thus not stored in the
  #  *         associated pack.
  #  */
  # public abstract long findOffset(AnyObjectId objId);

  @doc ~S"""
  Retrieve stored CRC32 checksum of the requested object raw-data (including header).

  Returns CRC32 checksum of specified object (at 32 less significant bits) or
  raises `MissingObjectError` if the requested object ID was not found in this index.

  Raises `???` if this index doesn't support CRC32 checksum.
  """
  defdelegate crc32_checksum_for_object(index, object_id), to: __MODULE__.Reader

  @doc ~S"""
  Returns `true` if this index supports (has) CRC32 checksums for objects.
  """
  defdelegate has_crc32_support?(index), to: __MODULE__.Reader

  # /**
  #  * Find objects matching the prefix abbreviation.
  #  *
  #  * @param matches
  #  *            set to add any located ObjectIds to. This is an output
  #  *            parameter.
  #  * @param id
  #  *            prefix to search for.
  #  * @param matchLimit
  #  *            maximum number of results to return. At most this many
  #  *            ObjectIds should be added to matches before returning.
  #  * @throws java.io.IOException
  #  *             the index cannot be read.
  #  */
  # public abstract void resolve(Set<ObjectId> matches, AbbreviatedObjectId id,
  #     int matchLimit) throws IOException;

  defmodule Entry do
    @moduledoc ~S"""
    Represents a single entry of pack index consisting of object ID and offset
    in pack.

    (Unlike jgit, these entries are not mutable.)

    Struct members:
    * `:name` (string): Hex string containing the object ID of this entry.
    * `:offset` (integer): Offset for this index object entry.
    """
    @enforce_keys [:name, :offset]
    defstruct [:name, :offset]
  end
end
