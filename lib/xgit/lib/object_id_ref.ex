defmodule Xgit.Lib.ObjectIdRef do
  @moduledoc ~S"""
  A `Ref` that points directly at an `ObjectId`.

  Struct members:
  * `name`: name of this ref
  * `storage`: method used to store this ref (See `t:Xgit.Lib.Ref.storage/0`.)
  * `object_id`: current value of the ref. May be `nil` to indicate a ref that
    does not exist yet.
  * `peeled?`: `true` if the ref has been peeled (implied if `peeled_object_id` is not `nil`)
  * `peeled_object_id`: current peeled value of the ref. If `nil`, indicates that
    the object ref hasn't been peeled yet.
  * `tag?`: `true` if the peeled value points to a tag
  * `update_index`: number that increases with each ref update. Set to `:undefined` if the
    storage doesn't support versioning.
  """

  @enforce_keys [:name, :storage]
  defstruct [
    :name,
    :storage,
    :object_id,
    :peeled?,
    :peeled_object_id,
    :tag?,
    update_index: :undefined
  ]
end

defimpl Xgit.Lib.Ref, for: Xgit.Lib.ObjectIdRef do
  alias Xgit.Lib.ObjectIdRef

  def name(%ObjectIdRef{name: name}), do: name
  def symbolic?(_), do: false
  def leaf(ref), do: ref
  def target(ref), do: ref
  def object_id(%ObjectIdRef{object_id: object_id}), do: object_id

  def peeled_object_id(%ObjectIdRef{tag?: true, peeled_object_id: peeled_object_id}),
    do: peeled_object_id

  def peeled_object_id(_), do: nil

  def peeled?(%ObjectIdRef{peeled?: true}), do: true
  def peeled?(%ObjectIdRef{peeled_object_id: nil}), do: false
  def peeled?(_), do: true

  def storage(%ObjectIdRef{storage: storage}), do: storage

  def update_index(%ObjectIdRef{update_index: update_index})
      when is_integer(update_index) and update_index > 0,
      do: update_index

  def update_index(_), do: raise(RuntimeError, "update_index is invalid")
end

defimpl String.Chars, for: Xgit.Lib.ObjectIdRef do
  def to_string(%Xgit.Lib.ObjectIdRef{
        name: name,
        object_id: object_id,
        update_index: update_index
      }),
      do: "Ref[#{name}=#{object_id}(#{update_index})]"
end
