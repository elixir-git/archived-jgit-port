defprotocol Xgit.Util.Time.MonotonicClock do
  @moduledoc ~S"""
  A provider of time.

  Clocks should provide wall clock time, obtained from a reasonable clock
  source, such as the local system clock.

  `MonotonicClock`s provide the following behavior, with the assertion always
  being true if `ProposedTimestamp.block_until/2` (not yet implemented) is used:

  ```
  clk = ... # struct that implements MonotonicClock

  %ProposedTimestamp{} = t1 = MonotonicClock.propose(clk)
  r1 = ProposedTimestamp.read(t1, :millisecond)
  ProposedTimestamp.block_until(t1, ...)

  %ProposedTimestamp{} = t2 = MonotonicClock.propose(clk)
  r2 = ProposedTimestamp.read(t2, :millisecond)

  assert r2 > r1
  ```
  """

  @doc ~S"""
  Obtain a timestamp close to "now".

  Proposed times are close to "now", but may not yet be certainly in the
  past. This allows the calling thread to interleave other useful work
  while waiting for the clock instance to create an assurance it will never
  in the future propose a time earlier than the returned time.

  A hypothetical implementation could read the local system clock (managed
  by NTP) and return that proposal, concurrently sending network messages
  to closely collaborating peers in the same cluster to also ensure their
  system clocks are ahead of this time. In such an implementation the
  `ProposedTimestamp.block_until/2` implementation would wait for replies
  from the peers indicating their own system clocks have moved past the
  proposed time.

  Should return a struct that implements `ProposedTimestamp`.
  """
  def propose(clock)
end
