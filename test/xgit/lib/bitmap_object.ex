defprotocol Xgit.Lib.BitmapObject do
  @moduledoc ~S"""
  This protocol defines an object type accessed during bitmap expansion.
  """

  @doc ~S"""
  Get git object type. See `Xgit.Lib.Constants`.
  """
  def type(bitmap_object)

  @doc ~S"""
  Get the name (object ID) of this object.
  """
  def object_id(bitmap_object)
end
