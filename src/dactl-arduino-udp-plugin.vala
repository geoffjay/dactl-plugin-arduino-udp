public void module_init (Dactl.PluginLoader loader) {
    try {
        // Instantiate the plugin object
        var plugin = new Dactl.ArduinoUDP.Plugin ();
        plugin.active = true;

        loader.add_plugin (plugin);
    } catch (Error error) {
        warning ("Failed to load %s: %s",
                 Dactl.ArduinoUDP.Plugin.NAME,
                 error.message);
    }
}

public class Dactl.ArduinoUDP.Plugin : Dactl.Plugin {

    public const string NAME = "arduino-udp";

    private bool _has_factory = true;
    public override bool has_factory { get { return _has_factory; } }

    /**
     * Instantiate the plugin.
     */
    public Plugin () {
        // Call the base constructor,
        base (NAME, null, null, Dactl.PluginCapabilities.CLD_OBJECT);
        factory = new Dactl.ArduinoUDP.Factory ();
    }
}
