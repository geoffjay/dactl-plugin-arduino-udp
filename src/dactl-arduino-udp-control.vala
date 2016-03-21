[GtkTemplate (ui = "/org/coanda/dactl/plugins/arduino-udp/arduino-udp-control.ui")]
public class Dactl.ArduinoUDP.Control : Dactl.SimpleWidget, Dactl.PluginControl, Dactl.CldAdapter {

    /* XML/XSD variables are useless for now */
    private string _xml = """
        <ui:object id=\"arduino-udp-ctl0\" type=\"arduino-udp-plugin\">
          <ui:property name="ref" device="arduino-udp">/ser0</ui:property>
        </ui:object>
    """;

    private string _xsd = """
        <xs:element name="object">
          <xs:attribute name="id" type="xs:string" use="required"/>
          <xs:attribute name="type" type="xs:string" use="required"/>
          <xs:attribute name="parent" type="xs:string" use="required"/>
        </xs:element>
    """;

    [GtkChild]
    private Gtk.Label lbl_arduino_udp;

    public string port_arduino_udp_ref { get; set; }

    private weak Cld.SerialPort _port_arduino_udp;

    public Cld.SerialPort port_arduino_udp {
        get { return _port_arduino_udp; }
        set {
            if ((value as Cld.Object).uri == port_arduino_udp_ref) {
                _port_arduino_udp = value;
                port_arduino_udp_isset = true;
            }
        }
    }

    private bool port_arduino_udp_isset = false;

    /**
     * {@inheritDoc}
     */
    protected override string xml {
        get { return _xml; }
    }

    /**
     * {@inheritDoc}
     */
    protected override string xsd {
        get { return _xsd; }
    }

    public virtual string parent_ref { get; set; }

    /**
     * {@inheritDoc}
     */
    protected bool satisfied { get; set; default = false; }

    construct {
        id = "arduino-udp-ctl0";
    }

    public Control.from_xml_node (Xml.Node *node) {
        build_from_xml_node (node);

        /* Request the CLD data */
        request_data.begin ();
    }

    /**
     * {@inheritDoc}
     */
    public override void build_from_xml_node (Xml.Node *node) {
        id = node->get_prop ("id");
        parent_ref = node->get_prop ("parent");
        message ("Building `%s' with parent `%s'", id, parent_ref);

        for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
            if (iter->name == "property") {
                switch (iter->get_prop ("name")) {
                    case "ref":
                        var device = iter->get_prop ("device");
                        if (device == "arduino-udp")
                            port_arduino_udp_ref = iter->get_content ();

                        break;
                    default:
                        break;
                }

                message (" > Adding %s to %s", iter->get_content (), id);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void offer_cld_object (Cld.Object object) {
        if (object.uri == port_arduino_udp_ref) {
            port_arduino_udp = object as Cld.SerialPort;
            port_arduino_udp.new_data.connect (arduino_udp_new_data_cb);
        }

        if (port_arduino_udp_isset)
            satisfied = true;
    }

    /**
     * {@inheritDoc}
     */
    protected async void request_data () {
        while (!satisfied) {
            if (!port_arduino_udp_isset)
                request_object (port_arduino_udp_ref);

            // Try again in a second
            yield nap (1000);
        }
    }

    /**
     * {@inheritDoc}
     *
     * FIXME: currently has no configurable property nodes or attributes
     */
    protected override void update_node () {
        /*
         *for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
         *    if (iter->name == "property") {
         *        switch (iter->get_prop ("name")) {
         *            case "---":
         *                iter->set_content (---);
         *                break;
         *            default:
         *                break;
         *        }
         *    }
         *}
         */
    }

    private void arduino_udp_new_data_cb (Cld.SerialPort port, uchar[] data, int size) {
        string received = "";

        for (var i = 0; i < size; i++) {
            unichar c = "%c".printf (data[i]).get_char ();
            string s = "%c".printf (data[i]);
            received += "%s".printf (s);
        }

        //stdout.printf ("Recv %d chars: %s\n", size, received);
    }
}
