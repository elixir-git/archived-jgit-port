defmodule Xgit.Util.MockSystemReader do
  @moduledoc false
  # Used for testing only.

  defstruct hostname: "fake.host.example.com",
            env: %{},
            user_config: nil,
            system_config: nil,
            time: 1_250_379_778_668

  # time == Sat Aug 15 20:12:58 GMT-03:30 2009

  # Adjust the current time by _n_ seconds.
  def tick(%{time: time} = mock, seconds), do: %{mock | time: time + seconds * 1000}
end

defimpl Xgit.Util.SystemReader, for: Xgit.Util.MockSystemReader do
  alias Xgit.Util.MockSystemReader

  def hostname(%{hostname: hostname}), do: hostname
  def get_env(%{env: env}, variable), do: Map.get(env, variable)

  def user_config(%MockSystemReader{user_config: user_config} = _reader, nil = _parent_config),
    do: user_config

  def system_config(
        %MockSystemReader{system_config: system_config} = _reader,
        nil = _parent_config
      ),
      do: system_config

  def current_time(%{time: time}), do: time
end
