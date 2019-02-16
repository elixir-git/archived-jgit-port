defprotocol Xgit.Lib.Ref do
  @moduledoc ~S"""
  Pairing of a name and the `Xgit.Lib.ObjectId` it currently has.

  A ref in Git is (more or less) a variable that holds a single object identifier.
  The object identifier can be any valid Git object (blob, tree, commit,
  annotated tag, ...).

  The ref name has the attributes of the ref that was asked for as well as the
  ref it was resolved to for symbolic refs plus the object id it points to and
  (for tags) the peeled target object id, i.e. the tag resolved recursively
  until a non-tag object is referenced.
  """

  @typedoc ~S"""
  Location where a `Ref` is stored. One of the following values:

  * `:new`: The ref does not exist yet, updating it may create it. Creation is
    likely to choose `:loose` storage.

  * `:loose`: The ref is stored in a file by itself. Updating this ref affects
    only this ref.

  * `:packed`: The ref is stored in the `packed-refs` file, with others. Updating
    this ref requires rewriting the file, with perhaps many other refs being
    included at the same time.

  * `:loose_packed`: The ref is both `:loose` and `:packed`. Updating this ref
    requires only updating the loose file, but deletion requires updating both
    the loose file and the packed refs file.

  * `:network`: The ref came from a network advertisement and storage is unknown.
    This ref cannot be updated without Git-aware support on the remote side, as
    Git-aware code consolidate the remote refs and reported them to this process.
  """
  @type storage :: :new | :loose | :packed | :loose_packed | :network

  @doc ~S"What this ref is called within the repository."
  @spec name(ref :: term) :: String.t()
  def name(ref)

  @doc ~S"""
  Is this reference a symbolic reference?

  A symbolic reference does not have its own `ObjectId` value, but instead
  points to another `Ref` in the same database and always uses that other
  reference's value as its own.
  """
  @spec symbolic?(ref :: term) :: boolean()
  def symbolic?(ref)

  @doc ~S"""
  Recursively traverse target references until `symbolic?/1` is `false`.
  """
  @spec leaf(ref :: term) :: Ref.t()
  def leaf(ref)

  @doc ~S"""
  Get the reference this reference points to or `ref` itself.

  If `symbolic?/1` is `true` this method returns the reference it directly names,
  which might not be the leaf reference, but could be another symbolic reference.

  If this is a leaf level reference that contains its own object ID, this method
  returns `ref`.
  """
  @spec target(ref :: term) :: Ref.t()
  def target(ref)

  @doc ~S"""
  Cached value of this ref.

  Returns the value of this Ref at the last time we read it. May be `nil` to
  indicate a ref that does not exist yet or a symbolic ref pointing to an unborn
  branch.
  """
  @spec object_id(ref :: term) :: ObjectId.t()
  def object_id(ref)

  @doc ~S"""
  Cached value of `ref^{}` (the ref peeled to commit).

  If this ref is an annotated tag the id of the commit (or tree or blob) that
  the annotated tag refers to; `nil` if this ref does not refer to an annotated tag.
  """
  @spec peeled_object_id(ref :: term) :: ObjectID.t() | nil
  def peeled_object_id(ref)

  @doc ~S"""
  Returns `true` if the Ref represents a peeled tag.
  """
  @spec peeled?(ref :: term) :: boolean
  def peeled?(ref)

  @doc ~S"""
  How was this ref obtained?

  The current storage model of a Ref may influence how the ref must be updated
  or deleted from the repository.

  See `t:storage/0`.
  """
  @spec storage(ref :: term) :: storage
  def storage(ref)

  @doc ~S"""
  Indicator of the relative order between updates of a specific reference
  name. A number that increases when a reference is updated.

  With symbolic references, the update index refers to updates of the symbolic
  reference itself. For example, if `HEAD` points to `refs/heads/master`, then
  the update index for `exact_ref("HEAD")` will only increase when `HEAD` changes
  to point to another ref, regardless of how many times `refs/heads/master` is updated.

  Should not be used unless the `RefDatabase` that instantiated the ref supports
  versioning. (See `RefDatabase.has_versioning?/1`.)

  Can throw `RuntimeError` if the creator of the instance (e.g. `RefDatabase`)
  doesn't support versioning.
  """
  @spec update_index(ref :: term) :: number
  def update_index(ref)
end