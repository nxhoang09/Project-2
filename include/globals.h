#ifndef GLOBALS_H
#define GLOBALS_H
#include<Arduino.h>

#define BUTTON_PIN 1
#define LED_GREEN_PIN 2
#define LED_RED_PIN 42

#define WIFI_SSID "Phong 301"
#define WIFI_PASS "1234567890"

#define MQTT_SERVER "192.161.71.105" 
#define MQTT_PORT 1883

enum LockState{
    STATE_IDLE, 
    STATE_SCANNING, 
    STATE_OPENED, 
    STATE_STRANGER, 
    STATE_SPOOF
};

extern volatile LockState current_state;

#endif