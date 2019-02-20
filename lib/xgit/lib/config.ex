defmodule Xgit.Lib.Config do
  @moduledoc ~S"""
  Git style `.config`, `.gitconfig`, `.gitmodules` file.

  IMPORTANT IMPLEMENTATION NOTE: The `Config` module represents a mutable state
  which could easily be shared across multiple client processes. Therefore, we use
  [Swarm process grouping](https://hexdocs.pm/swarm/readme.html#registration-process-grouping)
  to ensure that the lifetime of the server matches the *set* of potentially-interested
  client processes. Client processes  should
  [`Swarm.join/2`](https://hexdocs.pm/swarm/Swarm.html#join/2) the process group
  defined by `:ref` to ensure that the `GenServer`'s lifetime is appropriately
  long.
  """
  @enforce_keys [:ref]
  defstruct [:ref]

  alias Xgit.Errors.ConfigInvalidError
  alias Xgit.Lib.ConfigLine

  use GenServer

  defmodule State do
    @moduledoc false
    @enforce_keys [:config_lines, :ref, :base_config]
    defstruct [:config_lines, :ref, :base_config]
  end

  # Looks like ConfigSnapshot devolves down to a list of %ConfigLine{} structs,
  # so we can merge that functionality into this module as `defp` funcs.

  # private static final String[] EMPTY_STRING_ARRAY = {};

  @kib 1024
  @mib 1024 * @kib
  @gib 1024 * @mib

  @doc ~S"""
  Create a configuration with no default feedback.
  """
  def new do
    ref = make_ref()

    {:ok, _pid} = GenServer.start(__MODULE__, {ref, :new}, name: {:global, {:xgit_config, ref}})

    Swarm.join({:xgit_config, ref}, self())

    %__MODULE__{ref: ref}
  end

  # /**
  #  * Create an empty configuration with a fallback for missing keys.
  #  *
  #  * @param defaultConfig
  #  *            the base configuration to be consulted when a key is missing
  #  *            from this configuration instance.
  #  */
  # public Config(Config defaultConfig) {
  # 	baseConfig = defaultConfig;
  # 	state = new AtomicReference<>(newState());
  # }

  @impl true
  def init({ref, :new}) when is_reference(ref) do
    # TODO: Manage lifetime. (Shut down when Swarm process group becomes empty.)
    {:ok, %__MODULE__.State{config_lines: [], ref: ref, base_config: nil}}
  end

  #
  # /**
  #  * Globally sets a {@link org.eclipse.jgit.lib.TypedConfigGetter} that is
  #  * subsequently used to read typed values from all git configs.
  #  *
  #  * @param getter
  #  *            to use; if {@code null} use the default getter.
  #  * @since 4.9
  #  */
  # public static void setTypedConfigGetter(TypedConfigGetter getter) {
  # 	typedGetter = getter == null ? DEFAULT_GETTER : getter;
  # }
  #
  # /**
  #  * Escape the value before saving
  #  *
  #  * @param x
  #  *            the value to escape
  #  * @return the escaped value
  #  */
  # static String escapeValue(String x) {
  # 	if (x.isEmpty()) {
  # 		return ""; //$NON-NLS-1$
  # 	}
  #
  # 	boolean needQuote = x.charAt(0) == ' ' || x.charAt(x.length() - 1) == ' ';
  # 	StringBuilder r = new StringBuilder(x.length());
  # 	for (int k = 0; k < x.length(); k++) {
  # 		char c = x.charAt(k);
  # 		// git-config(1) lists the limited set of supported escape sequences, but
  # 		// the documentation is otherwise not especially normative. In particular,
  # 		// which ones of these produce and/or require escaping and/or quoting
  # 		// around them is not documented and was discovered by trial and error.
  # 		// In summary:
  # 		//
  # 		// * Quotes are only required if there is leading/trailing whitespace or a
  # 		//   comment character.
  # 		// * Bytes that have a supported escape sequence are escaped, except for
  # 		//   \b for some reason which isn't.
  # 		// * Needing an escape sequence is not sufficient reason to quote the
  # 		//   value.
  # 		switch (c) {
  # 		case '\0':
  # 			// Unix command line calling convention cannot pass a '\0' as an
  # 			// argument, so there is no equivalent way in C git to store a null byte
  # 			// in a config value.
  # 			throw new IllegalArgumentException(
  # 					JGitText.get().configValueContainsNullByte);
  #
  # 		case '\n':
  # 			r.append('\\').append('n');
  # 			break;
  #
  # 		case '\t':
  # 			r.append('\\').append('t');
  # 			break;
  #
  # 		case '\b':
  # 			// Doesn't match `git config foo.bar $'x\by'`, which doesn't escape the
  # 			// \x08, but since both escaped and unescaped forms are readable, we'll
  # 			// prefer internal consistency here.
  # 			r.append('\\').append('b');
  # 			break;
  #
  # 		case '\\':
  # 			r.append('\\').append('\\');
  # 			break;
  #
  # 		case '"':
  # 			r.append('\\').append('"');
  # 			break;
  #
  # 		case '#':
  # 		case ';':
  # 			needQuote = true;
  # 			r.append(c);
  # 			break;
  #
  # 		default:
  # 			r.append(c);
  # 			break;
  # 		}
  # 	}
  #
  # 	return needQuote ? '"' + r.toString() + '"' : r.toString();
  # }
  #
  # static String escapeSubsection(String x) {
  # 	if (x.isEmpty()) {
  # 		return "\"\""; //$NON-NLS-1$
  # 	}
  #
  # 	StringBuilder r = new StringBuilder(x.length() + 2).append('"');
  # 	for (int k = 0; k < x.length(); k++) {
  # 		char c = x.charAt(k);
  #
  # 		// git-config(1) lists the limited set of supported escape sequences
  # 		// (which is even more limited for subsection names than for values).
  # 		switch (c) {
  # 		case '\0':
  # 			throw new IllegalArgumentException(
  # 					JGitText.get().configSubsectionContainsNullByte);
  #
  # 		case '\n':
  # 			throw new IllegalArgumentException(
  # 					JGitText.get().configSubsectionContainsNewline);
  #
  # 		case '\\':
  # 		case '"':
  # 			r.append('\\').append(c);
  # 			break;
  #
  # 		default:
  # 			r.append(c);
  # 			break;
  # 		}
  # 	}
  #
  # 	return r.append('"').toString();
  # }
  #
  # /**
  #  * Obtain an integer value from the configuration.
  #  *
  #  * @param section
  #  *            section the key is grouped within.
  #  * @param name
  #  *            name of the key to get.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @return an integer value from the configuration, or defaultValue.
  #  */
  # public int getInt(final String section, final String name,
  # 		final int defaultValue) {
  # 	return typedGetter.getInt(this, section, null, name, defaultValue);
  # }
  #
  # /**
  #  * Obtain an integer value from the configuration.
  #  *
  #  * @param section
  #  *            section the key is grouped within.
  #  * @param subsection
  #  *            subsection name, such a remote or branch name.
  #  * @param name
  #  *            name of the key to get.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @return an integer value from the configuration, or defaultValue.
  #  */
  # public int getInt(final String section, String subsection,
  # 		final String name, final int defaultValue) {
  # 	return typedGetter.getInt(this, section, subsection, name,
  # 			defaultValue);
  # }

  @doc ~S"""
  Get an integer value from the git config.

  If no value was present, returns `default`.
  """
  def get_int(c, section, subsection \\ nil, name, default)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_integer(default) do
    c
    |> process_ref()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> to_lowercase_if_string()
    |> trim_if_string()
    |> to_number(section, name, default)
  end

  defp replace_empty_with_missing([]), do: [:missing]
  defp replace_empty_with_missing(x), do: x

  defp to_lowercase_if_string(s) when is_binary(s), do: String.downcase(s)
  defp to_lowercase_if_string(x), do: x

  defp trim_if_string(s) when is_binary(s), do: String.trim(s)
  defp trim_if_string(x), do: x

  defp to_number(:missing, _section, _name, default), do: default
  defp to_number(:empty, _section_, _name, default), do: default
  defp to_number("", _section, _name, default), do: default

  defp to_number(s, section, name, _default) do
    case parse_integer_and_strip_whitespace(s) do
      {n, "g"} -> n * @gib
      {n, "m"} -> n * @mib
      {n, "k"} -> n * @kib
      {n, ""} -> n
      _ -> raise(ConfigInvalidError, "Invalid integer value: #{section}.#{name}=#{s}")
    end
  end

  defp parse_integer_and_strip_whitespace(s) do
    case Integer.parse(s) do
      {n, str} -> {n, String.trim(str)}
      x -> x
    end
  end

  @doc ~S"""
  Get a boolean value from the git config.

  Returns `true` if any value or `default` if `true`; `false` for missing or
  an explicit `false`.
  """
  def get_boolean(c, section, subsection \\ nil, name, default)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_boolean(default) do
    c
    |> process_ref()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> to_lowercase_if_string()
    |> to_boolean(default)
  end

  defp to_boolean(nil, _default), do: true
  defp to_boolean(:empty, _default), do: true
  defp to_boolean(:missing, default), do: default
  defp to_boolean("false", _default), do: false
  defp to_boolean("no", _default), do: false
  defp to_boolean("off", _default), do: false
  defp to_boolean("0", _default), do: false
  defp to_boolean(_, _default), do: true

  # /**
  #  * Parse an enumeration from the configuration.
  #  *
  #  * @param section
  #  *            section the key is grouped within.
  #  * @param subsection
  #  *            subsection name, such a remote or branch name.
  #  * @param name
  #  *            name of the key to get.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @return the selected enumeration value, or {@code defaultValue}.
  #  */
  # public <T extends Enum<?>> T getEnum(final String section,
  # 		final String subsection, final String name, final T defaultValue) {
  # 	final T[] all = allValuesOf(defaultValue);
  # 	return typedGetter.getEnum(this, all, section, subsection, name,
  # 			defaultValue);
  # }
  #
  # @SuppressWarnings("unchecked")
  # private static <T> T[] allValuesOf(T value) {
  # 	try {
  # 		return (T[]) value.getClass().getMethod("values").invoke(null); //$NON-NLS-1$
  # 	} catch (Exception err) {
  # 		String typeName = value.getClass().getName();
  # 		String msg = MessageFormat.format(
  # 				JGitText.get().enumValuesNotAvailable, typeName);
  # 		throw new IllegalArgumentException(msg, err);
  # 	}
  # }
  #
  # /**
  #  * Parse an enumeration from the configuration.
  #  *
  #  * @param all
  #  *            all possible values in the enumeration which should be
  #  *            recognized. Typically {@code EnumType.values()}.
  #  * @param section
  #  *            section the key is grouped within.
  #  * @param subsection
  #  *            subsection name, such a remote or branch name.
  #  * @param name
  #  *            name of the key to get.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @return the selected enumeration value, or {@code defaultValue}.
  #  */
  # public <T extends Enum<?>> T getEnum(final T[] all, final String section,
  # 		final String subsection, final String name, final T defaultValue) {
  # 	return typedGetter.getEnum(this, all, section, subsection, name,
  # 			defaultValue);
  # }

  @doc ~S"""
  Get a single string value from the git config (or `nil` if not found).
  """
  def get_string(c, section, subsection \\ nil, name)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    c
    |> process_ref()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> replace_empty_with_missing()
    |> List.last()
    |> fix_missing_or_nil_string_result()
  end

  defp fix_missing_or_nil_string_result(:missing), do: nil
  defp fix_missing_or_nil_string_result(:empty), do: ""
  defp fix_missing_or_nil_string_result(nil), do: ""
  defp fix_missing_or_nil_string_result(x), do: to_string(x)

  @doc ~S"""
  Get a list of string values from the git config.

  If this instance was created with a base, the base's values (if any) are
  returned first.
  """
  def get_string_list(c, section, subsection \\ nil, name)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    # TODO: Implement base. Still thinking about how that works.
    # String[] base;
    # if (baseConfig != null)
    # 	base = baseConfig.getStringList(section, subsection, name);
    # else
    # 	base = EMPTY_STRING_ARRAY;

    c
    |> process_ref()
    |> GenServer.call({:get_raw_strings, section, subsection, name})
    |> Enum.map(&fix_missing_or_nil_string_result/1)
  end

  # /**
  #  * Parse a numerical time unit, such as "1 minute", from the configuration.
  #  *
  #  * @param section
  #  *            section the key is in.
  #  * @param subsection
  #  *            subsection the key is in, or null if not in a subsection.
  #  * @param name
  #  *            the key name.
  #  * @param defaultValue
  #  *            default value to return if no value was present.
  #  * @param wantUnit
  #  *            the units of {@code defaultValue} and the return value, as
  #  *            well as the units to assume if the value does not contain an
  #  *            indication of the units.
  #  * @return the value, or {@code defaultValue} if not set, expressed in
  #  *         {@code units}.
  #  * @since 4.5
  #  */
  # public long getTimeUnit(String section, String subsection, String name,
  # 		long defaultValue, TimeUnit wantUnit) {
  # 	return typedGetter.getTimeUnit(this, section, subsection, name,
  # 			defaultValue, wantUnit);
  # }
  #
  # /**
  #  * Parse a list of {@link org.eclipse.jgit.transport.RefSpec}s from the
  #  * configuration.
  #  *
  #  * @param section
  #  *            section the key is in.
  #  * @param subsection
  #  *            subsection the key is in, or null if not in a subsection.
  #  * @param name
  #  *            the key name.
  #  * @return a possibly empty list of
  #  *         {@link org.eclipse.jgit.transport.RefSpec}s
  #  * @since 4.9
  #  */
  # public List<RefSpec> getRefSpecs(String section, String subsection,
  # 		String name) {
  # 	return typedGetter.getRefSpecs(this, section, subsection, name);
  # }
  #
  # /**
  #  * Get set of all subsections of specified section within this configuration
  #  * and its base configuration
  #  *
  #  * @param section
  #  *            section to search for.
  #  * @return set of all subsections of specified section within this
  #  *         configuration and its base configuration; may be empty if no
  #  *         subsection exists. The set's iterator returns sections in the
  #  *         order they are declared by the configuration starting from this
  #  *         instance and progressing through the base.
  #  */
  # public Set<String> getSubsections(String section) {
  # 	return getState().getSubsections(section);
  # }

  @doc ~S"""
  Get the sections defined in this `Config`.
  """
  def sections(c), do: c |> process_ref() |> GenServer.call(:sections)

  # IMPORTANT: sections_impl/1 runs in GenServer process.
  # See handle_call/3 below.

  defp sections_impl(config_lines) do
    config_lines
    |> Enum.reject(&(&1.section == nil))
    |> Enum.map(&String.downcase(&1.section))
    |> Enum.dedup()

    # TODO: Dedup globally?
  end

  @doc ~S"""
  Get the list of names defined for this section.
  """
  def names_in_section(c, section) when is_binary(section),
    do: c |> process_ref() |> GenServer.call({:names_in_section, section})

  # IMPORTANT: names_in_section_impl/2 runs in GenServer process.
  # See handle_call/3 below.

  defp names_in_section_impl(config_lines, section) do
    config_lines
    |> Enum.filter(&(&1.section == section))
    |> Enum.reject(&(&1.name == nil))
    |> Enum.map(&String.downcase(&1.name))
    |> Enum.dedup()

    # TODO: Dedup globally?
  end

  @doc ~S"""
  Get the list of names defined for this subsection.
  """
  def names_in_subsection(c, section, subsection)
      when is_binary(section) and is_binary(subsection),
      do: c |> process_ref() |> GenServer.call({:names_in_subsection, section, subsection})

  # IMPORTANT: names_in_subsection_impl/3 runs in GenServer process.
  # See handle_call/3 below.

  defp names_in_subsection_impl(config_lines, section, subsection) do
    config_lines
    |> Enum.filter(&(&1.section == section && &1.subsection == subsection))
    |> Enum.reject(&(&1.name == nil))
    |> Enum.map(&String.downcase(&1.name))
    |> Enum.dedup()

    # TODO: Dedup globally?
  end

  # /**
  #  * Get the list of names defined for this subsection
  #  *
  #  * @param section
  #  *            the section
  #  * @param subsection
  #  *            the subsection
  #  * @return the list of names defined for this subsection
  #  */
  # public Set<String> getNames(String section, String subsection) {
  # 	return getState().getNames(section, subsection);
  # }
  #
  # /**
  #  * Get the list of names defined for this section
  #  *
  #  * @param section
  #  *            the section
  #  * @param recursive
  #  *            if {@code true} recursively adds the names defined in all base
  #  *            configurations
  #  * @return the list of names defined for this section
  #  * @since 3.2
  #  */
  # public Set<String> getNames(String section, boolean recursive) {
  # 	return getState().getNames(section, null, recursive);
  # }
  #
  # /**
  #  * Get the list of names defined for this section
  #  *
  #  * @param section
  #  *            the section
  #  * @param subsection
  #  *            the subsection
  #  * @param recursive
  #  *            if {@code true} recursively adds the names defined in all base
  #  *            configurations
  #  * @return the list of names defined for this subsection
  #  * @since 3.2
  #  */
  # public Set<String> getNames(String section, String subsection,
  # 		boolean recursive) {
  # 	return getState().getNames(section, subsection, recursive);
  # }
  #
  # /**
  #  * Obtain a handle to a parsed set of configuration values.
  #  *
  #  * @param <T>
  #  *            type of configuration model to return.
  #  * @param parser
  #  *            parser which can create the model if it is not already
  #  *            available in this configuration file. The parser is also used
  #  *            as the key into a cache and must obey the hashCode and equals
  #  *            contract in order to reuse a parsed model.
  #  * @return the parsed object instance, which is cached inside this config.
  #  */
  # @SuppressWarnings("unchecked")
  # public <T> T get(SectionParser<T> parser) {
  # 	final ConfigSnapshot myState = getState();
  # 	T obj = (T) myState.cache.get(parser);
  # 	if (obj == null) {
  # 		obj = parser.parse(this);
  # 		myState.cache.put(parser, obj);
  # 	}
  # 	return obj;
  # }
  #
  # /**
  #  * Remove a cached configuration object.
  #  * <p>
  #  * If the associated configuration object has not yet been cached, this
  #  * method has no effect.
  #  *
  #  * @param parser
  #  *            parser used to obtain the configuration object.
  #  * @see #get(SectionParser)
  #  */
  # public void uncache(SectionParser<?> parser) {
  # 	state.get().cache.remove(parser);
  # }
  #
  # /**
  #  * Adds a listener to be notified about changes.
  #  * <p>
  #  * Clients are supposed to remove the listeners after they are done with
  #  * them using the {@link org.eclipse.jgit.events.ListenerHandle#remove()}
  #  * method
  #  *
  #  * @param listener
  #  *            the listener
  #  * @return the handle to the registered listener
  #  */
  # public ListenerHandle addChangeListener(ConfigChangedListener listener) {
  # 	return listeners.addConfigChangedListener(listener);
  # }
  #
  # /**
  #  * Determine whether to issue change events for transient changes.
  #  * <p>
  #  * If <code>true</code> is returned (which is the default behavior),
  #  * {@link #fireConfigChangedEvent()} will be called upon each change.
  #  * <p>
  #  * Subclasses that override this to return <code>false</code> are
  #  * responsible for issuing {@link #fireConfigChangedEvent()} calls
  #  * themselves.
  #  *
  #  * @return <code></code>
  #  */
  # protected boolean notifyUponTransientChanges() {
  # 	return true;
  # }
  #
  # /**
  #  * Notifies the listeners
  #  */
  # protected void fireConfigChangedEvent() {
  # 	listeners.dispatch(new ConfigChangedEvent());
  # }

  defp raw_string_list(%__MODULE__.State{config_lines: config_lines}, section, subsection, name) do
    # TODO: Consider base state.
    config_lines
    |> Enum.filter(&ConfigLine.match?(&1, section, subsection, name))
    |> Enum.map(fn %ConfigLine{value: value} -> value end)
  end

  # private ConfigSnapshot getState() {
  # 	ConfigSnapshot cur, upd;
  # 	do {
  # 		cur = state.get();
  # 		final ConfigSnapshot base = getBaseState();
  # 		if (cur.baseState == base)
  # 			return cur;
  # 		upd = new ConfigSnapshot(cur.entryList, base);
  # 	} while (!state.compareAndSet(cur, upd));
  # 	return upd;
  # }
  #
  # private ConfigSnapshot getBaseState() {
  # 	return baseConfig != null ? baseConfig.getState() : null;
  # }
  #
  # /**
  #  * Add or modify a configuration value. The parameters will result in a
  #  * configuration entry like this.
  #  *
  #  * <pre>
  #  * [section &quot;subsection&quot;]
  #  *         name = value
  #  * </pre>
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  * @param value
  #  *            parameter value
  #  */
  # public void setInt(final String section, final String subsection,
  # 		final String name, final int value) {
  # 	setLong(section, subsection, name, value);
  # }
  #
  # /**
  #  * Add or modify a configuration value. The parameters will result in a
  #  * configuration entry like this.
  #  *
  #  * <pre>
  #  * [section &quot;subsection&quot;]
  #  *         name = value
  #  * </pre>
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  * @param value
  #  *            parameter value
  #  */
  # public void setLong(final String section, final String subsection,
  # 		final String name, final long value) {
  # 	final String s;
  #
  # 	if (value >= GiB && (value % GiB) == 0)
  # 		s = String.valueOf(value / GiB) + "g"; //$NON-NLS-1$
  # 	else if (value >= MiB && (value % MiB) == 0)
  # 		s = String.valueOf(value / MiB) + "m"; //$NON-NLS-1$
  # 	else if (value >= KiB && (value % KiB) == 0)
  # 		s = String.valueOf(value / KiB) + "k"; //$NON-NLS-1$
  # 	else
  # 		s = String.valueOf(value);
  #
  # 	setString(section, subsection, name, s);
  # }
  #
  # /**
  #  * Add or modify a configuration value. The parameters will result in a
  #  * configuration entry like this.
  #  *
  #  * <pre>
  #  * [section &quot;subsection&quot;]
  #  *         name = value
  #  * </pre>
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  * @param value
  #  *            parameter value
  #  */
  # public void setBoolean(final String section, final String subsection,
  # 		final String name, final boolean value) {
  # 	setString(section, subsection, name, value ? "true" : "false"); //$NON-NLS-1$ //$NON-NLS-2$
  # }
  #
  # /**
  #  * Add or modify a configuration value. The parameters will result in a
  #  * configuration entry like this.
  #  *
  #  * <pre>
  #  * [section &quot;subsection&quot;]
  #  *         name = value
  #  * </pre>
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  * @param value
  #  *            parameter value
  #  */
  # public <T extends Enum<?>> void setEnum(final String section,
  # 		final String subsection, final String name, final T value) {
  # 	String n;
  # 	if (value instanceof ConfigEnum)
  # 		n = ((ConfigEnum) value).toConfigValue();
  # 	else
  # 		n = value.name().toLowerCase(Locale.ROOT).replace('_', ' ');
  # 	setString(section, subsection, name, n);
  # }

  @doc ~S"""
  Add or modify a configuration value.

  This parameters will result in a configuration entry like this being added
  (in-memory only):

  ```
  [section "subsection"]
    name = value
  ```
  """
  def set_string(c, section, subsection \\ nil, name, value)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_binary(value) do
    c
    |> process_ref()
    |> GenServer.call({:set_string_list, section, subsection, name, [value]})

    c
  end

  # /**
  #  * Remove a configuration value.
  #  *
  #  * @param section
  #  *            section name, e.g "branch"
  #  * @param subsection
  #  *            optional subsection value, e.g. a branch name
  #  * @param name
  #  *            parameter name, e.g. "filemode"
  #  */
  # public void unset(final String section, final String subsection,
  # 		final String name) {
  # 	setStringList(section, subsection, name, Collections
  # 			.<String> emptyList());
  # }

  @doc ~S"""
  Remove all configuration values under a single section.
  """
  def unset_section(c, section, subsection \\ nil)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) do
    c
    |> process_ref()
    |> GenServer.call({:unset_section, section, subsection})

    c
  end

  # IMPORTANT: unset_section_impl/5 runs in GenServer process.
  # See handle_call/3 below.

  defp unset_section_impl(%__MODULE__.State{config_lines: config_lines}, section, subsection),
    do: Enum.reject(config_lines, &ConfigLine.match_section?(&1, section, subsection))

  @doc ~S"""
  Set a configuration value.

  This parameters will result in a configuration entry like this being added
  (in-memory only):

  ```
  [section "subsection"]
    name = value1
    name = value2
  ```
  """
  def set_string_list(c, section, subsection \\ nil, name, values)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_list(values) do
    c
    |> process_ref()
    |> GenServer.call({:set_string_list, section, subsection, name, values})

    c
  end

  # IMPORTANT: set_string_list_impl/5 runs in GenServer process.
  # See handle_call/3 below.

  def set_string_list_impl(
        %__MODULE__.State{config_lines: old_config_lines},
        section,
        subsection,
        name,
        values
      ) do
    new_config_lines =
      old_config_lines
      |> replace_matching_config_lines(values, [], section, subsection, name)
      |> Enum.reverse()

    # TODO:
    # if (notifyUponTransientChanges())
    # 	fireConfigChangedEvent();

    new_config_lines
  end

  defp replace_matching_config_lines(
         [],
         new_values,
         reversed_new_config_lines,
         section,
         subsection,
         name
       ) do
    new_config_lines =
      new_values
      |> Enum.map(&%ConfigLine{section: section, subsection: subsection, name: name, value: &1})
      |> Enum.reverse()

    # If we can find a matching key in the existing config, we should insert
    # the new config lines after those. Otherwise, attach to EOF.
    case Enum.split_while(
           reversed_new_config_lines,
           &(!ConfigLine.match_section?(&1, section, subsection))
         ) do
      {all, []} -> new_config_lines ++ [create_section_heaader(section, subsection)] ++ all
      {group1, group2} -> group1 ++ new_config_lines ++ group2
    end
  end

  defp replace_matching_config_lines(
         [current | remainder],
         new_values,
         reversed_new_config_lines,
         section,
         subsection,
         name
       ) do
    if ConfigLine.match?(current, section, subsection, name) do
      {new_values, new_config_lines} =
        consume_next_matching_config_line(new_values, reversed_new_config_lines, current)

      replace_matching_config_lines(
        remainder,
        new_values,
        new_config_lines,
        section,
        subsection,
        name
      )
    else
      replace_matching_config_lines(
        remainder,
        new_values,
        [current | reversed_new_config_lines],
        section,
        subsection,
        name
      )
    end
  end

  defp create_section_heaader(section, subsection),
    do: %ConfigLine{section: section, subsection: subsection}

  defp consume_next_matching_config_line(
         [next_match | remainder],
         reversed_new_config_lines,
         current
       ),
       do: {[%{current | value: next_match} | reversed_new_config_lines], remainder}

  defp consume_next_matching_config_line([], reversed_new_config_lines, _current),
    do: {reversed_new_config_lines, []}

  # private static List<ConfigLine> copy(final ConfigSnapshot src,
  # 		final List<String> values) {
  # 	// At worst we need to insert 1 line for each value, plus 1 line
  # 	// for a new section header. Assume that and allocate the space.
  # 	//
  # 	final int max = src.entryList.size() + values.size() + 1;
  # 	final ArrayList<ConfigLine> r = new ArrayList<>(max);
  # 	r.addAll(src.entryList);
  # 	return r;
  # }
  #
  # private static int findSectionEnd(final List<ConfigLine> entries,
  # 		final String section, final String subsection,
  # 		boolean skipIncludedLines) {
  # 	for (int i = 0; i < entries.size(); i++) {
  # 		ConfigLine e = entries.get(i);
  # 		if (e.includedFrom != null && skipIncludedLines) {
  # 			continue;
  # 		}
  #
  # 		if (e.match(section, subsection, null)) {
  # 			i++;
  # 			while (i < entries.size()) {
  # 				e = entries.get(i);
  # 				if (e.match(section, subsection, e.name))
  # 					i++;
  # 				else
  # 					break;
  # 			}
  # 			return i;
  # 		}
  # 	}
  # 	return -1;
  # }

  @doc ~S"""
  Get this configuration, formatted as a Git-style text file.
  """
  def to_text(c), do: GenServer.call(process_ref(c), :to_text)

  # IMPORTANT: to_text_impl/1 runs in GenServer process.
  # See handle_call/3 below.

  defp to_text_impl(config_lines) do
    config_lines
    |> Enum.map_join(&config_line_to_text/1)
    |> drop_leading_blank_line()
  end

  defp drop_leading_blank_line("\n" <> remainder), do: remainder
  defp drop_leading_blank_line(s), do: s

  defp config_line_to_text(%ConfigLine{included_from: included_from}) when included_from != nil,
    do: ""

  defp config_line_to_text(%ConfigLine{prefix: prefix, suffix: suffix} = cl),
    do:
      maybe_extra_line_prefix(cl) <>
        "#{config_line_maybe_str(prefix)}#{config_line_body_to_text(cl)}" <>
        "#{config_line_maybe_str(suffix)}\n"

  defp maybe_extra_line_prefix(%ConfigLine{section: section, name: nil}) when section != nil,
    do: "\n"

  defp maybe_extra_line_prefix(_), do: ""

  defp config_line_maybe_str(nil), do: ""
  defp config_line_maybe_str(s), do: s

  defp config_line_body_to_text(%ConfigLine{section: section, subsection: subsection, name: nil})
       when section != nil,
       do: "[#{section}#{subsection_to_text(subsection)}]"

  defp config_line_body_to_text(%ConfigLine{
         prefix: prefix,
         suffix: suffix,
         section: section,
         name: name,
         value: value
       })
       when section != nil do
    "#{prefix_str_for_body(prefix)}#{name}#{value_to_text(value)}#{suffix_str_for_body(suffix)}"
  end

  defp config_line_body_to_text(_), do: ""

  defp subsection_to_text(nil), do: ""

  defp subsection_to_text(subsection) do
    " \"#{subsection}\""

    # TODO: Escaping not handled yet.
    # 				out.append(' ');
    # 				String escaped = escapeValue(e.subsection);
    # 				// make sure to avoid double quotes here
    # 				boolean quoted = escaped.startsWith("\"") //$NON-NLS-1$
    # 						&& escaped.endsWith("\""); //$NON-NLS-1$
    # 				if (!quoted)
    # 					out.append('"');
    # 				out.append(escaped);
    # 				if (!quoted)
    # 					out.append('"');
  end

  defp prefix_str_for_body(nil), do: "\t"
  defp prefix_str_for_body(""), do: "\t"
  defp prefix_str_for_body(_), do: ""

  defp value_to_text(:empty), do: ""
  defp value_to_text(nil), do: " ="
  defp value_to_text(v), do: " = #{escape_value(v)}"

  defp escape_value(v), do: v
  # TODO: Needs a real implementation.

  defp suffix_str_for_body(nil), do: ""
  defp suffix_str_for_body(s), do: s

  @doc ~S"""
  Clear this configuration and reset to the contents of the parsed string.

  `text` should be a Git-style text file listing configuration properties

  Raises `ConfigInvalidError` if unable to parse string.
  """
  def from_text(c, text) when is_binary(text) do
    case GenServer.call(process_ref(c), {:from_text, text}) do
      {:error, e} -> raise(e)
      _ -> c
    end
  end

  # IMPORTANT: from_text_impl/3 runs in GenServer process.
  # See handle_call/3 below.

  defp from_text_impl(_text, 10, _included_from) do
    raise ConfigInvalidError, message: "Too many recursions; circular includes in config file(s)?"
  end

  defp from_text_impl(text, depth, included_from) when is_binary(text) and is_integer(depth) do
    text
    |> String.to_charlist()
    |> config_lines_from([], nil, nil, included_from, [])
  end

  defp config_lines_from(remainder, config_lines_acc, section, subsection, included_from, prefix)

  defp config_lines_from([], config_lines_acc, _section, _subsection, _included_from, _prefix),
    do: config_lines_acc

  defp config_lines_from(
         [?\n | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         _prefix
       ) do
    config_lines_from(remainder, config_lines_acc, section, subsection, included_from, [])
  end

  defp config_lines_from(
         [?\s | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       ) do
    config_lines_from(
      remainder,
      config_lines_acc,
      section,
      subsection,
      included_from,
      prefix ++ [?\s]
    )
  end

  defp config_lines_from(
         [?\t | remainder],
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       ) do
    config_lines_from(
      remainder,
      config_lines_acc,
      section,
      subsection,
      included_from,
      prefix ++ [?\t]
    )
  end

  defp config_lines_from(
         [?[ | remainder] = buffer,
         config_lines_acc,
         _section,
         _subsection,
         included_from,
         prefix
       ) do
    # This is a section header.
    {section, remainder} =
      remainder
      |> skip_whitespace()
      |> Enum.split_while(&section_name_char?/1)
      |> section_to_string(buffer)

    # TODO: Reread readSectionName closely.

    {subsection, remainder} =
      remainder
      |> skip_whitespace()
      |> maybe_read_subsection_name(buffer)

    subsection = maybe_string(subsection)

    remainder =
      remainder
      |> skip_whitespace()
      |> expect_close_brace(buffer)

    {suffix, remainder} = Enum.split_while(remainder, &(&1 != ?\n))

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        included_from: included_from,
        suffix: suffix
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_lines_from(
         [c | _] = remainder,
         config_lines_acc,
         section,
         subsection,
         included_from,
         prefix
       )
       when c == ?; or c == ?# do
    {comment, remainder} = Enum.split_while(remainder, &not_eol?/1)

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        included_from: included_from,
        suffix: comment
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_lines_from(_remainder, _config_lines_acc, nil, _subsection, _included_from, _prefix) do
    # Attempt to set a value before a section header.
    raise ConfigInvalidError, "Invalid line in config file"
  end

  defp config_lines_from(remainder, config_lines_acc, section, subsection, included_from, prefix) do
    {key, remainder} = read_key_name(remainder, [])
    {value, remainder} = maybe_read_value(remainder)
    {comment, remainder} = maybe_read_comment(remainder)

    new_config_line =
      config_line_with_strings(%{
        prefix: prefix,
        section: section,
        subsection: subsection,
        name: key,
        value: value,
        suffix: comment,
        included_from: included_from
      })

    config_lines_from(
      remainder,
      config_lines_acc ++ [new_config_line],
      section,
      subsection,
      included_from,
      prefix
    )
  end

  defp config_line_with_strings(params) do
    %ConfigLine{
      prefix: maybe_string(params, :prefix),
      section: params.section,
      subsection: params.subsection,
      name: maybe_string(params, :name),
      value: maybe_string(params, :value),
      suffix: maybe_string(params, :suffix),
      included_from: params.included_from
    }
  end

  defp maybe_string(nil), do: nil
  defp maybe_string(x) when is_atom(x), do: x
  defp maybe_string(x), do: to_string(x)
  defp maybe_string(map, key), do: map |> Map.get(key) |> maybe_string()

  defp expect_close_brace([?] | remainder], _buffer), do: remainder
  defp expect_close_brace(_, buffer), do: raise_bad_section_entry(buffer)

  defp section_to_string({[] = _section, _remainder}, buffer), do: raise_bad_section_entry(buffer)
  defp section_to_string({section, remainder}, _buffer), do: {to_string(section), remainder}

  defp maybe_read_subsection_name([?] | _] = remainder, _buffer), do: {nil, remainder}

  defp maybe_read_subsection_name([?" | remainder], buffer),
    do: read_subsection_name(remainder, [], buffer)

  defp maybe_read_subsection_name(_remainder, buffer), do: raise_bad_section_entry(buffer)

  defp read_subsection_name([], _name_acc, buffer), do: raise_bad_section_entry(buffer)
  defp read_subsection_name([?\n | _], _name_acc, buffer), do: raise_bad_section_entry(buffer)
  defp read_subsection_name([?" | remainder], name_acc, _buffer), do: {name_acc, remainder}

  defp read_subsection_name([?\\ | [c | remainder]], name_acc, buffer),
    do: read_subsection_name(remainder, name_acc ++ [c], buffer)

  defp read_subsection_name([c | remainder], name_acc, buffer),
    do: read_subsection_name(remainder, name_acc ++ [c], buffer)

  defp raise_bad_section_entry(buffer) do
    raise(
      ConfigInvalidError,
      "Bad section entry: #{buffer |> first_line_from() |> to_string()}"
    )
  end

  defp read_key_name([], name_acc), do: {name_acc, []}
  defp read_key_name([?\n | _] = remainder, name_acc), do: {name_acc, remainder}
  defp read_key_name([?= | _] = remainder, name_acc), do: {name_acc, remainder}
  defp read_key_name([?\s | remainder], name_acc), do: {name_acc, skip_whitespace(remainder)}
  defp read_key_name([?\t | remainder], name_acc), do: {name_acc, skip_whitespace(remainder)}

  defp read_key_name([c | remainder], name_acc) do
    if letter_or_digit?(c) || c == ?-,
      do: read_key_name(remainder, name_acc ++ [c]),
      else: raise(ConfigInvalidError, message: "Bad entry name: #{to_string(name_acc ++ [c])}")
  end

  defp maybe_read_value([?\n | _] = remainder), do: {:empty, remainder}
  defp maybe_read_value([?= | remainder]), do: read_value(skip_whitespace(remainder), [], [])
  defp maybe_read_value([?; | remainder]), do: {nil, remainder}
  defp maybe_read_value([?# | remainder]), do: {nil, remainder}
  defp maybe_read_value([]), do: {nil, []}
  defp maybe_read_value(_), do: raise(ConfigInvalidError, message: "Bad entry delimiter.")

  defp read_value([], value_acc, _trailing_ws_acc), do: {value_acc, []}
  defp read_value([?\n | _] = remainder, value_acc, _trailing_ws_acc), do: {value_acc, remainder}

  defp read_value([c | _] = remainder, value_acc, _trailing_ws_acc)
       when c == ?# or c == ?;,
       do: {value_acc, remainder}

  defp read_value([?\\], _name_acc, _trailing_ws_acc),
    do: raise(ConfigInvalidError, message: "End of file in escape")

  defp read_value([?\\ | [?\n | remainder]], value_acc, trailing_ws_acc),
    do: read_value(remainder, value_acc ++ trailing_ws_acc, [])

  defp read_value([?\\ | [c | remainder]], value_acc, trailing_ws_acc),
    do: read_value(remainder, value_acc ++ trailing_ws_acc ++ [translate_escape(c)], [])

  defp read_value([?" | _remainder], _value_acc, _trailing_ws_acc) do
    raise "quoted values not yet implemented"
  end

  defp read_value([c | remainder], value_acc, trailing_ws_acc) when c == ?\s or c == ?\t,
    do: read_value(remainder, value_acc, trailing_ws_acc ++ [c])

  defp read_value([c | remainder], value_acc, trailing_ws_acc),
    do: read_value(remainder, value_acc ++ trailing_ws_acc ++ [c], [])

  defp translate_escape(?t), do: ?\t
  defp translate_escape(?b), do: ?\b
  defp translate_escape(?n), do: ?\n
  defp translate_escape(?\\), do: ?\\
  defp translate_escape(?"), do: ?\"
  defp translate_escape(c), do: raise(ConfigInvalidError, message: "Bad escape: #{c}")

  defp maybe_read_comment(remainder) do
    {whitespace, remainder} = Enum.split_while(remainder, &whitespace?/1)
    {comment, remainder} = read_comment(remainder)
    {whitespace ++ comment, remainder}
  end

  defp read_comment([c | _] = remainder) when c == ?; or c == ?#,
    do: Enum.split_while(remainder, &not_eol?/1)

  defp read_comment([?\n | remainder]), do: {[], remainder}
  defp read_comment([]), do: {[], []}
  defp read_comment(_), do: raise(ConfigInvalidError, message: "Bad entry delimiter.")

  defp skip_whitespace(s), do: Enum.drop_while(s, &whitespace?/1)

  defp whitespace?(?\s), do: true
  defp whitespace?(?\t), do: true
  defp whitespace?(_), do: false

  defp first_line_from(buffer), do: Enum.take_while(buffer, &not_eol?/1)

  defp not_eol?(?\n), do: true
  defp not_eol?(_), do: false

  defp section_name_char?(c) when c >= ?0 and c <= ?9, do: true
  defp section_name_char?(c) when c >= ?A and c <= ?Z, do: true
  defp section_name_char?(c) when c >= ?a and c <= ?z, do: true
  defp section_name_char?(?.), do: true
  defp section_name_char?(?-), do: true
  defp section_name_char?(_), do: false

  # HELP: This is not Unicode-savvy. Is there such a thing?
  defp letter_or_digit?(c) when c >= ?0 and c <= ?9, do: true
  defp letter_or_digit?(c) when c >= ?A and c <= ?Z, do: true
  defp letter_or_digit?(c) when c >= ?a and c <= ?z, do: true
  defp letter_or_digit?(_), do: false

  # /**
  #  * Read the included config from the specified (possibly) relative path
  #  *
  #  * @param relPath
  #  *            possibly relative path to the included config, as specified in
  #  *            this config
  #  * @return the read bytes, or null if the included config should be ignored
  #  * @throws org.eclipse.jgit.errors.ConfigInvalidException
  #  *             if something went wrong while reading the config
  #  * @since 4.10
  #  */
  # protected byte[] readIncludedConfig(String relPath)
  # 		throws ConfigInvalidException {
  # 	return null;
  # }
  #
  # private void addIncludedConfig(final List<ConfigLine> newEntries,
  # 		ConfigLine line, int depth) throws ConfigInvalidException {
  # 	if (!line.name.equalsIgnoreCase("path") || //$NON-NLS-1$
  # 			line.value == null || line.value.equals(MAGIC_EMPTY_VALUE)) {
  # 		throw new ConfigInvalidException(MessageFormat.format(
  # 				JGitText.get().invalidLineInConfigFileWithParam, line));
  # 	}
  # 	byte[] bytes = readIncludedConfig(line.value);
  # 	if (bytes == null) {
  # 		return;
  # 	}
  #
  # 	String decoded;
  # 	if (isUtf8(bytes)) {
  # 		decoded = RawParseUtils.decode(UTF_8, bytes, 3, bytes.length);
  # 	} else {
  # 		decoded = RawParseUtils.decode(bytes);
  # 	}
  # 	try {
  # 		newEntries.addAll(fromTextRecurse(decoded, depth + 1, line.value));
  # 	} catch (ConfigInvalidException e) {
  # 		throw new ConfigInvalidException(MessageFormat
  # 				.format(JGitText.get().cannotReadFile, line.value), e);
  # 	}
  # }
  #
  # private ConfigSnapshot newState() {
  # 	return new ConfigSnapshot(Collections.<ConfigLine> emptyList(),
  # 			getBaseState());
  # }
  #
  # private ConfigSnapshot newState(List<ConfigLine> entries) {
  # 	return new ConfigSnapshot(Collections.unmodifiableList(entries),
  # 			getBaseState());
  # }
  #
  # /**
  #  * Clear the configuration file
  #  */
  # protected void clear() {
  # 	state.set(newState());
  # }
  #
  # /**
  #  * Check if bytes should be treated as UTF-8 or not.
  #  *
  #  * @param bytes
  #  *            the bytes to check encoding for.
  #  * @return true if bytes should be treated as UTF-8, false otherwise.
  #  * @since 4.4
  #  */
  # protected boolean isUtf8(final byte[] bytes) {
  # 	return bytes.length >= 3 && bytes[0] == (byte) 0xEF
  # 			&& bytes[1] == (byte) 0xBB && bytes[2] == (byte) 0xBF;
  # }
  #
  # private static String readSectionName(StringReader in)
  # 		throws ConfigInvalidException {
  # 	final StringBuilder name = new StringBuilder();
  # 	for (;;) {
  # 		int c = in.read();
  # 		if (c < 0)
  # 			throw new ConfigInvalidException(JGitText.get().unexpectedEndOfConfigFile);
  #
  # 		if (']' == c) {
  # 			in.reset();
  # 			break;
  # 		}
  #
  # 		if (' ' == c || '\t' == c) {
  # 			for (;;) {
  # 				c = in.read();
  # 				if (c < 0)
  # 					throw new ConfigInvalidException(JGitText.get().unexpectedEndOfConfigFile);
  #
  # 				if ('"' == c) {
  # 					in.reset();
  # 					break;
  # 				}
  #
  # 				if (' ' == c || '\t' == c)
  # 					continue; // Skipped...
  # 				throw new ConfigInvalidException(MessageFormat.format(JGitText.get().badSectionEntry, name));
  # 			}
  # 			break;
  # 		}
  #
  # 		if (Character.isLetterOrDigit((char) c) || '.' == c || '-' == c)
  # 			name.append((char) c);
  # 		else
  # 			throw new ConfigInvalidException(MessageFormat.format(JGitText.get().badSectionEntry, name));
  # 	}
  # 	return name.toString();
  # }
  #
  # private static String readSubsectionName(StringReader in)
  # 		throws ConfigInvalidException {
  # 	StringBuilder r = new StringBuilder();
  # 	for (;;) {
  # 		int c = in.read();
  # 		if (c < 0) {
  # 			break;
  # 		}
  #
  # 		if ('\n' == c) {
  # 			throw new ConfigInvalidException(
  # 					JGitText.get().newlineInQuotesNotAllowed);
  # 		}
  # 		if ('\\' == c) {
  # 			c = in.read();
  # 			switch (c) {
  # 			case -1:
  # 				throw new ConfigInvalidException(JGitText.get().endOfFileInEscape);
  #
  # 			case '\\':
  # 			case '"':
  # 				r.append((char) c);
  # 				continue;
  #
  # 			default:
  # 				// C git simply drops backslashes if the escape sequence is not
  # 				// recognized.
  # 				r.append((char) c);
  # 				continue;
  # 			}
  # 		}
  # 		if ('"' == c) {
  # 			break;
  # 		}
  #
  # 		r.append((char) c);
  # 	}
  # 	return r.toString();
  # }
  #
  # private static String readValue(StringReader in)
  # 		throws ConfigInvalidException {
  # 	StringBuilder value = new StringBuilder();
  # 	StringBuilder trailingSpaces = null;
  # 	boolean quote = false;
  # 	boolean inLeadingSpace = true;
  #
  # 	for (;;) {
  # 		int c = in.read();
  # 		if (c < 0) {
  # 			break;
  # 		}
  # 		if ('\n' == c) {
  # 			if (quote) {
  # 				throw new ConfigInvalidException(
  # 						JGitText.get().newlineInQuotesNotAllowed);
  # 			}
  # 			in.reset();
  # 			break;
  # 		}
  #
  # 		if (!quote && (';' == c || '#' == c)) {
  # 			if (trailingSpaces != null) {
  # 				trailingSpaces.setLength(0);
  # 			}
  # 			in.reset();
  # 			break;
  # 		}
  #
  # 		char cc = (char) c;
  # 		if (Character.isWhitespace(cc)) {
  # 			if (inLeadingSpace) {
  # 				continue;
  # 			}
  # 			if (trailingSpaces == null) {
  # 				trailingSpaces = new StringBuilder();
  # 			}
  # 			trailingSpaces.append(cc);
  # 			continue;
  # 		} else {
  # 			inLeadingSpace = false;
  # 			if (trailingSpaces != null) {
  # 				value.append(trailingSpaces);
  # 				trailingSpaces.setLength(0);
  # 			}
  # 		}
  #
  # 		if ('\\' == c) {
  # 			c = in.read();
  # 			switch (c) {
  # 			case -1:
  # 				throw new ConfigInvalidException(JGitText.get().endOfFileInEscape);
  # 			case '\n':
  # 				continue;
  # 			case 't':
  # 				value.append('\t');
  # 				continue;
  # 			case 'b':
  # 				value.append('\b');
  # 				continue;
  # 			case 'n':
  # 				value.append('\n');
  # 				continue;
  # 			case '\\':
  # 				value.append('\\');
  # 				continue;
  # 			case '"':
  # 				value.append('"');
  # 				continue;
  # 			default:
  # 				throw new ConfigInvalidException(MessageFormat.format(
  # 						JGitText.get().badEscape,
  # 						Character.valueOf(((char) c))));
  # 			}
  # 		}
  #
  # 		if ('"' == c) {
  # 			quote = !quote;
  # 			continue;
  # 		}
  #
  # 		value.append(cc);
  # 	}
  # 	return value.length() > 0 ? value.toString() : null;
  # }
  #
  # /**
  #  * Parses a section of the configuration into an application model object.
  #  * <p>
  #  * Instances must implement hashCode and equals such that model objects can
  #  * be cached by using the {@code SectionParser} as a key of a HashMap.
  #  * <p>
  #  * As the {@code SectionParser} itself is used as the key of the internal
  #  * HashMap applications should be careful to ensure the SectionParser key
  #  * does not retain unnecessary application state which may cause memory to
  #  * be held longer than expected.
  #  *
  #  * @param <T>
  #  *            type of the application model created by the parser.
  #  */
  # public static interface SectionParser<T> {
  # 	/**
  # 	 * Create a model object from a configuration.
  # 	 *
  # 	 * @param cfg
  # 	 *            the configuration to read values from.
  # 	 * @return the application model instance.
  # 	 */
  # 	T parse(Config cfg);
  # }
  #
  # private static class StringReader {
  # 	private final char[] buf;
  #
  # 	private int pos;
  #
  # 	StringReader(String in) {
  # 		buf = in.toCharArray();
  # 	}
  #
  # 	int read() {
  # 		try {
  # 			return buf[pos++];
  # 		} catch (ArrayIndexOutOfBoundsException e) {
  # 			pos = buf.length;
  # 			return -1;
  # 		}
  # 	}
  #
  # 	void reset() {
  # 		pos--;
  # 	}
  # }
  #
  # /**
  #  * Converts enumeration values into configuration options and vice-versa,
  #  * allowing to match a config option with an enum value.
  #  *
  #  */
  # public static interface ConfigEnum {
  # 	/**
  # 	 * Converts enumeration value into a string to be save in config.
  # 	 *
  # 	 * @return the enum value as config string
  # 	 */
  # 	String toConfigValue();
  #
  # 	/**
  # 	 * Checks if the given string matches with enum value.
  # 	 *
  # 	 * @param in
  # 	 *            the string to match
  # 	 * @return true if the given string matches enum value, false otherwise
  # 	 */
  # 	boolean matchConfigValue(String in);
  # }

  @impl true
  def handle_call(:to_text, _from, %__MODULE__.State{config_lines: config_lines} = s),
    do: {:reply, to_text_impl(config_lines), s}

  @impl true
  def handle_call({:from_text, text}, _from, %__MODULE__.State{} = s) when is_binary(text) do
    try do
      new_config_lines = from_text_impl(text, 1, nil)
      {:reply, :ok, %{s | config_lines: new_config_lines}}
    rescue
      e in ConfigInvalidError -> {:reply, {:error, e}, s}
    end
  end

  @impl true
  def handle_call({:get_raw_strings, section, subsection, name}, _from, %__MODULE__.State{} = s)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) do
    {:reply, raw_string_list(s, section, subsection, name), s}
  end

  @impl true
  def handle_call(:sections, _from, %__MODULE__.State{config_lines: config_lines} = s),
    do: {:reply, sections_impl(config_lines), s}

  @impl true
  def handle_call(
        {:names_in_section, section},
        _from,
        %__MODULE__.State{config_lines: config_lines} = s
      )
      when is_binary(section) do
    {:reply, names_in_section_impl(config_lines, section), s}
  end

  @impl true
  def handle_call(
        {:names_in_subsection, section, subsection},
        _from,
        %__MODULE__.State{config_lines: config_lines} = s
      )
      when is_binary(section) do
    {:reply, names_in_subsection_impl(config_lines, section, subsection), s}
  end

  @impl true
  def handle_call({:unset_section, section, subsection}, _from, %__MODULE__.State{} = s)
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) do
    new_config_lines = unset_section_impl(s, section, subsection)
    {:reply, :ok, %{s | config_lines: new_config_lines}}
  end

  @impl true
  def handle_call(
        {:set_string_list, section, subsection, name, values},
        _from,
        %__MODULE__.State{} = s
      )
      when is_binary(section) and (is_binary(subsection) or is_nil(subsection)) and
             is_binary(name) and is_list(values) do
    new_config_lines = set_string_list_impl(s, section, subsection, name, values)
    {:reply, :ok, %{s | config_lines: new_config_lines}}
  end

  defp process_ref(%__MODULE__{ref: ref}) when is_reference(ref),
    do: {:global, {:xgit_config, ref}}
end
