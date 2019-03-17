# Defined here so it is in MIX_ENV=test compile path.
# Otherwise, we miss the window of opportunity for protocol consolidation.

defmodule Xgit.Test.SpyStorage do
  @moduledoc false
  # Used by Xgit.Lib.ConfigTest to verify Config module's interaction
  # with Storage protocol.

  defstruct [:test_pid]
end

defimpl Xgit.Lib.Config.Storage, for: Xgit.Test.SpyStorage do
  def load(%Xgit.Test.SpyStorage{test_pid: test_pid}, config),
    do: send(test_pid, {:load, config})

  def save(%Xgit.Test.SpyStorage{test_pid: test_pid}, config),
    do: send(test_pid, {:save, config})
end
