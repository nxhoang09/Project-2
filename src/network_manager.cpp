#include "NetworkManager.h"
#include "globals.h" 
#include "face_algo.h"
#include "face_db.h"
#include "enroll_flow.h"
#include <SPIFFS.h>

WiFiClient espClient;
PubSubClient mqttClient(espClient);

String macAddr;
String cmdTopic;
String statusTopic;
unsigned long lastReconnectAttempt = 0;

void mqttCallback(char* topic, byte* payload, unsigned int length) {
    DynamicJsonDocument doc(4096); 
    DeserializationError error = deserializeJson(doc, payload, length);

    if (error) {
        Serial.print("Lỗi đọc JSON: ");
        Serial.println(error.c_str());
        return; 
    }
    JsonObject dataObj = doc["data"];
    
    if (dataObj.isNull()) {
        dataObj = doc.as<JsonObject>(); 
    }

    const char* cmd = dataObj["cmd"];

    if (cmd == nullptr) {
        Serial.println("Gói tin JSON không chứa trường 'cmd'!");
        return; 
    }

    Serial.printf("Nhận lệnh: %s\n", cmd);

    if (strcmp(cmd, "unlock") == 0) {
        Serial.println("Yêu cầu mở khóa từ Server!");
        current_state = STATE_OPENED;
        sendUnlockResult("success");
    } 
    else if (strcmp(cmd, "start_enroll") == 0) {
        Serial.println("Yêu cầu quét khuôn mặt mới!");
        const char* p_id = dataObj["profile_id"];
        
        startEnroll(p_id); 
        
        current_state = STATE_SCANNING;
    }
    else if (strcmp(cmd, "sync_face") == 0) {
        Serial.println("Đang đồng bộ Vector từ Server...");
        JsonArray vectors = dataObj["face_vectors"];
    }
    else if(strcmp(cmd, "delete_face") == 0){
        const char *p_id = dataObj["profile_id"];
        bool isDeleted = deleteFaceProfile(p_id);

        if(isDeleted){
            sendDeleteResult(p_id, "success");
        } else {
            sendDeleteResult(p_id, "not_found");
        }
    }
}

void initNetwork() {
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED) { vTaskDelay(pdMS_TO_TICKS(500)); }
    
    macAddr = WiFi.macAddress();
    Serial.println(macAddr);
    cmdTopic = "smartlock/devices/" + macAddr + "/command";
    statusTopic = "smartlock/devices/" + macAddr + "/status";

    mqttClient.setServer(MQTT_SERVER, 1883);
    mqttClient.setCallback(mqttCallback);
    mqttClient.setBufferSize(8192); 
}

void handleNetworkLoop() {
    unsigned long now = millis();
    if (WiFi.status() != WL_CONNECTED) {
        if (now - lastReconnectAttempt > 5000) {
            Serial.println("Mất WiFi! Đang thử bắt lại sóng...");
            WiFi.disconnect();
            WiFi.begin(WIFI_SSID, WIFI_PASS);
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
    mqttClient.loop();
}

void sendEnrollResult(const char* profile_id, const char* status, int* esp_ids, int id_count, float* face_vectors, int sample_count) {
    DynamicJsonDocument doc(10240); 

    doc["status"] = status;
    doc["profile_id"] = profile_id;

    JsonArray idsArray = doc.createNestedArray("local_esp_ids");
    for (int i = 0; i < id_count; i++) {
        idsArray.add(esp_ids[i]);
    }

    JsonArray vectorsArray = doc.createNestedArray("face_vectors");
    for (int i = 0; i < sample_count; i++) {
        JsonArray singleVector = vectorsArray.createNestedArray();
        for (int j = 0; j < EMBEDDING_SIZE; j++) {
            singleVector.add(face_vectors[i * EMBEDDING_SIZE + j]); 
        }
    }

    String output;
    serializeJson(doc, output);
    
    Serial.printf("Đang gửi dữ liệu Enroll lên Server. Kích thước JSON: %d bytes\n", output.length());

    String resultTopic = "smartlock/devices/" + macAddr + "/enroll_result";
    
    if (mqttClient.connected() && mqttClient.setBufferSize(output.length() + 256) && mqttClient.publish(resultTopic.c_str(), output.c_str(), false)) {
        Serial.println("Gửi kết quả Enroll trực tiếp thành công!");
    } else {
        Serial.println("Mất mạng hoặc gửi lỗi! Đang chuyển vào Offline Queue...");
        savePendingReport(resultTopic, output);
    }
}

void sendDeleteResult(const char* profile_id, const char* status) {
    DynamicJsonDocument doc(256);
    doc["status"] = status; 
    doc["profile_id"] = profile_id;

    String output;
    serializeJson(doc, output);
    
    String resultTopic = "smartlock/devices/" + macAddr + "/delete_result";

    if (mqttClient.connected() && mqttClient.publish(resultTopic.c_str(), output.c_str(), false)) {
        Serial.println("Đã gửi báo cáo Xóa thành công lên Server!");
    } else {
        Serial.println("Mất mạng! Lưu báo cáo xóa vào Offline Queue...");
        savePendingReport(resultTopic, output);
    }
}

void savePendingReport(String topic, String payload){
    File file = SPIFFS.open("/pending_mqtt.txt", FILE_APPEND);
    if(!file){
        Serial.println("Không thể mở file SPIFFS để lưu tạm!");
        return;
    }
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

            mqttClient.setBufferSize(payload.length() + 256);

            if (mqttClient.publish(topic.c_str(), payload.c_str(), false)) {
                Serial.printf("Đã gửi bù thành công: %s\n", topic.c_str());
                vTaskDelay(pdMS_TO_TICKS(100)); 
            } else {
                Serial.println("Gửi bù thất bại, lưu trữ lại...");
                tempFile.println(line); 
                allSent = false;
            }
        }
    }
    file.close();
    tempFile.close();

    SPIFFS.remove("/pending_mqtt.txt");
    if(!allSent){
        SPIFFS.rename("/temp_mqtt.txt", "/pending_mqtt.txt");
    } else {
        SPIFFS.remove("/temp_mqtt.txt");
    }
}

void sendAlert(String eventType, const char* profile_id) {
    DynamicJsonDocument doc(256);
    doc["event"] = eventType;
    if (profile_id != nullptr) {
        doc["profile_id"] = profile_id;
    }

    String output;
    serializeJson(doc, output);
    String topic = "smartlock/devices/" + macAddr + "/report";

    if (mqttClient.connected() && mqttClient.publish(topic.c_str(), output.c_str(), false)) {
        Serial.printf("✅ Đã gửi Log [%s] lên Server!\n", eventType.c_str());
    } else {
        savePendingReport(topic, output); 
    }
}
void sendUnlockResult(const char* status, const char* reason) {
    DynamicJsonDocument doc(256);
    doc["cmd"] = "unlock";
    doc["status"] = status; // "success" | "failed"
    if (reason) doc["reason"] = reason;

    String output;
    serializeJson(doc, output);

    String resultTopic = "smartlock/devices/" + macAddr + "/unlock_result";

    if (mqttClient.connected() && mqttClient.publish(resultTopic.c_str(), output.c_str(), false)) {
        Serial.println("Da gui phan hoi mo khoa len Server!");
    } else {
        Serial.println("Mat mang! Luu phan hoi mo khoa vao Offline Queue...");
        savePendingReport(resultTopic, output);
    }
}