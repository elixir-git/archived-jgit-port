defmodule Xgit.Util.Time.MonotonicSystemClockTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.Time.MonotonicClock
  alias Xgit.Util.Time.MonotonicSystemClock
  alias Xgit.Util.Time.ProposedTimestamp

  test "propose/1" do
    msc = %MonotonicSystemClock{}

    assert %{} = proposed = MonotonicClock.propose(msc)

    now = ProposedTimestamp.read(proposed, :microsecond)
    assert is_integer(now) and now > 0
  end
end
