defmodule Xgit.Test.MockProposedTime do
  @moduledoc false
  # Used for testing only.
  # Implements a timestamp from a fixed initial timestamp.

  @enforce_keys [:time]
  defstruct [:time]
end

defimpl Xgit.Util.Time.ProposedTimestamp.Impl, for: Xgit.Test.MockProposedTime do
  def read(%{time: time}), do: time
end
