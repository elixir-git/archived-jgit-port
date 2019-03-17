defmodule Xgit.Util.Time.MonotonicSystemClock do
  @moduledoc ~S"""
  An implementation of `MonotonicClock` that naively uses the system clock.

  PORTING NOTE: We do not currently validate that the system clock has not
  rolled back. See `nowMicros` in the jgit implementation.
  """

  defstruct ignore: :me
  # We need at least one struct member in order to define a struct,
  # but in this case, it's there only to trigger this implementation
  # of the protocol. The actual content doesn't matter.

  defmodule FixedTimestamp do
    @moduledoc false
    # Implementation detail. Not intended for broader consumption.

    defstruct [:now]
  end
end

defimpl Xgit.Util.Time.ProposedTimestamp.Impl,
  for: Xgit.Util.Time.MonotonicSystemClock.FixedTimestamp do
  def read(%{now: now}), do: now
end

defimpl Xgit.Util.Time.MonotonicClock, for: Xgit.Util.Time.MonotonicSystemClock do
  def propose(_clock) do
    %Xgit.Util.Time.MonotonicSystemClock.FixedTimestamp{now: System.os_time(:microsecond)}
  end
end
