#include "NetworkManager.h"
#include "globals.h" 
#include "face_algo.h"

WiFiClient espClient;
PubSubClient mqttClient(espClient);

String macAddr;
String cmdTopic;

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
    } 
    else if (strcmp(cmd, "start_enroll") == 0) {
        Serial.println("Yêu cầu quét khuôn mặt mới!");
        const char* p_id = dataObj["profile_id"];
        
        current_state = STATE_SCANNING; 
    }
    else if (strcmp(cmd, "sync_face") == 0) {
        Serial.println("Đang đồng bộ Vector từ Server...");
        JsonArray vectors = dataObj["face_vectors"];
    }
}

void initNetwork() {
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED) { delay(500); }
    
    macAddr = WiFi.macAddress();
    Serial.println(macAddr);
    cmdTopic = "smartlock/devices/" + macAddr + "/command";

    mqttClient.setServer(MQTT_SERVER, 1883);
    mqttClient.setCallback(mqttCallback);
    mqttClient.setBufferSize(8192); 
}

void handleNetworkLoop() {
    if (!mqttClient.connected()) {
        if (mqttClient.connect(macAddr.c_str())) {
            mqttClient.subscribe(cmdTopic.c_str());
            Serial.println("MQTT Connected!");
        }
    }
    mqttClient.loop();
}