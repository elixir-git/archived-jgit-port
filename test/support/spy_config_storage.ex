# Defined here so it is in MIX_ENV=test compile path.
# Otherwise, we miss the window of opportunity for protocol consolidation.

defmodule Xgit.Lib.Config.SpyStorage do
  defstruct [:test_pid]
end

defimpl Xgit.Lib.Config.Storage, for: Xgit.Lib.Config.SpyStorage do
  def load(%Xgit.Lib.Config.SpyStorage{test_pid: test_pid}, config),
    do: send(test_pid, {:load, config})

  def save(%Xgit.Lib.Config.SpyStorage{test_pid: test_pid}, config),
    do: send(test_pid, {:save, config})
end
