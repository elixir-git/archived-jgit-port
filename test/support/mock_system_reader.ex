defmodule Xgit.Test.MockSystemReader do
  @moduledoc false
  # Used for testing only.

  alias Xgit.Lib.Config
  alias Xgit.Test.MockConfigStorage

  defstruct hostname: "fake.host.example.com",
            env: %{},
            user_config: nil,
            system_config: nil,
            time_agent: nil

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
  alias Xgit.Test.MockSystemReader

  def hostname(%{hostname: hostname}), do: hostname
  def get_env(%{env: env}, variable), do: Map.get(env, variable)

  def user_config(%MockSystemReader{user_config: user_config} = _reader, nil = _parent_config) do
    user_config
  end

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
end
