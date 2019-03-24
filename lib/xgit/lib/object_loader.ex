defprotocol Xgit.Lib.ObjectLoader do
  @moduledoc ~S"""
  Protocol that allows for different storage representations of git objects.
  """

  @doc ~S"""
  Get in-pack object type.

  See `Constants.obj_*`.
  """
  def type(loader)

  @doc ~S"""
  Get the size of the object in bytes.
  """
  def size(loader)

  @doc ~S"""
  Return `true` if this object is too large to obtain as a byte array.

  If so, the caller should use a stream returned by `open_stream/1` to
  prevent overflowing the VM heap.
  """
  def large?(loader)

  @doc ~S"""
  Obtain the (possibly cached) bytes of this object.

  This function offers direct access to the internal caches, potentially
  saving on data copies between the internal cache and higher level code.
  """
  def cached_bytes(loader)

  @doc ~S"""
  Obtain an `Enumerable` (typically a stream) to read this object's data.
  """
  def stream(loader)

  # PORTING NOTE: It is expected that the `copyTo` function in jgit's ObjectLoader
  # class can be mimiced by using `Sream.into/1`, so it's unnecessary to port it.
end
