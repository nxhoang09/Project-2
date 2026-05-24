#include "hal_hardware.h"
#include "globals.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);

void initHardware(){
    pinMode(BUTTON_PIN, INPUT);
    Wire.begin(SDA_PIN, SCL_PIN);

    lcd.init();
    lcd.backlight();

    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("System Ready");
}

bool isButtonPressed() {
    if (digitalRead(BUTTON_PIN) == HIGH) {
        vTaskDelay(pdMS_TO_TICKS(50)); 
        return (digitalRead(BUTTON_PIN) == HIGH);
    }
    return false;
}

void clearDisplay() {
    lcd.clear();
}

void showSuccess() {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("ACCESS GRANTED");
    lcd.setCursor(0, 1);
    lcd.print("Welcome!");
}

void showWarning() {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("ACCESS DENIED");
    lcd.setCursor(0, 1);
    lcd.print("Try again");
}

void showSpoof() {
    for (int i = 0; i < 10; i++) {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("!!! SPOOF !!!");

        vTaskDelay(pdMS_TO_TICKS(300));

        lcd.clear();
        vTaskDelay(pdMS_TO_TICKS(300));
    }

    lcd.clear();
}