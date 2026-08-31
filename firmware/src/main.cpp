#include <Arduino.h>
#include <Preferences.h>
#include "camera_utils.h"
#include "hal_hardware.h"
#include "globals.h"
#include "face_algo.h"
#include "NetworkManager.h"
#include "face_db.h"

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

QueueHandle_t frame_queue;
LockState internal_state = STATE_IDLE;
SemaphoreHandle_t stateMutex = NULL;

#define BOOT_BTN_PIN 0
unsigned long buttonPressStartTime = 0;
bool isButtonPressed_Boot = false;

LockState getLockState() {
    LockState s;
    if (stateMutex != NULL) xSemaphoreTake(stateMutex, portMAX_DELAY);
    s = internal_state;
    if (stateMutex != NULL) xSemaphoreGive(stateMutex);
    return s;
}

void setLockState(LockState s) {
    if (stateMutex != NULL) xSemaphoreTake(stateMutex, portMAX_DELAY);
    internal_state = s;
    if (stateMutex != NULL) xSemaphoreGive(stateMutex);
}

void TaskNetwork(void *pvParameters) {
    initNetwork();
    while (1) {
        handleNetworkLoop();
        vTaskDelay(pdMS_TO_TICKS(50)); // Tăng delay để giảm tải Core 0
    }
}

void TaskCamera(void *pvParameters){
    while(1){
        if (getLockState() == STATE_SCANNING) {
            camera_fb_t *fb = esp_camera_fb_get();
            if(fb){
                // Nếu Queue đầy, phải giải phóng frame ngay lập tức để tránh tràn PSRAM
                if(xQueueSend(frame_queue, &fb, pdMS_TO_TICKS(50)) != pdPASS){
                    esp_camera_fb_return(fb);
                }
            }
        }
        vTaskDelay(pdMS_TO_TICKS(100)); // Nhường CPU
    }
}

void TaskAI(void *pvParameters){
    camera_fb_t *fb = NULL;
    while(1){
        if(xQueueReceive(frame_queue, &fb, portMAX_DELAY) == pdPASS){
            if(getLockState() == STATE_SCANNING){
                detectFace(fb); 
            }
            // Luôn luôn phải trả lại frame buffer
            esp_camera_fb_return(fb);
        }
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

void setup() {
    Serial.begin(1000000);
    initHardware();
    stateMutex = xSemaphoreCreateMutex();
    pinMode(BOOT_BTN_PIN, INPUT_PULLUP);

    Preferences prefs;
    prefs.begin("lock_config", true);
    String ssid = prefs.getString("ssid", "");
    prefs.end();

    if (ssid == "") {
        Serial.println("Chưa có cấu hình WiFi. Khởi động BLE Provisioning...");
        startBLEProvisioning(); 
    }

    if (!initCamera()) {
        Serial.println("Khoi tao camera that bai.");
        while (true) { vTaskDelay(1000); }
    }
    
    initFaceAlgo();

    frame_queue = xQueueCreate(2, sizeof(camera_fb_t *));

    // Phân bổ lại Priority: Network cao nhất để giữ kết nối, AI chạy ngầm
    xTaskCreatePinnedToCore(TaskNetwork, "NetworkTask", 8192, NULL, 3, NULL, 0);
    xTaskCreatePinnedToCore(TaskAI, "AITask", 16384, NULL, 1, NULL, 1);
    xTaskCreatePinnedToCore(TaskCamera, "CameraTask", 8192, NULL, 2, NULL, 1);
}

void loop() {
    if (digitalRead(BOOT_BTN_PIN) == LOW) {
        if (!isButtonPressed_Boot) {
            isButtonPressed_Boot = true;
            buttonPressStartTime = millis();
        } else if (millis() - buttonPressStartTime >= 5000) {
            Preferences prefs;
            prefs.begin("lock_config", false);
            prefs.clear();
            prefs.end();
            deleteAllFaces(); 
            delay(1000);
            ESP.restart(); 
        }
    } else {
        isButtonPressed_Boot = false;
    }

    LockState current = getLockState();

    if (current == STATE_IDLE && isButtonPressed()) {
        xQueueReset(frame_queue);
        setLockState(STATE_SCANNING);
    }
    else if (current == STATE_OPENED) {
        showSuccess();
        vTaskDelay(pdMS_TO_TICKS(3000)); 
        clearDisplay();
        setLockState(STATE_IDLE);
    }
    else if (current == STATE_STRANGER) {
        showWarning();
        vTaskDelay(pdMS_TO_TICKS(2000)); 
        clearDisplay();
        setLockState(STATE_IDLE);
    }
    else if (current == STATE_SPOOF) {
        showSpoof();
        clearDisplay();
        setLockState(STATE_IDLE);
    }
    
    vTaskDelay(pdMS_TO_TICKS(100)); // Nhường CPU cho UI Loop
}