## ArduinoUDP

This plugin is a UDP interface interface between Dactl and multiple Arduinos
all with an Ethernet shield attached. The port given in the configuration is
common for all connections and has been used to program the firmware of all
microcontrollers. The server in the plugin will be responsible for parsing
the input and the clients on each microcontroller will be responsible for
providing a unique identifier, a two character numeric, in the packet sent.

### Plugin XML Configuration

```xml
<plugins>
  <plugin id="arduino-udp0" type="ArduinoUDP">
    <ui:object id="arduino-udp-ctl0" type="plugin-control" parent="box0-0">
      <ui:property name="port" device="arduino_udp">3000</ui:property>
    </ui:object>
  </plugin>
</plugins>
```

### Plugin CLD XML Configuration

```xml
<cld:objects>
  <cld:object id="udp00" type="channel" ref="daqctl0/devnull" ptype="analog" direction="input">
    <cld:property name="tag"></cld:property>
    <cld:property name="desc"></cld:property>
    <cld:property name="num"></cld:property>
    <cld:property name="subdevnum"></cld:property>
    <cld:property name="calref">udp_cal00</cld:property>
    <cld:property name="range"></cld:property>
    <cld:property name="naverage"></cld:property>
    <cld:property name="alias"></cld:property>
  </cld:object>
  <!-- ... x9 -->

  <cld:object id="udp_cal00" type="calibration">
    <cld:property name="units">Volts</cld:property>
    <cld:object id="cft0" type="coefficient">
      <cld:property name="n">0</cld:property>
      <cld:property name="value">0</cld:property>
    </cld:object>
    <cld:object id="cft1" type="coefficient">
      <cld:property name="n">1</cld:property>
      <cld:property name="value">1</cld:property>
    </cld:object>
  </cld:object>
  <!-- ... x9 -->
</cld:objects>
```
