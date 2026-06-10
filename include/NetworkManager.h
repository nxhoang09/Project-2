#ifndef NETWORK_MANAGER_H
#define NETWORK_MANAGER_H

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

void initNetwork();
void handleNetworkLoop();
void sendReport(const char* event);
void sendEnrollResult(const char* profile_id, const char* status, int* esp_ids, int id_count);
void savePendingReport(String topic, String payload);
void sendDeleteResult(const char* profile_id, const char* status);
void processPendingReport();
void sendAlert(String eventType, const char* profile_id);
void sendUnlockResult(const char* status, const char* reason = nullptr);
void startBLEProvisioning();
#endif