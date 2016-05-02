[GtkTemplate (ui = "/org/coanda/dactl/plugins/arduino-udp/arduino-udp-control.ui")]
public class Dactl.ArduinoUDP.Control : Dactl.SimpleWidget, Dactl.PluginControl, Dactl.CldAdapter {

    /* XML/XSD variables are useless for now */
    private string _xml = """
        <ui:object id=\"arduino-udp-ctl0\" type=\"arduino-udp-plugin\">
          <ui:property name="port">3000</ui:property>
          <ui:property name="ref">/udp00</ui:property>
          <ui:property name="ref">/udp01</ui:property>
          <ui:property name="ref">/udp02</ui:property>
          <ui:property name="ref">/udp03</ui:property>
        </ui:object>
    """;

    private string _xsd = """
        <xs:element name="ui:object">
          <xs:attribute name="id" type="xs:string" use="required"/>
          <xs:attribute name="type" type="xs:string" use="required"/>
          <xs:attribute name="parent" type="xs:string" use="required"/>
          <xs:sequence>
            <xs:element name="ui:property">
              <xs:attribute name="name"/>
            </xs:element>
          </xs:sequence>
        </xs:element>
    """;

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

    private int port = 3000;

    private bool enabled = true;

    private Gee.List<string> references = new Gee.LinkedList<string> ();

    private Gee.Map<string, Cld.AIChannel> channels = new Gee.HashMap<string, Cld.AIChannel> ();

    construct {
        id = "arduino-udp-ctl0";
    }

    public Control.from_xml_node (Xml.Node *node) {
        build_from_xml_node (node);

        /* Request the CLD data */
        request_data.begin ();

        if (enabled) {
            listen_udp.begin ((obj, res) => {
                try {
                    listen_udp.end (res);
                } catch (ThreadError e) {
                    error (e.message);
                }
            });
        }

        if (!visible)
            this.hide ();
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
                    case "port":
                        port = int.parse (iter->get_content ());
                        break;
                    case "enabled":
                        enabled = bool.parse (iter->get_content ());
                        break;
                    case "ref":
                        references.add (iter->get_content ());
                        break;
                    default:
                        break;
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void offer_cld_object (Cld.Object object) {
        if (references.contains (object.uri)) {
            message ("Adding `%s' to `%s'", object.uri, id);
            channels.set (object.id, object as Cld.AIChannel);
        }

        if (references.size == channels.size)
            satisfied = true;
    }

    /**
     * {@inheritDoc}
     */
    protected async void request_data () {
        while (!satisfied) {
            foreach (var reference in references) {
                request_object (reference);
            }

            // Try again in a second
            yield nap (1000);
        }
    }

    protected async void listen_udp () throws ThreadError {
        SourceFunc callback = listen_udp.callback;

        ThreadFunc<void*> run = () => {
            try {
                message ("Connecting UDP socket of `%s' to port %d", id, port);
                var socket = new Socket (SocketFamily.IPV4,
                                         SocketType.DATAGRAM,
                                         SocketProtocol.UDP);
                var addr = new InetAddress.from_bytes ({0, 0, 0, 0}, SocketFamily.IPV4);
                var sa = new InetSocketAddress (addr, (uint16) port);
                socket.bind (sa, true);

                var source = socket.create_source (IOCondition.IN);
                source.set_callback ((s, cond) => {
                    try {
                        uint8 buffer[4096];
                        size_t read = s.receive (buffer);
                        buffer[read] = 0;                   // null terminate
                        string recv = (string) buffer;
                        recv = recv.strip ();

                        int msg_start = recv.index_of ("{");
                        int msg_end = recv.index_of ("}");

                        string[] tokens = (recv.slice (msg_start+1, msg_end)).split (",", channels.size);
                        for (int i = 0; i < tokens.length; i++) {
                            int from = references.@get (i).last_index_of ("/") + 1;
                            int to = references.@get (i).length;
                            var channel = channels.@get (references.@get (i).slice (from, to));
                            channel.add_raw_value (double.parse (tokens[i]));
                        }
                    } catch (Error e) {
                        error (e.message);
                    }
                    return true;
                });
                source.attach (MainContext.get_thread_default ());
            } catch (Error e) {
                error (e.message);
            }

            Idle.add ((owned) callback);
            return null;
        };

        Thread.create<void*> (run, false);
        yield;
    }

    /**
     * {@inheritDoc}
     *
     * FIXME: currently has no configurable property nodes or attributes
     */
    protected override void update_node () { /* do nothing */ }

    [GtkCallback]
    private void btn_settings_clicked_cb () {
        message ("`%s' - woot!", id);

        foreach (var channel in channels.values) {
            message ("%s", channel.id);
        }
    }
}
