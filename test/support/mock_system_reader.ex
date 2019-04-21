defmodule Xgit.Test.MockSystemReader do
  @moduledoc false
  # Used for testing only.

  defstruct hostname: "fake.host.example.com",
            env: %{},
            user_config: nil,
            system_config: nil,
            time_agent: nil

  alias Xgit.Lib.Config
  alias Xgit.Test.MockConfigStorage

  def new do
    {:ok, time_agent} = Agent.start_link(1_250_379_778_668_000)
    # ^ time is Sat Aug 15 20:12:58 GMT-03:30 2009

    %__MODULE__{
      user_config: Config.new(storage: %MockConfigStorage{}),
      system_config: Config.new(storage: %MockConfigStorage{}),
      time_agent: time_agent
    }
  end

  # Adjust the current time by _n_ seconds.
  def tick(%{time_agent: time_agent}, seconds) do
    Agent.get_and_update(time_agent, fn existing_time ->
      new_time = existing_time + seconds * 1_000_000
      {new_time, new_time}
    end)
  end
end

defimpl Xgit.Util.SystemReader, for: Xgit.Test.MockSystemReader do
  alias Xgit.Lib.Config
  alias Xgit.Test.MockSystemReader

  def hostname(%{hostname: hostname}), do: hostname
  def get_env(%{env: env}, variable), do: Map.get(env, variable)

  def user_config(%MockSystemReader{user_config: user_config} = _reader, nil = _parent_config),
    do: user_config

  def user_config(%MockSystemReader{user_config: user_config} = _reader, %Config{storage: nil}),
    do: user_config

  # Assume in this case that the idle system config will never be written to.
  # This is probably for testing.

  def system_config(
        %MockSystemReader{system_config: system_config} = _reader,
        nil = _parent_config
      ) do
    system_config
  end

  def current_time(%{time_agent: time_agent}) do
    time_agent
    |> Agent.get(& &1)
    |> Kernel.div(1000)
  end

  def clock(reader), do: reader

  def timezone_at_time(_, _time), do: -210
  def timezone(_), do: -210
  # Offset in the mock is GMT-03:30.
end

defimpl Xgit.Util.Time.MonotonicClock, for: Xgit.Test.MockSystemReader do
  # We impmlement the MonotonicClock protocol directly on MockSystemReader
  # because it needs to access "current time" state from MockSystemReader's
  # time agent.

  alias Xgit.Test.MockSystemReader
  alias Xgit.Util.SystemReader

  def propose(%MockSystemReader{} = system_reader) do
    t = SystemReader.current_time(system_reader)
    %Xgit.Test.MockProposedTime{time: t}
  end
end
