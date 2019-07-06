# Copyright (C) 2009, Google Inc.
# and other copyright owners as documented in the project's IP log.
#
# Elixir adaptation from jgit file:
# org.eclipse.jgit/src/org/eclipse/jgit/lib/ObjectDatabase.java
#
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

defmodule Xgit.Lib.ObjectDatabase do
  @moduledoc ~S"""
  Abstraction of arbitrary object storage.

  An object database stores one or more git objects, indexed by their unique
  Object ID.
  """
  use GenServer

  require Logger

  @type t :: pid

  @doc """
  Starts an `ObjectDatabase` process linked to the current process.

  ## Parameters

  `module` is the name of a module that implements the callbacks defined in this module.

  `init_arg` is passed to the `init/1` function of `module`.

  `options` are passed to `GenServer.start_link/3`.

  ## Return Value

  See `GenServer.start_link/3`.
  """
  @spec start_link(module :: module, init_arg :: term, GenServer.options()) ::
          GenServer.on_start()
  def start_link(module, init_arg, options) when is_atom(module) and is_list(options),
    do: GenServer.start_link(__MODULE__, {module, init_arg}, options)

  @impl true
  def init({mod, mod_init_arg}) do
    case mod.init(mod_init_arg) do
      {:ok, state} -> {:ok, {mod, state}}
      {:stop, reason} -> {:stop, reason}
    end
  end

  @doc ~S"""
  Returns `true` if the argument is a PID representing a valid `ObjectDatabase` process.
  """
  @spec valid?(database :: term) :: boolean
  def valid?(database) when is_pid(database) do
    Process.alive?(database) &&
      GenServer.call(database, :valid_object_database?) == :valid_object_database
  end

  def valid?(_), do: false

  # TO DO: https://github.com/elixir-git/xgit/issues/132

  @doc ~S"""
  Returns `true` if this database exists.
  """
  @spec exists?(database :: t) :: boolean
  def exists?(database) when is_pid(database), do: GenServer.call(database, :exists?)

  @doc ~S"""
  Invoked when `exists?/1` is called on this database.

  ## Return Value

  Should return `{true, mod_state}` if the database exists or `{false, mod_state}` if not.
  """
  @callback handle_exists?(state :: term) :: {exists? :: boolean, state :: term}

  @doc ~S"""
  Initialize a new object database.

  ## Return Value

  `:ok`

  ## Errors

  May raise `File.Error` or similar if the database could not be created.
  """
  @spec create!(database :: t) :: :ok
  def create!(database) when is_pid(database), do: GenServer.call(database, :create)

  @doc ~S"""
  Invoked when `create!/1` is called on this database.

  Should initialize a new reference database at this location.

  ## Return Value

  Should return `{:ok, mod_state}` for function chaining or (TBD) if not.

  _TO DO:_ Finalize error-handling strategy here. https://github.com/elixir-git/xgit/issues/132

  ## Error

  May raise `File.Error` or similar if the database could not be created.
  """
  @callback handle_create(state :: term) :: {:ok, state :: term} | {:error, reason :: term}

  # /**
  #  * Create a new {@code ObjectInserter} to insert new objects.
  #  * <p>
  #  * The returned inserter is not itself thread-safe, but multiple concurrent
  #  * inserter instances created from the same {@code ObjectDatabase} must be
  #  * thread-safe.
  #  *
  #  * @return writer the caller can use to create objects in this database.
  #  */
  # public abstract ObjectInserter newInserter();
  #
  # /**
  #  * Create a new {@code ObjectReader} to read existing objects.
  #  * <p>
  #  * The returned reader is not itself thread-safe, but multiple concurrent
  #  * reader instances created from the same {@code ObjectDatabase} must be
  #  * thread-safe.
  #  *
  #  * @return reader the caller can use to load objects from this database.
  #  */
  # public abstract ObjectReader newReader();
  #
  # /**
  #  * Close any resources held by this database.
  #  */
  # public abstract void close();
  #
  # /**
  #  * Does the requested object exist in this database?
  #  * <p>
  #  * This is a one-shot call interface which may be faster than allocating a
  #  * {@link #newReader()} to perform the lookup.
  #  *
  #  * @param objectId
  #  *            identity of the object to test for existence of.
  #  * @return true if the specified object is stored in this database.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # public boolean has(AnyObjectId objectId) throws IOException {
  #   try (ObjectReader or = newReader()) {
  #     return or.has(objectId);
  #   }
  # }
  #
  # /**
  #  * Open an object from this database.
  #  * <p>
  #  * This is a one-shot call interface which may be faster than allocating a
  #  * {@link #newReader()} to perform the lookup.
  #  *
  #  * @param objectId
  #  *            identity of the object to open.
  #  * @return a {@link org.eclipse.jgit.lib.ObjectLoader} for accessing the object.
  #  * @throws MissingObjectException
  #  *             the object does not exist.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # public ObjectLoader open(AnyObjectId objectId)
  #     throws IOException {
  #   return open(objectId, ObjectReader.OBJ_ANY);
  # }
  #
  # /**
  #  * Open an object from this database.
  #  * <p>
  #  * This is a one-shot call interface which may be faster than allocating a
  #  * {@link #newReader()} to perform the lookup.
  #  *
  #  * @param objectId
  #  *            identity of the object to open.
  #  * @param typeHint
  #  *            hint about the type of object being requested, e.g.
  #  *            {@link org.eclipse.jgit.lib.Constants#OBJ_BLOB};
  #  *            {@link org.eclipse.jgit.lib.ObjectReader#OBJ_ANY} if the
  #  *            object type is not known, or does not matter to the caller.
  #  * @return a {@link org.eclipse.jgit.lib.ObjectLoader} for accessing the
  #  *         object.
  #  * @throws org.eclipse.jgit.errors.MissingObjectException
  #  *             the object does not exist.
  #  * @throws org.eclipse.jgit.errors.IncorrectObjectTypeException
  #  *             typeHint was not OBJ_ANY, and the object's actual type does
  #  *             not match typeHint.
  #  * @throws java.io.IOException
  #  *             the object store cannot be accessed.
  #  */
  # public ObjectLoader open(AnyObjectId objectId, int typeHint)
  #     throws MissingObjectException, IncorrectObjectTypeException,
  #     IOException {
  #   try (ObjectReader or = newReader()) {
  #     return or.open(objectId, typeHint);
  #   }
  # }
  #
  # /**
  #  * Create a new cached database instance over this database. This instance might
  #  * optimize queries by caching some information about database. So some modifications
  #  * done after instance creation might fail to be noticed.
  #  *
  #  * @return new cached database instance
  #  */
  # public ObjectDatabase newCachedDatabase() {
  #   return this;
  # }

  @impl true
  def handle_call(:valid_object_database?, _from, state),
    do: {:reply, :valid_object_database, state}

  def handle_call(:exists?, _from, {mod, mod_state}) do
    case mod.handle_exists?(mod_state) do
      {true, mod_state} -> {:reply, true, {mod, mod_state}}
      {false, mod_state} -> {:reply, false, {mod, mod_state}}
    end
  end

  def handle_call(:create, _from, {mod, mod_state}) do
    case mod.handle_create(mod_state) do
      {:ok, mod_state} -> {:reply, :ok, {mod, mod_state}}
      {:error, reason} -> {:stop, reason}
    end
  end

  def handle_call(message, from, {mod, mod_state}) do
    {:reply, dir, mod_state} = mod.handle_extra_call(message, from, mod_state)
    {:reply, dir, {mod, mod_state}}
  end

  @doc ~S"""
  Respond to any messages that may not be handled by `ObjectDatabase`'s
  `handle_call/3` function.

  See `c:GenServer.handle_call/3`.
  """
  @callback handle_extra_call(message :: term, from :: pid, state :: term) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason, reply, new_state}
              | {:stop, reason, new_state}
            when reply: term(), new_state: term(), reason: term()

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      use GenServer, opts

      alias Xgit.Lib.ObjectDatabase

      require Logger

      @behaviour Xgit.Lib.ObjectDatabase

      @impl true
      def handle_extra_call(message, _from, state) do
        Logger.warn("ObjectDatabase received unrecognized call #{inspect(message)}")
        {:reply, {:error, :unknown_message}, state}
      end

      defoverridable handle_extra_call: 3
    end
  end
end
