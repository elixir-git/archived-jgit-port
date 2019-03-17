defmodule Xgit.Test.MockConfigStorage do
  @moduledoc false
  # Used for testing only.

  defstruct ignore: :me
  # We need at least one struct member in order to define a struct,
  # but in this case, it's there only to trigger this implementation
  # of the protocol. The actual content doesn't matter.
end

defimpl Xgit.Lib.Config.Storage, for: Xgit.Test.MockConfigStorage do
  # This "storage" implementation is used so that MockSystemReader can construct
  # Config structs that will accept the `load/1` call, but we don't actually want
  # to pollute the test state with whatever happens to be in the user or system
  # .gitconfig files. So we replace the file-based implementations with no-ops.

  def load(_storage, _config), do: :ok
  def save(_storage, _config), do: :ok
end
