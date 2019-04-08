defprotocol Xgit.Util.SystemReader do
  @moduledoc ~S"""
  Behaviour to read values from the system.

  When writing unit tests, implementing this protocol with a custom module
  will allow the test code to simululate specific system variable values or
  other aspects of the user's global configuration.
  """
  @fallback_to_any true

  alias Xgit.Lib.Config

  @doc ~S"""
  Gets the hostname of the local host. If no hostname can be found, the
  hostname is set to the default value `"localhost"`.
  """
  @spec hostname(reader :: term) :: String.t()
  def hostname(reader \\ nil)

  @doc ~S"""
  Get value of the named system (environment) variable.
  """
  @spec get_env(reader :: term, variable :: String.t()) :: String.t()
  def get_env(reader \\ nil, variable)

  @doc ~S"""
  Open the git configuration found in the user home.
  """
  @spec user_config(reader :: term, parent_config :: Config.t()) :: Config.t()
  def user_config(reader \\ nil, parent_config \\ nil)

  @doc ~S"""
  Open the git configuration found in the system-wide "etc" directory.

  May return `nil` if no such configuration is present.
  """
  @spec system_config(reader :: term, parent_config :: Config.t()) :: Config.t() | nil
  def system_config(reader \\ nil, parent_config \\ nil)

  @doc ~S"""
  Get the current system time in milliseconds.
  """
  @spec current_time(reader :: term) :: number
  def current_time(reader \\ nil)

  @doc ~S"""
  Get clock instance preferred by this system.

  The return value should be a struct that implements `MonotonicClock`.
  """
  @spec clock(reader :: term) :: term
  def clock(reader \\ nil)

  @doc ~S"""
  Get the local time zone at a specific system-provided time.

  Time zone is expressed as a number of minutes +/- GMT offset.

  PORTING NOTE: Elixir does not have the depth of time-zone knowledge that is
  available in Java. For now, the abstraction is present, but the default
  system reader will always return 0 (GMT).
  """
  @spec timezone_at_time(reader :: term, time :: integer) :: integer
  def timezone_at_time(reader \\ nil, time)

  @doc ~S"""
  Get system time zone, possibly mocked for testing.

  Time zone is expressed as a number of minutes +/- GMT offset.

  PORTING NOTE: Elixir does not have the depth of time-zone knowledge that is
  available in Java. For now, the abstraction is present, but the default
  system reader will always return 0 (GMT).
  """
  @spec timezone(reader :: term) :: integer
  def timezone(reader \\ nil)

  # /**
  #  * Get the locale to use
  #  *
  #  * @return the locale to use
  #  * @since 1.2
  #  */
  # public Locale getLocale() {
  # 	return Locale.getDefault();
  # }

  # /**
  #  * Returns a simple date format instance as specified by the given pattern.
  #  *
  #  * @param pattern
  #  *            the pattern as defined in
  #  *            {@link java.text.SimpleDateFormat#SimpleDateFormat(String)}
  #  * @return the simple date format
  #  * @since 2.0
  #  */
  # public SimpleDateFormat getSimpleDateFormat(String pattern) {
  # 	return new SimpleDateFormat(pattern);
  # }

  # /**
  #  * Returns a simple date format instance as specified by the given pattern.
  #  *
  #  * @param pattern
  #  *            the pattern as defined in
  #  *            {@link java.text.SimpleDateFormat#SimpleDateFormat(String)}
  #  * @param locale
  #  *            locale to be used for the {@code SimpleDateFormat}
  #  * @return the simple date format
  #  * @since 3.2
  #  */
  # public SimpleDateFormat getSimpleDateFormat(String pattern, Locale locale) {
  # 	return new SimpleDateFormat(pattern, locale);
  # }

  # /**
  #  * Returns a date/time format instance for the given styles.
  #  *
  #  * @param dateStyle
  #  *            the date style as specified in
  #  *            {@link java.text.DateFormat#getDateTimeInstance(int, int)}
  #  * @param timeStyle
  #  *            the time style as specified in
  #  *            {@link java.text.DateFormat#getDateTimeInstance(int, int)}
  #  * @return the date format
  #  * @since 2.0
  #  */
  # public DateFormat getDateTimeInstance(int dateStyle, int timeStyle) {
  # 	return DateFormat.getDateTimeInstance(dateStyle, timeStyle);
  # }

  # /**
  #  * Whether we are running on Windows.
  #  *
  #  * @return true if we are running on Windows.
  #  */
  # public boolean isWindows() {
  # 	if (isWindows == null) {
  # 		String osDotName = getOsName();
  # 		isWindows = Boolean.valueOf(osDotName.startsWith("Windows")); //$NON-NLS-1$
  # 	}
  # 	return isWindows.booleanValue();
  # }

  # /**
  #  * Whether we are running on Mac OS X
  #  *
  #  * @return true if we are running on Mac OS X
  #  */
  # public boolean isMacOS() {
  # 	if (isMacOS == null) {
  # 		String osDotName = getOsName();
  # 		isMacOS = Boolean.valueOf(
  # 				"Mac OS X".equals(osDotName) || "Darwin".equals(osDotName)); //$NON-NLS-1$ //$NON-NLS-2$
  # 	}
  # 	return isMacOS.booleanValue();
  # }

  # /**
  #  * Check tree path entry for validity.
  #  * <p>
  #  * Scans a multi-directory path string such as {@code "src/main.c"}.
  #  *
  #  * @param path path string to scan.
  #  * @throws org.eclipse.jgit.errors.CorruptObjectException path is invalid.
  #  * @since 3.6
  #  */
  # public void checkPath(String path) throws CorruptObjectException {
  # 	platformChecker.checkPath(path);
  # }
end

defimpl Xgit.Util.SystemReader, for: Any do
  alias Xgit.Lib.Config
  alias Xgit.Storage.File.FileBasedConfig
  alias Xgit.Util.Time.MonotonicSystemClock

  def hostname(_) do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  def get_env(_, variable), do: System.get_env(variable)

  def user_config(_, nil) do
    System.user_home!()
    |> Path.join(".gitconfig")
    |> FileBasedConfig.config_for_path()
  end

  def user_config(_, base_config) do
    System.user_home!()
    |> Path.join(".gitconfig")
    |> FileBasedConfig.config_for_path(base_config: base_config)
  end

  def system_config(_, nil), do: Config.new()
  # PORTING NOTE: For now, we're going to ignore the system configuration file.
  # Likely use cases for xgit (as a server product) suggest system git configuration
  # should be ignored in favor of explicit configuration. A PR is welcome if this
  # decision doesn't make sense.

  def current_time(_), do: System.os_time(:millisecond)

  def clock(_), do: %MonotonicSystemClock{}

  def timezone_at_time(_, _time), do: 0
  def timezone(_), do: 0
  # PORTING NOTE: Elixir does not have the depth of time-zone knowledge that is
  # available in Java. For now, the abstraction is present, but the default
  # system reader will always return 0 (GMT).
end
