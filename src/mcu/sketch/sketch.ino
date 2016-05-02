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

#define BOARDID 0x08

// Communication related
IPAddress ns(172, 16, 0, 1);
IPAddress gateway(172, 16, 0, 1);
IPAddress netmask(255, 255, 255, 0);
IPAddress dest(172, 16, 0, 10);

byte mac[] = { 0xFA, 0x7E, 0xB0, 0x0B, 0x1E, 0x50 + BOARDID };
IPAddress ip(172, 16, 0, 100 + BOARDID);
unsigned int port = 3000 + BOARDID;

EthernetUDP Udp;

unsigned int count = 0;
unsigned long lastSend = 0;
const long sendPeriod = 200;
unsigned long lastRead = 0;
const long readPeriod = 50;

// Sensor related
//const int enPins[] = { 3, 5, 17, 16, 15, 14, 8, 7, 6 };   // octagon
const int enPins[] = { 3, 7, 6, 5, 17, 16, 15, 14, 8 };   // octagon
//const int enPins[] = { 8, 7, 6, 5, 17, 16, 15, 14 };      // 8 sensor arrangement
//const int enPins[] = { 8, 7, 6, 5 };                      // 4 sensor arrangement

const int N = sizeof(enPins) / sizeof(int);
MS5803 sensors[N];
bool initialized = false;

const int Z = 2;
const int CSD = 4;
const int CSE = 10;

void setup() {
  Serial.begin(115200);
  delay(1000);

  // Disable all sensors before the initialization of any
  for (int i = 0; i < N; i++) {
    pinMode(enPins[i], OUTPUT);
    digitalWrite(enPins[i], HIGH);
  }

  pinMode(CSD, OUTPUT);
  pinMode(CSE, OUTPUT);
  pinMode(Z, OUTPUT);
  digitalWrite(CSD, HIGH);
  digitalWrite(CSE, HIGH);
  digitalWrite(Z, LOW);

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

  digitalWrite(Z, HIGH);

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

  //String msg = "{|" + String(count++) + "|";
  String msg = "{";

  digitalWrite(Z, LOW);

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

  digitalWrite(Z, HIGH);

  char buf[msg.length()];
  Udp.beginPacket(dest, port);
  msg.toCharArray(buf, msg.length());
  Udp.write(buf);
  Udp.endPacket();

  Serial.print(msg);
}
