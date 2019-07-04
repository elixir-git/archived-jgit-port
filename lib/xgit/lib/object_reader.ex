# Copyright (C) 2010, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectReader.java
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

defmodule Xgit.Lib.ObjectReader do
  @moduledoc ~S"""
  Reads an `Xgit.Lib.ObjectDatabase` for a single process.

  Readers that can support efficient reuse of pack encoded objects should also
  implement the companion protocol `ObjectReuseAsIs` _(not yet ported)_.

  TO DO: https://github.com/elixir-git/xgit/issues/133

  PORTING NOTE: Is this necessarily tied to a single process in Elixir?

  PORTING NOTE: `ObjectReuseAsIs` is not yet ported.

  PORTING NOTE: `streamFileThreadhold` is considered an implementation detail
  and thus is not part of the generic interface.

  PORTING NOTE: This jgit class is partially ported for now. Holding off on the
  rest until I understand the use cases better.
  """

  alias Xgit.Lib.AbbreviatedObjectId
  alias Xgit.Lib.ObjectId
  alias Xgit.Lib.ObjectLoader

  defprotocol Strategy do
    @moduledoc ~S"""
    Strategy for `Xgit.Lib.ObjectReader` instances.
    """

    alias Xgit.Lib.AbbreviatedObjectId
    alias Xgit.Lib.ObjectId

    @type t :: struct

    @doc ~S"""
    Resolve an abbreviated object ID to its full form.

    This method searches for an object ID that begins with the abbreviation,
    and returns at least some matching candidates.

    ## Return Values

    If the returned collection is empty, no objects start with this
    abbreviation. The abbreviation doesn't belong to this repository, or the
    repository lacks the necessary objects to complete it.

    If the collection contains exactly one member, the abbreviation is
    (currently) unique within this database. There is a reasonably high
    probability that the returned ID is what was previously abbreviated.

    If the collection contains 2 or more members, the abbreviation is not
    unique. In this case the implementation is only required to return at
    least 2 candidates to signal the abbreviation has conflicts. User-friendly
    implementations should return as many candidates as reasonably possible,
    as the caller may be able to disambiguate further based on context. However,
    since databases can be very large (e.g. 10 million objects) returning 625,000
    candidates for the abbreviation "0" is simply unreasonable. Implementers
    should draw the line at around 256 matches.
    """
    @spec resolve(reader :: t, abbreviated_id :: AbbreviatedObjectId.t()) :: [ObjectId.t()]
    def resolve(reader, abbreviated_id)

    @doc ~S"""
    Does the requested object exist in this database?

    ## Parameters

    `type_hint` may be one of the `obj_*` constants from `Xgit.Lib.Constants` or
    the wildcard term `:any` if the caller does not know the object type.
    """
    @spec has_object?(
            reader :: t,
            object_id :: ObjectId.t(),
            type_hint :: Xgit.Lib.Constants.obj_type() | :any
          ) :: boolean
    def has_object?(reader, object_id, type_hint)

    @doc ~S"""
    Open an object from this database.

    ## Parameters

    `type_hint` may be one of the `obj_*` constants from `Xgit.Lib.Constants` or
    the wildcard term `:any` if the caller does not know the object type.

    ## Return Value

    Should return a struct that implements `Xgit.Lib.ObjectLoader` protocol.

    ## Errors

    Should raise `Xgit.Errors.MissingObjectError` if no such object exists in the database.
    """
    @spec open(
            reader :: t,
            object_id :: ObjectId.t(),
            type_hint :: Xgit.Lib.Constants.obj_type() | :any
          ) ::
            ObjectLoader.t()
    def open(reader, object_id, type_hint)

    @doc ~S"""
    Get only the size of an object.

    ## Parameters

    `type_hint` may be one of the `obj_*` constants from `Xgit.Lib.Constants` or
    the wildcard term `:any` if the caller does not know the object type.

    ## Return Value

    Should return the size of the object in bytes.

    A default implementation exists. It will call `open/3` and use the resulting
    `Xgit.Lib.ObjectLoader` to determine the object's size. If an implementation wishes
    to use this implementation, it can simply return `:default` from this
    function.

    ## Error

    Should raise `Xgit.Errors.MissingObjectError` if no such object exists.
    """
    @spec object_size(
            reader :: t,
            object_id :: ObjectId.t(),
            type_hint :: Xgit.Lib.Constants.obj_type() | :any
          ) ::
            non_neg_integer() | :default
    def object_size(reader, object_id, type_hint)
  end

  @type t :: __MODULE__.Strategy.t()

  @doc ~S"""
  Obtain a unique abbreviation (prefix) of an object SHA-1.

  This function offers a reasonable default (7) for the minimum length. Callers who
  don't care about the minimum length should use the default.

  Abbreviates the ID to the specified length, then resolves it to see if there
  are multiple results. When multiple results are found, the length is extended
  by 1 and resolve is tried again.

  The returned abbreviation would expand back to the argument `object_id` when
  passed to `resolve/2`, assuming no new objects are added to this repository
  between calls.
  """
  @spec abbreviate(reader :: t, object_id :: ObjectId.t(), length :: 2..40) ::
          AbbreviatedObjectId.t()
  def abbreviate(reader, object_id, length \\ 7)

  def abbreviate(_reader, object_id, 40) when is_binary(object_id), do: object_id

  def abbreviate(reader, object_id, length)
      when is_integer(length) and length >= 2 and length < 40 do
    abbrev = :binary.part(object_id, 0, length)

    case resolve(reader, abbrev) do
      [_] ->
        abbrev

      [] ->
        abbrev

      _ ->
        abbreviate(reader, object_id, length + 1)
        # OPTIMIZATION NOTE: This is a naive implementation. We *could* sniff the
        # candidates that are returned and then potentially avoid some calls to
        # resolve/2 in that case. For now, we're taking the performance hit.
    end
  end

  @doc ~S"""
  Resolve an abbreviated object ID to its full form.

  This method searches for an object ID that begins with the abbreviation,
  and returns at least some matching candidates.

  ## Return Value

  If the returned collection is empty, no objects start with this
  abbreviation. The abbreviation doesn't belong to this repository, or the
  repository lacks the necessary objects to complete it.

  If the collection contains exactly one member, the abbreviation is
  (currently) unique within this database. There is a reasonably high
  probability that the returned ID is what was previously abbreviated.

  If the collection contains 2 or more members, the abbreviation is not
  unique. In this case the implementation is only required to return at
  least 2 candidates to signal the abbreviation has conflicts. User- friendly
  implementations should return as many candidates as reasonably possible,
  as the caller may be able to disambiguate further based on context. However,
  since databases can be very large (e.g. 10 million objects) returning 625,000
  candidates for the abbreviation "0" is simply unreasonable. Implementers
  should draw the line at around 256 matches.
  """
  @spec resolve(reader :: t, abbreviated_id :: AbbreviatedObjectId.t()) :: [ObjectId.t()]
  defdelegate resolve(reader, abbreviated_id), to: Strategy

  @doc ~S"""
  Does the requested object exist in this database?

  `type_hint` should be one of the `obj_*` constants from `Xgit.Lib.Constants` or
  the wildcard term `:any` if the object type is not known. (The default value
  is `:any`.)
  """
  @spec has_object?(
          reader :: t,
          object_id :: ObjectId.t(),
          type_hint :: Xgit.Lib.Constants.obj_type() | :any
        ) :: boolean
  defdelegate has_object?(reader, object_id, type_hint \\ :any), to: Strategy

  @doc ~S"""
  Open an object from this database.

  `type_hint` should be one of the `obj_*` constants from `Xgit.Lib.Constants` or
  the wildcard term `:any` if the object type is not known. (The default value
  is `:any`.)

  Returns a struct that implements `Xgit.Lib.ObjectLoader` protocol.

  Raises `Xgit.Errors.MissingObjectError` if no such object exists in the database.
  """
  @spec open(
          reader :: term,
          object_id :: ObjectId.t(),
          type_hint :: Xgit.Lib.Constants.obj_type() | :any
        ) ::
          ObjectLoader.t()
  defdelegate open(reader, object_id, type_hint \\ :any), to: Strategy

  # /**
  #  * Returns IDs for those commits which should be considered as shallow.
  #  *
  #  * @return IDs of shallow commits
  #  * @throws java.io.IOException
  #  */
  # public abstract Set<ObjectId> getShallowCommits() throws IOException;
  #
  # /**
  #  * Asynchronous object opening.
  #  *
  #  * PORTING NOTE: This might be better handled by clients using Task.async_stream.
  #  *
  #  * @param objectIds
  #  *            objects to open from the object store. The supplied collection
  #  *            must not be modified until the queue has finished.
  #  * @param reportMissing
  #  *            if true missing objects are reported by calling failure with a
  #  *            MissingObjectException. This may be more expensive for the
  #  *            implementation to guarantee. If false the implementation may
  #  *            choose to report MissingObjectException, or silently skip over
  #  *            the object with no warning.
  #  * @return queue to read the objects from.
  #  */
  # public <T extends ObjectId> AsyncObjectLoaderQueue<T> open(
  #     Iterable<T> objectIds, final boolean reportMissing) {
  #   final Iterator<T> idItr = objectIds.iterator();
  #   return new AsyncObjectLoaderQueue<T>() {
  #     private T cur;
  #
  #     @Override
  #     public boolean next() throws MissingObjectException, IOException {
  #       if (idItr.hasNext()) {
  #         cur = idItr.next();
  #         return true;
  #       } else {
  #         return false;
  #       }
  #     }
  #
  #     @Override
  #     public T getCurrent() {
  #       return cur;
  #     }
  #
  #     @Override
  #     public ObjectId getObjectId() {
  #       return cur;
  #     }
  #
  #     @Override
  #     public ObjectLoader open() throws IOException {
  #       return ObjectReader.this.open(cur, :any);
  #     }
  #
  #     @Override
  #     public boolean cancel(boolean mayInterruptIfRunning) {
  #       return true;
  #     }
  #
  #     @Override
  #     public void release() {
  #       // Since we are sequential by default, we don't
  #       // have any state to clean up if we terminate early.
  #     }
  #   };
  # }

  @doc ~S"""
  Get only the size of an object.

  `type_hint` should be one of the `obj_*` constants from `Xgit.Lib.Constants` or
  the wildcard term `:any` if the object type is not known. (The default value
  is `:any`.)

  Returns the size of the object in bytes.

  Raises `Xgit.Errors.MissingObjectError` if no such object exists.
  """
  @spec object_size(
          reader :: term,
          object_id :: ObjectId.t(),
          type_hint :: Xgit.Lib.Constants.obj_type() | :any
        ) ::
          ObjectLoader.t()
  def object_size(reader, object_id, type_hint \\ :any) do
    case Strategy.object_size(reader, object_id, type_hint) do
      size when is_integer(size) ->
        size

      :default ->
        reader
        |> open(object_id, type_hint)
        |> ObjectLoader.size()
    end
  end

  # /**
  #  * Asynchronous object size lookup.
  #  *
  #  * @param objectIds
  #  *            objects to get the size of from the object store. The supplied
  #  *            collection must not be modified until the queue has finished.
  #  * @param reportMissing
  #  *            if true missing objects are reported by calling failure with a
  #  *            MissingObjectException. This may be more expensive for the
  #  *            implementation to guarantee. If false the implementation may
  #  *            choose to report MissingObjectException, or silently skip over
  #  *            the object with no warning.
  #  * @return queue to read object sizes from.
  #  */
  # public <T extends ObjectId> AsyncObjectSizeQueue<T> getObjectSize(
  #     Iterable<T> objectIds, final boolean reportMissing) {
  #   final Iterator<T> idItr = objectIds.iterator();
  #   return new AsyncObjectSizeQueue<T>() {
  #     private T cur;
  #
  #     private long sz;
  #
  #     @Override
  #     public boolean next() throws MissingObjectException, IOException {
  #       if (idItr.hasNext()) {
  #         cur = idItr.next();
  #         sz = getObjectSize(cur, :any);
  #         return true;
  #       } else {
  #         return false;
  #       }
  #     }
  #
  #     @Override
  #     public T getCurrent() {
  #       return cur;
  #     }
  #
  #     @Override
  #     public ObjectId getObjectId() {
  #       return cur;
  #     }
  #
  #     @Override
  #     public long getSize() {
  #       return sz;
  #     }
  #
  #     @Override
  #     public boolean cancel(boolean mayInterruptIfRunning) {
  #       return true;
  #     }
  #
  #     @Override
  #     public void release() {
  #       // Since we are sequential by default, we don't
  #       // have any state to clean up if we terminate early.
  #     }
  #   };
  # }
  #
  # /**
  #  * Advise the reader to avoid unreachable objects.
  #  * <p>
  #  * While enabled the reader will skip over anything previously proven to be
  #  * unreachable. This may be dangerous in the face of concurrent writes.
  #  *
  #  * @param avoid
  #  *            true to avoid unreachable objects.
  #  * @since 3.0
  #  */
  # public void setAvoidUnreachableObjects(boolean avoid) {
  #    -- is overridden
  #   // Do nothing by default.
  # }
  #
  # /**
  #  * An index that can be used to speed up ObjectWalks.
  #  *
  #  * @return the index or null if one does not exist.
  #  * @throws java.io.IOException
  #  *             when the index fails to load
  #  * @since 3.0
  #  */
  # public BitmapIndex getBitmapIndex() throws IOException {
  #   -- is overridden
  #   return null;
  # }
  #
  # /**
  #  * Get the {@link org.eclipse.jgit.lib.ObjectInserter} from which this
  #  * reader was created using {@code inserter.newReader()}
  #  *
  #  * @return the {@link org.eclipse.jgit.lib.ObjectInserter} from which this
  #  *         reader was created using {@code inserter.newReader()}, or null if
  #  *         this reader was not created from an inserter.
  #  * @since 4.4
  #  */
  # @Nullable
  # public ObjectInserter getCreatedFromInserter() {
  #   -- is overridden
  #   return null;
  # }
  #
  # /**
  #  * {@inheritDoc}
  #  * <p>
  #  * Release any resources used by this reader.
  #  * <p>
  #  * A reader that has been released can be used again, but may need to be
  #  * released after the subsequent usage.
  #  *
  #  * @since 4.0
  #  */
  # @Override
  # public abstract void close();
  #
  # /**
  #  * Sets the threshold at which a file will be streamed rather than loaded
  #  * entirely into memory
  #  *
  #  * @param threshold
  #  *            the new threshold
  #  * @since 4.6
  #  */
  # public void setStreamFileThreshold(int threshold) {
  #   streamFileThreshold = threshold;
  # }
  #
  # /**
  #  * Returns the threshold at which a file will be streamed rather than loaded
  #  * entirely into memory
  #  *
  #  * @return the threshold in bytes
  #  * @since 4.6
  #  */
  # public int getStreamFileThreshold() {
  #   return streamFileThreshold;
  # }
end
