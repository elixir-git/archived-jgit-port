defmodule Xgit.Lib.ObjectReader do
  @moduledoc ~S"""
  Reads an `ObjectDatabase` for a single process.

  Readers that can support efficient reuse of pack encoded objects should also
  implement the companion protocol `ObjectReuseAsIs`.

  PORTING NOTE: Is this necessarily tied to a single process in Elixir?

  PORTING NOTE: `ObjectReuseAsIs` is not yet ported.

  PORTING NOTE: `streamFileThreadhold` is considered an implementation detail
  and thus is not part of the generic interface.

  PORTING NOTE: This jgit class is partially ported for now. Holding off on the
  rest until I understand the use cases better.
  """

  alias Xgit.Lib.AbbreviatedObjectId
  alias Xgit.Lib.ObjectId

  defprotocol Strategy do
    @moduledoc ~S"""
    Strategy for `ObjectReader` instances.
    """

    alias Xgit.Lib.AbbreviatedObjectId
    alias Xgit.Lib.ObjectId

    # should implement Strategy protocol
    @type t :: term()

    @doc ~S"""
    Resolve an abbreviated `ObjectId` to its full form.

    This method searches for an `ObjectId` that begins with the abbreviation,
    and returns at least some matching candidates.

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
    def resolve(reader, abbreviated_id)

    @doc ~S"""
    Does the requested object exist in this database?

    `type_hint` may be one of the `obj_*` constants from `Constants` or
    the wildcard term `:any` if the caller does not know the object type.
    """
    @spec has_object?(reader :: term, object_id :: ObjectId.t(), type_hint :: term) :: boolean
    def has_object?(reader, object_id, type_hint)

    @doc ~S"""
    Open an object from this database.

    `type_hint` may be one of the `obj_*` constants from `Constants` or
    the wildcard term `:any` if the caller does not know the object type.

    Should return a struct that implements `ObjectLoader` protocol.

    Should raise `MissingObjectError` if no such object exists in the database.
    """
    @spec open(reader :: term, object_id :: ObjectId.t(), type_hint :: term) :: ObjectLoader.t()
    def open(reader, object_id, type_hint)
  end

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
  @spec abbreviate(reader :: term, object_id :: ObjectId.t(), length :: 2..40) ::
          AbbreviatedObjectId.t()
  def abbreviate(reader, object_id, length \\ 7)

  def abbreviate(_reader, object_id, 40) when is_binary(object_id), do: object_id

  def abbreviate(reader, object_id, length)
      when is_integer(length) and length >= 2 and length < 40 do
    abbrev = String.slice(object_id, 0, length)

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
  Resolve an abbreviated `ObjectId` to its full form.

  This method searches for an `ObjectId` that begins with the abbreviation,
  and returns at least some matching candidates.

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
  @spec resolve(reader :: term, abbreviated_id :: AbbreviatedObjectId.t()) :: [ObjectId.t()]
  defdelegate resolve(reader, abbreviated_id), to: Strategy

  @doc ~S"""
  Does the requested object exist in this database?

  `type_hint` should be one of the `obj_*` constants from `Constants` or
  the wildcard term `:any` if the object type is not known. (The default value
  is `:any`.)
  """
  @spec has_object?(reader :: term, object_id :: ObjectId.t(), type_hint :: term) :: boolean
  defdelegate has_object?(reader, object_id, type_hint \\ :any), to: Strategy

  @doc ~S"""
  Open an object from this database.

  `type_hint` should be one of the `obj_*` constants from `Constants` or
  the wildcard term `:any` if the object type is not known. (The default value
  is `:any`.)

  Returns a struct that implements `ObjectLoader` protocol.

  Raises `MissingObjectError` if no such object exists in the database.
  """
  @spec open(reader :: term, object_id :: ObjectId.t(), type_hint :: term) :: ObjectLoader.t()
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
  #
  # /**
  #  * Get only the size of an object.
  #  * <p>
  #  * The default implementation of this method opens an ObjectLoader.
  #  * Databases are encouraged to override this if a faster access method is
  #  * available to them.
  #  *
  #  * @param objectId
  #  *            identity of the object to open.
  #  * @param typeHint
  #  *            hint about the type of object being requested, e.g.
  #  *            {@link org.eclipse.jgit.lib.Constants#OBJ_BLOB};
  #  *            {@link #:any} if the object type is not known, or does not
  #  *            matter to the caller.
  #  * @return size of object in bytes.
  #  * @throws org.eclipse.jgit.errors.MissingObjectException
  #  *             the object does not exist.
  #  * @throws org.eclipse.jgit.errors.IncorrectObjectTypeException
  #  *             typeHint was not :any, and the object's actual type does
  #  *             not match typeHint.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # public long getObjectSize(AnyObjectId objectId, int typeHint)
  #     throws MissingObjectException, IncorrectObjectTypeException,
  #     IOException {
  #   return open(objectId, typeHint).getSize();
  # }
  #
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
