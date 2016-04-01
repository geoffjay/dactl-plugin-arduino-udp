/**
 * Arduino sketch to read SPI pressure sensors and transmit the measurements
 * to whoever wants to listen. Imposes zero security and zero reliability.
 *
 * Authors:
 *  Christian Veenstra <christian.veenstra@coanda.ca>
 *  Geoff Johnson <geoff.johnson@coanda.ca>
 *  Jeff Mottershead <jeff.mottershead@coanda.ca>
 */

#include <SPI.h>
#include <Ethernet.h>
#include <EthernetUdp.h>

#include "MS5803.h"

// Communication related
byte mac[] = { 0x90, 0xA2, 0xDA, 0x0F, 0xF7, 0xC7 };
IPAddress ip(10, 0, 2, 10);
IPAddress ns(10, 0, 0, 2);
IPAddress gateway(10, 0, 0, 1);
IPAddress netmask(255, 255, 0, 0);

unsigned int port = 3333;
IPAddress dest(10, 0, 2, 2);

EthernetUDP Udp;

unsigned long lastSend = 0;
const long sendPeriod = 1000;
unsigned long lastRead = 0;
const long readPeriod = 50;

// Sensor related
const int enPins[] = { 7, 8, 5, 6, 14, 15, 16, 17, 9 };
const int N = sizeof(enPins) / sizeof(int);
MS5803 sensors[N];
bool initialized = false;

void setup() {
  Serial.begin(115200);
  delay(1000);

  // Disable all sensors before the initialization of any
  for (int i = 0; i < N; i++)
    digitalWrite(enPins[i], HIGH);

  // Initialize the sensor and perform a CRC check
  for (int i = 0; i < N; i++) {
    sensors[i] = MS5803(enPins[i]);
    if (!sensors[i].initializeSensor()) {
      Serial.println("Failed to initialize sensor: " + String(i));
      initialized = false;
    } else {
      initialized = true;
    }
  }

  // Connect to the network and setup a connectionless socket
  Ethernet.begin(mac, ip, ns, gateway, netmask);
  Udp.begin(port);

  Serial.print("Using IP address: ");
  Serial.println(Ethernet.localIP());
}

void loop() {
  //rx();
  tx();
}

/**
 * Poorly named function to receive the new sensor readings. This is largely
 * pointless given that the read could just be done before pulling the value
 * but created nonetheless in case something more, eg. averaging, needs to
 * be done as well.
 */
void rx() {
  if (millis() - lastRead < readPeriod)
    return;

  lastRead = millis();

  for (int i = 0; i < N; i++)
    sensors[i].readSensor();
}

/**
 * Transmit the sensor values over the socket to any listener.
 */
void tx() {
  if (millis() - lastSend < sendPeriod)
    return;

  lastSend = millis();

  String msg = "{";

//  if (!initialized) {
//    Udp.print("-1|NaN");
//  } else {
    for (int i = 0; i < N; i++) {
      sensors[i].readSensor();
      msg += String(sensors[i].pressure());
      if (i != N-1)
        msg += ",";
      else
        msg += "}\n";
    }
//  }

  char buf[msg.length()];
  Udp.beginPacket(dest, port);
  msg.toCharArray(buf, msg.length());
  Udp.write(buf);
  Serial.print(msg);
  Udp.endPacket();
}
