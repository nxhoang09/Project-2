#include "NetworkManager.h"
#include "hal_hardware.h"
#include "globals.h" 
#include "face_algo.h"
#include "face_db.h"
#include "enroll_flow.h"
#include <SPIFFS.h>
#include <Preferences.h>

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#include "freertos/FreeRTOS.h"
#include "freertos/queue.h"

#define SERVICE_UUID           "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID_RX "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CHARACTERISTIC_UUID_TX "a291ce3a-39fb-4b9b-b0b8-4c6e8ea30ab2"

WiFiClient espClient;
PubSubClient mqttClient(espClient);
Preferences preferences;

// Khai báo Hàng đợi (Queue) giao tiếp giữa 2 Core
struct MqttMsg {
    char topic[64];
    char payload[512];
};
QueueHandle_t mqttTxQueue;

String macAddr;
String cmdTopic;
String statusTopic;
String savedSSID = "";
String savedPASS = "";
unsigned long lastReconnectAttempt = 0;

BLECharacteristic *pCharacteristicTX;
bool deviceConnected = false;
bool shouldRestartBLE = false;

// Cấu trúc Hàm đẩy dữ liệu vào Hàng đợi một cách an toàn
void enqueueMqtt(String topic, String payload) {
    if (WiFi.status() != WL_CONNECTED || !mqttClient.connected()) {
        savePendingReport(topic, payload);
        return;
    }

    MqttMsg msg;
    strncpy(msg.topic, topic.c_str(), sizeof(msg.topic) - 1);
    msg.topic[sizeof(msg.topic) - 1] = '\0';
    
    strncpy(msg.payload, payload.c_str(), sizeof(msg.payload) - 1);
    msg.payload[sizeof(msg.payload) - 1] = '\0';

    // Gửi vào Queue, nếu Queue đầy thì lưu offline và giải phóng RAM
    if (xQueueSend(mqttTxQueue, &msg, pdMS_TO_TICKS(100)) != pdPASS) {
        Serial.println("⚠️ Hàng đợi MQTT đầy! Đẩy vào SPIFFS...");
        savePendingReport(topic, payload);
    }
}

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) { deviceConnected = true; Serial.println("BLE: Đã kết nối!"); }
    void onDisconnect(BLEServer* pServer) { deviceConnected = false; BLEDevice::startAdvertising(); }
};

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
        std::string rxValue = pCharacteristic->getValue();
        if (rxValue.length() > 0) {
            DynamicJsonDocument doc(1024);
            if (deserializeJson(doc, rxValue)) return;
            
            preferences.begin("lock_config", false);
            preferences.putString("ssid", (const char*)doc["ssid"]);
            preferences.putString("pass", (const char*)doc["password"]);
            preferences.putString("owner", (const char*)doc["owner_id"]);
            preferences.end();

            DynamicJsonDocument resDoc(256);
            resDoc["status"] = "success";
            resDoc["mac_address"] = WiFi.macAddress();
            String resStr;
            serializeJson(resDoc, resStr);

            pCharacteristicTX->setValue(resStr.c_str());
            pCharacteristicTX->notify(); 
            shouldRestartBLE = true; 
        }
    }
};

void startBLEProvisioning() {
    showBLEProvisioning();
    String mac = WiFi.macAddress();
    String bleName = "SmartLock_" + mac.substring(12, 17);
    bleName.replace(":", "");
    
    BLEDevice::init(bleName.c_str());
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks());

    BLEService *pService = pServer->createService(SERVICE_UUID);
    pCharacteristicTX = pService->createCharacteristic(CHARACTERISTIC_UUID_TX, BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristicTX->addDescriptor(new BLE2902());

    BLECharacteristic *pCharacteristicRX = pService->createCharacteristic(CHARACTERISTIC_UUID_RX, BLECharacteristic::PROPERTY_WRITE);
    pCharacteristicRX->setCallbacks(new MyCallbacks());

    pService->start();
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    BLEDevice::startAdvertising();
    
    Serial.println("Đang phát sóng BLE: " + bleName);
    while (true) {
        if (shouldRestartBLE) {
            delay(2000); ESP.restart(); 
        }
        delay(100);
    }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
    DynamicJsonDocument doc(4096); 
    DeserializationError error = deserializeJson(doc, payload, length);

    if (error) {
        Serial.print("Lỗi đọc JSON: ");
        Serial.println(error.c_str());
        return; 
    }
    JsonObject dataObj = doc["data"];
    if (dataObj.isNull()) dataObj = doc.as<JsonObject>(); 

    const char* cmd = dataObj["cmd"];
    if (cmd == nullptr) return; 

    Serial.printf("Nhận lệnh: %s\n", cmd);

    if (strcmp(cmd, "unlock") == 0) {
        Serial.println("Yêu cầu mở khóa từ Server!");
        setUnlockData(-1);
        setLockState(STATE_OPENED);
        sendUnlockResult("success", nullptr); // Bây giờ gọi từ trong Callback đã an toàn vì nó dùng Queue
    } 
    else if (strcmp(cmd, "start_enroll") == 0) {
        Serial.println("Yêu cầu quét khuôn mặt mới!");
        showEnrollStart();
        const char* p_id = dataObj["profile_id"];
        startEnroll(p_id); 
        setLockState(STATE_SCANNING); 
    }
    else if(strcmp(cmd, "delete_face") == 0){
        const char *p_id = dataObj["profile_id"];
        bool isDeleted = deleteFaceProfile(p_id);
        if (isDeleted) {
            showDeleteSuccess();
            vTaskDelay(pdMS_TO_TICKS(2000));
            clearDisplay();
        }
        sendDeleteResult(p_id, isDeleted ? "success" : "not_found");
    } 
    else if (strcmp(cmd, "factory_reset") == 0){
        Serial.println("Nhận lệnh xóa khóa từ Owner! Bắt đầu tẩy trắng...");
        deleteAllFaces();
        
        preferences.begin("lock_config", false);
        preferences.clear();
        preferences.end();
        
        String resultTopic = "smartlock/devices/" + macAddr + "/delete_result";
        enqueueMqtt(resultTopic, "{\"status\":\"factory_reset_done\"}");
        
        delay(1000);
        ESP.restart();
    }
}

void initNetwork() {
    // Khởi tạo Queue giao tiếp
    mqttTxQueue = xQueueCreate(10, sizeof(MqttMsg));

    SPIFFS.remove("/pending_mqtt.txt");
    SPIFFS.remove("/temp_mqtt.txt");
    preferences.begin("lock_config", true);
    savedSSID = preferences.getString("ssid", "");
    savedPASS = preferences.getString("pass", "");
    preferences.end();

    WiFi.begin(savedSSID.c_str(), savedPASS.c_str());
    while (WiFi.status() != WL_CONNECTED) { vTaskDelay(pdMS_TO_TICKS(500)); }
    
    macAddr = WiFi.macAddress();
    Serial.println(macAddr);
    cmdTopic = "smartlock/devices/" + macAddr + "/command";
    statusTopic = "smartlock/devices/" + macAddr + "/status";

    mqttClient.setServer(MQTT_SERVER, 1883);
    mqttClient.setCallback(mqttCallback);
    
    // CỐ ĐỊNH bộ đệm 1 LẦN DUY NHẤT để chống phân mảnh RAM
    if (!mqttClient.setBufferSize(10240)) {
        Serial.println("CẢNH BÁO: Không đủ RAM liên tục để cấp phát Buffer MQTT!");
    }
}

void handleNetworkLoop() {
    unsigned long now = millis();
    if (WiFi.status() != WL_CONNECTED) {
        if (now - lastReconnectAttempt > 5000) {
            Serial.println("Mất WiFi! Đang thử bắt lại sóng...");
            WiFi.disconnect();
            WiFi.begin(savedSSID.c_str(), savedPASS.c_str());
            lastReconnectAttempt = now;
        }
        return;
    }

    if (!mqttClient.connected()) {
        if (now - lastReconnectAttempt > 5000) {
            Serial.println("Rớt mạng MQTT! Đang gọi lại Server...");
            if (mqttClient.connect(macAddr.c_str(), nullptr, nullptr, statusTopic.c_str(), 1, true, "OFFLINE", false)) {
                Serial.println("Đã khôi phục kết nối MQTT!");
                mqttClient.publish(statusTopic.c_str(), "ONLINE", true);
                mqttClient.subscribe(cmdTopic.c_str(), 1); 
                lastReconnectAttempt = 0;
                processPendingReport(); 
            } else {
                Serial.printf("Bắt tay Server thất bại. Mã lỗi: %d\n", mqttClient.state());
                lastReconnectAttempt = now;
            }
        }
        return;
    }
    
    mqttClient.loop(); // Lắng nghe Server

    // XỬ LÝ HÀNG ĐỢI (Queue)
    MqttMsg msg;
    while (xQueueReceive(mqttTxQueue, &msg, 0) == pdPASS) {
       if (!mqttClient.publish(msg.topic, msg.payload, false)) {
            Serial.println("❌ Lỗi Publish! Lưu offline...");
            savePendingReport(String(msg.topic), String(msg.payload));
        }
    }
}

void sendEnrollResult(const char* profile_id, const char* status, int* esp_ids, int id_count) {
    DynamicJsonDocument doc(512); 
    doc["status"] = status;
    doc["profile_id"] = profile_id;

    JsonArray idsArray = doc.createNestedArray("local_esp_ids");
    for (int i = 0; i < id_count; i++) idsArray.add(esp_ids[i]);

    String output;
    serializeJson(doc, output);
    String resultTopic = "smartlock/devices/" + macAddr + "/enroll_result";
    enqueueMqtt(resultTopic, output);
}

void sendDeleteResult(const char* profile_id, const char* status) {
    DynamicJsonDocument doc(256);
    doc["status"] = status; 
    doc["profile_id"] = profile_id;

    String output;
    serializeJson(doc, output);
    String resultTopic = "smartlock/devices/" + macAddr + "/delete_result";
    enqueueMqtt(resultTopic, output);
}

void savePendingReport(String topic, String payload){
    File file = SPIFFS.open("/pending_mqtt.txt", FILE_APPEND);
    if(!file) return;
    file.println(topic + "|||" + payload);
    file.close();
}

void processPendingReport(){
    if(!SPIFFS.exists("/pending_mqtt.txt")) return;
    File file = SPIFFS.open("/pending_mqtt.txt", FILE_READ);
    if(!file) return ;

    File tempFile = SPIFFS.open("/temp_mqtt.txt", FILE_WRITE);
    String line;
    bool allSent = true;

    while(file.available()){
        line = file.readStringUntil('\n');
        line.trim();
        if(line.length() == 0) continue;
        int separatorIdx = line.indexOf("|||");

        if(separatorIdx > 0){
            String topic = line.substring(0, separatorIdx);
            String payload = line.substring(separatorIdx + 3);

            if (mqttClient.publish(topic.c_str(), payload.c_str(), false)) {
                Serial.printf("Đã gửi bù thành công: %s\n", topic.c_str());
                vTaskDelay(pdMS_TO_TICKS(100)); 
            } else {
                tempFile.println(line); 
                allSent = false;
            }
        }
    }
    file.close();
    tempFile.close();

    SPIFFS.remove("/pending_mqtt.txt");
    if(!allSent) SPIFFS.rename("/temp_mqtt.txt", "/pending_mqtt.txt");
    else SPIFFS.remove("/temp_mqtt.txt");
}

void sendAlert(String eventType, const char* profile_id) {
    DynamicJsonDocument doc(256);
    doc["event"] = eventType;
    if (profile_id != nullptr) doc["profile_id"] = profile_id;

    String output;
    serializeJson(doc, output);
    String topic = "smartlock/devices/" + macAddr + "/report";
    
    enqueueMqtt(topic, output);
}

void sendUnlockResult(const char* status, const char* reason) {
    DynamicJsonDocument doc(256);
    doc["cmd"] = "unlock";
    doc["status"] = status; 
    if (reason) doc["reason"] = reason;

    String output;
    serializeJson(doc, output);
    String resultTopic = "smartlock/devices/" + macAddr + "/unlock_result";
    
    enqueueMqtt(resultTopic, output);
}