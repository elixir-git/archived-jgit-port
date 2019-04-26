# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/internal/storage/file/FileSnapshot.java
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

defmodule Xgit.Internal.Storage.File.FileSnapshot do
  @moduledoc ~S"""
  Caches when a file was last read, making it possible to detect future edits.

  This object tracks the last modified time of a file. Later during an
  invocation of `modified?/2` the object will return `true` if the file may have
  been modified and should be re-read from disk.

  A snapshot does not "live update" when the underlying filesystem changes.
  Callers must poll for updates by periodically invoking `modified?/2`.

  To work around the "racy git" problem (where a file may be modified multiple
  times within the granularity of the filesystem modification clock) this class
  may return `true` from `modified?/2` if the last modification time of the
  file is less than 3 seconds ago.

  Struct members:
  * `last_modified`: Last observed modification time of the path.
  * `last_read`: When was the modification time last read?
  """

  @enforce_keys [:last_modified, :ref]
  defstruct [:last_modified, :ref]

  @doc ~S"""
  A FileSnapshot that is considered to always be modified.

  This instance is useful for application code that wants to lazily read a
  file, but only after `modified?/2` gets invoked. This snapshot instance
  contains only invalid status information.
  """
  def dirty, do: %__MODULE__{last_modified: :dirty, ref: nil}

  @doc ~S"""
  A FileSnapshot that is clean if the file does not exist.

  This instance is useful if the application wants to consider a missing
  file to be clean. `modified?/2` will return `false` if the file path
  does not exist.
  """
  def missing_file, do: %__MODULE__{last_modified: :missing, ref: nil}

  @doc ~S"""
  Record a snapshot for a specific file path.

  This method should be invoked before the file is accessed.
  """
  def save(path) when is_binary(path) do
    %{mtime: last_modified} = File.stat!(path, time: :posix)

    ref = make_ref()
    record_time_for_ref(ref)

    %__MODULE__{last_modified: last_modified, ref: ref}
  end

  @doc ~S"""
  Check if the path may have been modified since the snapshot was saved.
  """
  def modified?(%__MODULE__{last_modified: last_modified, ref: ref}, path)
      when is_binary(path) and is_reference(ref) do
    %{mtime: curr_last_modified} = File.stat!(path, time: :posix)
    modified_impl?(curr_last_modified, last_modified, ref)
  end

  def modified?(%__MODULE__{last_modified: :dirty}, _path), do: true
  def modified?(%__MODULE__{last_modified: :missing}, path), do: File.exists?(path)

  @doc ~S"""
  Update this snapshot when the content hasn't changed.

  If the caller gets `true` from `modified?/2`, re-reads the content, discovers
  the content is identical, it can use to make a future call to `modified?/2`
  return `false`.

  The logic goes something like this:

  ```
  if FileSnapshot.modified?(snapshot, path) do
    other = FileSnapshot.save(path)
    if old_content_matches_new_content? and snapshot.last_modified == other.last_modified do
      FileSnapshot.set_clean(snapshot, other)
    end
  end
  ```
  """
  def set_clean(
        %__MODULE__{last_modified: last_modified, ref: ref},
        %__MODULE__{ref: other_ref}
      ) do
    other_last_read = ConCache.get(:xgit_file_snapshot, other_ref)

    if not_racy_clean?(last_modified, other_last_read),
      do: ConCache.delete(:xgit_file_snapshot, ref),
      else: record_time_for_ref(ref, not_racy_clean?(last_modified, other_last_read))
  end

  defp modified_impl?(file_last_modified, last_modified, ref) do
    last_read_time = ConCache.get(:xgit_file_snapshot, ref)

    if last_modified == file_last_modified,
      do: modified_impl_race?(file_last_modified, last_read_time),
      else: true
  end

  # There's a potential race condition in which the file was modified at roughly
  # the same time as the last time we read the modification time. If these two
  # events are too close together, we have to assume the file is modified.

  defp modified_impl_race?(_file_last_modified, x) when x == false or x == nil do
    # We have already determined the last read was far enough
    # after the last modification that any new modifications
    # are certain to change the last modified time.
    false
  end

  defp modified_impl_race?(file_last_modified, last_read_time) do
    if not_racy_clean?(file_last_modified, last_read_time) do
      # Our last read should have marked cannotBeRacilyClean,
      # but this thread may not have seen the change. The read
      # of the volatile field lastRead should have fixed that.
      false
    else
      # We last read this path too close to its last observed
      # modification time. We may have missed a modification.
      # Scan again, to ensure we still see the same state.
      true
    end
  end

  defp not_racy_clean?(last_modified_time, last_read_time) do
    last_read_time - last_modified_time >= 3
    # The last modified time granularity of FAT filesystems is 2 seconds.
    # Using 3 seconds here provides a reasonably high assurance that
    # a modification was not missed.
  end

  defp record_time_for_ref(ref, time \\ :os.system_time(:second)) when is_reference(ref),
    do: ConCache.put(:xgit_file_snapshot, ref, time)
end

defimpl String.Chars, for: Xgit.Internal.Storage.File.FileSnapshot do
  alias Xgit.Internal.Storage.File.FileSnapshot

  def to_string(%FileSnapshot{last_modified: :dirty}), do: "DIRTY"

  def to_string(%FileSnapshot{last_modified: :missing}), do: "MISSING_FILE"

  def to_string(%FileSnapshot{last_modified: last_modified, ref: ref}) do
    last_read_time = ConCache.get(:xgit_file_snapshot, ref)
    "FileSnapshot[modified: #{last_modified}, read: #{last_read_time}]"
  end
end
