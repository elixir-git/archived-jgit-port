defmodule Xgit.Util.GenServerUtils do
  @moduledoc ~S"""
  Some utilities to make error handling in GenServer calls easier.

  Xgit is somewhat more exception-friendly than typical Elixir code
  """

  @doc ~S"""
  Starts a `GenServer` process linked to the current process.

  Raises if the process fails to start.
  """
  def start_link!(module, init_arg, options \\ []) do
    {:ok, pid} = GenServer.start_link(module, init_arg, options)
    pid
  end

  @doc ~S"""
  Makes a synchronous call to the server and waits for its reply.

  If the response is `:ok`, return `server` (for function chaining).

  If the response is `{:ok, (value)}`, return `value`.

  If the response is `{:error, (reason)}`, raise `reason` as an error.
  """
  def call!(server, request, timeout \\ 5000) do
    case GenServer.call(server, request, timeout) do
      :ok -> server
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @doc ~S"""
  Delegate a `handle_call/3` call to a `handle_(something)` call on a module.

  Wraps common `:ok` and error responses and exceptions and returns them to caller.
  """
  def delegate_call_to(mod, function, args, mod_state) do
    try do
      case apply(mod, function, args) do
        {:ok, mod_state} -> {:reply, :ok, {mod, mod_state}}
        {:ok, response, mod_state} -> {:reply, {:ok, response}, {mod, mod_state}}
        {:error, reason, mod_state} -> {:reply, {:error, reason}, {mod, mod_state}}
      end
    rescue
      e -> {:reply, {:error, e}, {mod, mod_state}}
    end
  end
end
