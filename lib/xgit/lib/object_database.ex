defprotocol Xgit.Lib.ObjectDatabase do
  @moduledoc ~S"""
  Abstraction of arbitrary object storage.

  An object database stores one or more git objects, indexed by their unique
  `ObjectId`.
  """

  alias Xgit.Lib.ObjectInserter

  @type t :: term

  @doc ~S"""
  Does this database exist yet?
  """
  @spec exists(database :: t) :: boolean
  def exists?(database)

  @doc ~S"""
  Initialize a new object database at this location.

  Raises `File.Error` if the database could not be created.
  """
  @spec create!(database :: t) :: :ok
  def create!(database)

  # PORTING NOTE: ObjectInserter is not ported yet.
  # @doc ~S"""
  # Create a new `ObjectInserter` to insert new objects.
  # """
  # @spec new_inserter(database :: t) :: ObjectInserter.t()
  # def new_inserter(database)

  @doc ~S"""
  Create a new `ObjectReader` to read existing objects.

  PORTING NOTE: Unsure about the following claim.
  The returned reader is not itself thread-safe, but multiple concurrent
  reader instances created from the same `ObjectDatabase` must be thread-safe.
  """
  @spec new_reader(database :: t) :: ObjectReader.t()
  def new_reader(database)

  # /**
  #  * Close any resources held by this database.
  #  */
  # public abstract void close();

  @doc ~S"""
  Does the requested object exist in this database?

  `type_hint` may be one of the `obj_*` constants from `Constants` or
  the wildcard term `:any` if the caller does not know the object type.
  """
  @spec has_object?(database :: term, object_id :: ObjectId.t(), type_hint :: term) :: boolean
  def has_object?(database, object_id, type_hint \\ :any)

  @doc ~S"""
  Open an object from this database.

  `type_hint` may be one of the `obj_*` constants from `Constants` or
  the wildcard term `:any` if the caller does not know the object type.

  This interface may be faster in practice than calling `new_reader/1`
  and calling its `open/3` function.

  Should return a struct that implements `ObjectLoader` protocol.

  Should raise `MissingObjectError` if no such object exists in the database.
  """
  @spec open(database :: term, object_id :: ObjectId.t(), type_hint :: term) :: ObjectLoader.t()
  def open(database, object_id, type_hint \\ :any)

  # /**
  #  * Create a new cached database instance over this database. This instance might
  #  * optimize queries by caching some information about database. So some modifications
  #  * done after instance creation might fail to be noticed.
  #  *
  #  * @return new cached database instance
  #  */
  # public ObjectDatabase newCachedDatabase() {
  #   return this;
  # }
end
