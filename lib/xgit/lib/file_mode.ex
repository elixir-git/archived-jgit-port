defmodule Xgit.Lib.FileMode do
  @moduledoc ~S"""
  Constants describing various file modes recognized by git.

  git uses a subset of the available Unix file permission bits. The `FileMode`
  module provides access to constants defining the modes actually used by git.
  """
  @enforce_keys [:mode_bits, :object_type, :octal_bytes]
  defstruct [:mode_bits, :object_type, :octal_bytes]

  alias Xgit.Lib.Constants

  use Bitwise, skip_operators: true

  @doc "Mask to apply to a file mode to obtain its type bits."
  def type_mask, do: 0o170000

  @doc "Bit pattern for `type_mask/0` matching `tree/0`."
  def type_tree, do: 0o040000

  @doc "Bit pattern for `type_mask/0` matching `symlink/0`."
  def type_symlink, do: 0o120000

  @doc "Bit pattern for `type_mask/0` matching `regular_file/0`."
  def type_file, do: 0o100000

  @doc "Bit pattern for `type_mask/0` matching `gitlink/0`."
  def type_gitlink, do: 0o160000

  @doc "Bit pattern for `type_mask/0` matching `missing/0`."
  def type_missing, do: 0o000000

  @doc "Mode indicating an entry is a tree (aka directory)."
  def tree, do: new(type_tree(), Constants.obj_tree())

  @doc "Mode indicating an entry is a symbolic link."
  def symlink, do: new(type_symlink(), Constants.obj_blob())

  @doc "Mode indicating an entry is a non-executable file."
  def regular_file, do: new(0o100644, Constants.obj_blob())

  @doc "Mode indicating an entry is an executable file."
  def executable_file, do: new(0o100755, Constants.obj_blob())

  @doc "Mode indicating an entry is a submodule commit in another repository."
  def gitlink, do: new(type_gitlink(), Constants.obj_commit())

  @doc "Mode indicating an entry is missing during parallel walks."
  def missing, do: new(type_missing(), Constants.obj_bad())

  @doc ~S"""
  Test a file mode for equality with this `FileMode` struct.
  """
  def match_mode_bits?(file_mode, mode_bits)

  def match_mode_bits?(%__MODULE__{mode_bits: 0o100644}, mode_bits),
    do: band(mode_bits, type_mask()) == type_file() && band(mode_bits, 0o111) == 0

  def match_mode_bits?(%__MODULE__{mode_bits: 0o100755}, mode_bits),
    do: band(mode_bits, type_mask()) == type_file() && band(mode_bits, 0o111) != 0

  def match_mode_bits?(%__MODULE__{mode_bits: 0o000000}, mode_bits),
    do: mode_bits == 0

  def match_mode_bits?(%__MODULE__{mode_bits: self_mode_bits}, other_mode_bits),
    do: self_mode_bits == other_mode_bits

  @doc ~S"""
  Convert a set of mode bits into a `FileMode` enumerated value.
  """
  def from_bits(bits), do: bits |> band(type_mask()) |> from_type_bits(bits)

  defp from_type_bits(0o000000, 0), do: missing()
  defp from_type_bits(0o040000, _), do: tree()
  defp from_type_bits(0o100000, bits) when band(bits, 0o111) != 0, do: executable_file()
  defp from_type_bits(0o100000, _), do: regular_file()
  defp from_type_bits(0o120000, _), do: symlink()
  defp from_type_bits(0o160000, _), do: gitlink()
  defp from_type_bits(_, bits), do: new(bits, Constants.obj_bad())

  defp new(mode, object_type) do
    %__MODULE__{
      mode_bits: mode,
      object_type: object_type,
      octal_bytes: octal_bytes_from_mode(mode)
    }
  end

  defp octal_bytes_from_mode(0), do: '0'
  defp octal_bytes_from_mode(mode), do: octal_bytes_from_mode(mode, [])

  defp octal_bytes_from_mode(0, bytes), do: bytes

  defp octal_bytes_from_mode(mode, bytes),
    do: octal_bytes_from_mode(bsr(mode, 3), [band(mode, 0x7) + ?0 | bytes])
end

defimpl String.Chars, for: Xgit.Lib.FileMode do
  def to_string(%Xgit.Lib.FileMode{octal_bytes: octal_bytes}), do: Kernel.to_string(octal_bytes)
end
