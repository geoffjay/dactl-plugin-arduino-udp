/**
 * Holds constants defined by the build system.
 */

[CCode (cheader_filename = "config.h")]
public class Dactl.ArduinoUDP.Config {

    /* Package information */

    [CCode (cname = "PACKAGE_NAME")]
    public static const string PACKAGE_NAME;

    [CCode (cname = "PACKAGE_STRING")]
    public static const string PACKAGE_STRING;

    [CCode (cname = "PACKAGE_VERSION")]
    public static const string PACKAGE_VERSION;

    /* Gettext package */

    [CCode (cname = "GETTEXT_PACKAGE")]
    public static const string GETTEXT_PACKAGE;

    [CCode (cname = "LOCALEDIR")]
    public static const string LOCALEDIR;

    /* Configured paths - these variables are not present in config.h, they are
     * passed to underlying C code as cmd line macros. */

    [CCode (cname = "DATADIR")]
    public static const string DATADIR;

    [CCode (cname = "SYS_CONFIG_DIR")]
    public static const string SYS_CONFIG_DIR;

    [CCode (cname = "PLUGIN_DIR")]
    public static const string PLUGIN_DIR;

    [CCode (cname = "LIBDIR")]
    public static const string LIBDIR;
}
