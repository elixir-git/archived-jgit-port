# Copyright (C) 2019, Eric Scouten <eric+xgit@scouten.com>
#
# This program and the accompanying materials are made available
# under the terms of the Eclipse Distribution License v1.0 which
# accompanies this distribution, is reproduced below, and is
# available at http://www.eclipse.org/org/documents/edl-v10.php
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# - Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# - Redistributions in binary form must reproduce the above
#   copyright notice, this list of conditions and the following
#   disclaimer in the documentation and/or other materials provided
#   with the distribution.
#
# - Neither the name of the Eclipse Foundation, Inc. nor the
#   names of its contributors may be used to endorse or promote
#   products derived from this software without specific prior
#   written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

defmodule Xgit.Util.GenServerUtils do
  @moduledoc ~S"""
  Some utilities to make error handling in `GenServer` calls easier.

  Xgit is somewhat more exception-friendly than typical Elixir code.
  """

  @doc ~S"""
  Makes a synchronous call to the server and waits for its reply.

  ## Return Value

  If the response is `:ok`, return `server` (for function chaining).

  If the response is `{:ok, (value)}`, return `value`.

  If the response is `{:error, (reason)}`, raise `reason` as an error.
  """
  @spec call!(server :: GenServer.server(), request :: term, timeout :: non_neg_integer) :: term
  def call!(server, request, timeout \\ 5000) do
    case GenServer.call(server, request, timeout) do
      :ok -> server
      {:ok, value} -> value
      {:error, reason} -> raise reason
    end
  end

  @doc ~S"""
  Wrap a `handle_call/3` call to a `handle_(something)` call on a module.

  Wraps common `:ok` and error responses and exceptions and returns them to caller.

  Should be used for standalone modules (i.e. modules that are not open to extension).
  """
  @spec wrap_call(mod :: module, function :: atom, args :: term, prev_state :: term) ::
          {:reply, term, term}
  def wrap_call(mod, function, args, prev_state) do
    case apply(mod, function, args) do
      {:ok, state} -> {:reply, :ok, state}
      {:ok, response, state} -> {:reply, {:ok, response}, state}
      {:error, reason, state} -> {:reply, {:error, reason}, state}
    end
  rescue
    e -> {:reply, {:error, e}, prev_state}
  end

  @doc ~S"""
  Delegate a `handle_call/3` call to a `handle_(something)` call on a module.

  Wraps common `:ok` and error responses and exceptions and returns them to caller.

  Unlike `wrap_call/4`, assumes that the `GenServer` state is a tuple of
  `{module, mod_state}` and re-wraps module state accordingly.
  """
  @spec delegate_call_to(mod :: module, function :: atom, args :: term, mod_state :: term) ::
          {:reply, term, {module, term}}
  def delegate_call_to(mod, function, args, mod_state) do
    case apply(mod, function, args) do
      {:ok, mod_state} -> {:reply, :ok, {mod, mod_state}}
      {:ok, response, mod_state} -> {:reply, {:ok, response}, {mod, mod_state}}
      {:error, reason, mod_state} -> {:reply, {:error, reason}, {mod, mod_state}}
    end
  rescue
    e -> {:reply, {:error, e}, {mod, mod_state}}
  end
end
