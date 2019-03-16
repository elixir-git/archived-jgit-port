defprotocol Xgit.Util.SystemReader do
  @moduledoc ~S"""
  Behaviour to read values from the system.

  When writing unit tests, implementing this protocol with a custom module
  will allow the test code to simululate specific system variable values or
  other aspects of the user's global configuration.
  """
  @fallback_to_any true

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

  # /**
  #  * Open the git configuration found in the user home
  #  *
  #  * @param parent
  #  *            a config with values not found directly in the returned config
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  * @return the git configuration found in the user home
  #  */
  # public abstract FileBasedConfig openUserConfig(Config parent, FS fs);

  # /**
  #  * Open the gitconfig configuration found in the system-wide "etc" directory
  #  *
  #  * @param parent
  #  *            a config with values not found directly in the returned
  #  *            config. Null is a reasonable value here.
  #  * @param fs
  #  *            the file system abstraction which will be necessary to perform
  #  *            certain file system operations.
  #  * @return the gitconfig configuration found in the system-wide "etc"
  #  *         directory
  #  */
  # public abstract FileBasedConfig openSystemConfig(Config parent, FS fs);

  @doc ~S"""
  Get the current system time in milliseconds.
  """
  @spec current_time(reader :: term) :: number
  def current_time(reader \\ nil)

  # /**
  #  * Get clock instance preferred by this system.
  #  *
  #  * @return clock instance preferred by this system.
  #  * @since 4.6
  #  */
  # public MonotonicClock getClock() {
  # 	return new MonotonicSystemClock();
  # }

  # /**
  #  * Get the local time zone
  #  *
  #  * @param when
  #  *            a system timestamp
  #  * @return the local time zone
  #  */
  # public abstract int getTimezone(long when);

  # /**
  #  * Get system time zone, possibly mocked for testing
  #  *
  #  * @return system time zone, possibly mocked for testing
  #  * @since 1.2
  #  */
  # public TimeZone getTimeZone() {
  # 	return TimeZone.getDefault();
  # }

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
  def hostname(_) do
    {:ok, hostname} = :inet.gethostname()
    to_string(hostname)
  end

  def get_env(_, variable), do: System.get_env(variable)
  def current_time(_), do: System.os_time(:millisecond)
end
