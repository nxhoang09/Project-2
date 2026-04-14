#include "hal_hardware.h"
#include "globals.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

void initHardware(){
    pinMode(BUTTON_PIN, INPUT);
    pinMode(LED_GREEN_PIN, OUTPUT);
    pinMode(LED_RED_PIN, OUTPUT);
    turnOffAllLeds();
}

bool isButtonPressed() {
    if (digitalRead(BUTTON_PIN) == HIGH) {
        vTaskDelay(pdMS_TO_TICKS(50)); 
        return (digitalRead(BUTTON_PIN) == HIGH);
    }
    return false;
}
void turnOffAllLeds() {
    digitalWrite(LED_GREEN_PIN, LOW);
    digitalWrite(LED_RED_PIN, LOW);
}

void setLedSuccess() {
    digitalWrite(LED_GREEN_PIN, HIGH);
    digitalWrite(LED_RED_PIN, LOW);
}

void setLedWarning() {
    digitalWrite(LED_GREEN_PIN, LOW);
    digitalWrite(LED_RED_PIN, HIGH);
}

void setLedSpoof() {
    digitalWrite(LED_GREEN_PIN, LOW);
    bool led_toggle = false;
    for (int i = 0; i < 20; i++) {
        led_toggle = !led_toggle;
        if(led_toggle){
            digitalWrite(LED_RED_PIN, HIGH);
        } else {
            digitalWrite(LED_RED_PIN, LOW);
        }
        vTaskDelay(pdMS_TO_TICKS(200));
    }
    digitalWrite(LED_RED_PIN, LOW);
}