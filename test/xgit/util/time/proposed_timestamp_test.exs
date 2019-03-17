defmodule Xgit.Util.Time.ProposedTimestampTest do
  use ExUnit.Case, async: true

  alias Xgit.Util.Time.ProposedTimestamp
  alias Xgit.Test.MockProposedTime

  describe "read/2" do
    setup do
      mock_time = %MockProposedTime{time: 1_250_379_778_668_345}
      # time == Sat Aug 15 20:12:58 GMT-03:30 2009
      {:ok, mock_time: mock_time}
    end

    test ":seconds", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :second) == 1_250_379_778
    end

    test ":millisecond", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :millisecond) == 1_250_379_778_668
    end

    test ":microsecond", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, :microsecond) == 1_250_379_778_668_345
    end

    test "arbitrary divisor", %{mock_time: mock_time} do
      assert ProposedTimestamp.read(mock_time, 10_000) == 125_037_977_866
    end
  end
end
