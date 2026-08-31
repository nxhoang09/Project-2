#include "hal_hardware.h"
#include "globals.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

LiquidCrystal_I2C lcd(0x27, 16, 2);
SemaphoreHandle_t lcdMutex = NULL;

int current_user_id = -1;
int current_fail_count = 0;

void setUnlockData(int userId) { current_user_id = userId; }
void setFailData(int count) { current_fail_count = count; }

void safeLcdPrint(const char* line1, const char* line2) {
    if (lcdMutex != NULL && xSemaphoreTake(lcdMutex, portMAX_DELAY)) {
        lcd.clear();
        if (line1) {
            lcd.setCursor(0, 0);
            lcd.print(line1);
        }
        if (line2) {
            lcd.setCursor(0, 1);
            lcd.print(line2);
        }
        xSemaphoreGive(lcdMutex);
    }
}


void initHardware(){
    pinMode(BUTTON_PIN, INPUT);
    Wire.begin(SDA_PIN, SCL_PIN);

   lcdMutex = xSemaphoreCreateMutex();

    if (lcdMutex != NULL && xSemaphoreTake(lcdMutex, portMAX_DELAY)) {
        lcd.init();
        lcd.backlight();
        xSemaphoreGive(lcdMutex);
    }
    showSystemReady();
}

bool isButtonPressed() {
    if (digitalRead(BUTTON_PIN) == HIGH) {
        vTaskDelay(pdMS_TO_TICKS(50)); 
        return (digitalRead(BUTTON_PIN) == HIGH);
    }
    return false;
}

void clearDisplay() {
    if (lcdMutex != NULL && xSemaphoreTake(lcdMutex, portMAX_DELAY)) {
        lcd.clear();
        xSemaphoreGive(lcdMutex);
    }
}

void showSystemReady() {
    safeLcdPrint("SYSTEM READY", "Press to Scan");
}

void showSuccess() {
    if (current_user_id == -1) {
        safeLcdPrint("UNLOCK SUCCESS", "By Mobile App");
    } else {
        char buf[16];
        sprintf(buf, "User ID: %d", current_user_id);
        safeLcdPrint("UNLOCK SUCCESS", buf);
    }
}

void showWarning() {
    if (current_fail_count >= 2) {
        safeLcdPrint("!!! WARNING !!!", "INTRUDER ALERT");
    } else {
        char buf[16];
        sprintf(buf, "Try again (%d/2)", current_fail_count);
        safeLcdPrint("ACCESS DENIED", buf);
    }
}

void showSpoof() {
    for (int i = 0; i < 5; i++) {
        safeLcdPrint("!!! SPOOF !!!", "FAKE FACE");
        vTaskDelay(pdMS_TO_TICKS(300));
        clearDisplay();
        vTaskDelay(pdMS_TO_TICKS(300));
    }
}

void showEnrollStart() {
    safeLcdPrint("ENROLL NEW FACE", "Look at camera");
}

void showEnrollProgress(int current, int total) {
    char buf[16];
    sprintf(buf, "Sample: %d/%d", current, total);
    safeLcdPrint("ENROLLING...", buf);
}

void showEnrollSuccess() {
    safeLcdPrint("ENROLL SUCCESS", "Face saved!");
}

void showDeleteSuccess() {
    safeLcdPrint("DELETE SUCCESS", "Face removed");
}

void showBLEProvisioning() {
    safeLcdPrint("BLE SETUP MODE", "Connect via App");
}
