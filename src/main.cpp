#include <Arduino.h>
#include "camera_utils.h"
#include "hal_hardware.h"
#include "globals.h"
#include "face_algo.h"
#include "NetworkManager.h"

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"
#include "freertos/task.h"

QueueHandle_t frame_queue;
volatile LockState current_state = STATE_IDLE;

void TaskNetwork(void *pvParameters) {
    Serial.println("NetworkTask khởi động trên Core 0");
    initNetwork();

    while (1) {
        handleNetworkLoop();
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

void TaskCamera(void *pvParameters){
    Serial.println("TaskCamera dang chay tren core 1");
    while(1){
        if (current_state == STATE_SCANNING) {
            camera_fb_t *fb = esp_camera_fb_get();
            if(fb){
                if(xQueueSend(frame_queue, &fb, pdMS_TO_TICKS(100)) != pdPASS){
                    esp_camera_fb_return(fb);
                }
            } else {
                vTaskDelay(pdMS_TO_TICKS(100));
            }
            vTaskDelay(pdMS_TO_TICKS(100));
        } else {
            vTaskDelay(pdMS_TO_TICKS(100));
        }
    }
}
void TaskAI(void *pvParameters){
    Serial.println("TaskAI dang chay tren core 1");
    camera_fb_t *fb = NULL;
    while(1){
        if(xQueueReceive(frame_queue, &fb, portMAX_DELAY) == pdPASS){
            if(current_state == STATE_SCANNING){
                detectFace(fb);
            }
            esp_camera_fb_return(fb);
            vTaskDelay(pdMS_TO_TICKS(10));
        }
    }
}

void setup() {
    Serial.begin(1000000);
    initHardware();
    disableCore0WDT();
    if (!initCamera()) {
        Serial.println("Khoi tao camera that bai.");
        while (true) { delay(100); }
    }
    Serial.println("Khoi tao camera thanh cong");
    initFaceAlgo();
    Serial.println("Khoi tao face detection thanh cong");

    frame_queue = xQueueCreate(2, sizeof(camera_fb_t *));
    if(frame_queue == NULL){
        Serial.println("Khong the tao queue");
        while(1){
            delay(100);
        }
    }
    xTaskCreatePinnedToCore(TaskAI,"AITask", 8192 * 4, NULL, 1, NULL, 1);
    xTaskCreatePinnedToCore(TaskCamera, "CameraTask", 8192, NULL, 2, NULL, 1);
    xTaskCreatePinnedToCore(TaskNetwork, "NetworkTask", 8192, NULL, 1, NULL, 0);
}
void loop() {
    if (current_state == STATE_IDLE && isButtonPressed()) {
        Serial.println("=> BAT DAU QUET KHUON MAT!");
        xQueueReset(frame_queue);
        current_state = STATE_SCANNING;
    }

    if (current_state == STATE_OPENED) {
        showSuccess();
        vTaskDelay(pdMS_TO_TICKS(5000)); 
        clearDisplay();
        current_state = STATE_IDLE;
    }
    else if (current_state == STATE_STRANGER) {
        showWarning();
        vTaskDelay(pdMS_TO_TICKS(3000)); 
        clearDisplay();
        current_state = STATE_IDLE;
    }
    else if (current_state == STATE_SPOOF) {
        showSpoof();
        current_state = STATE_IDLE;
    }
   if (Serial.available() > 0) {
        char c = Serial.read();
        if (c == 'E' || c == 'e') {
            //requestEnroll(); 
        }
        else if (c == 'D' || c == 'd') {
            deleteAllFaces();
        }
    }
    
    vTaskDelay(pdMS_TO_TICKS(100)); // Nhường CPU
}