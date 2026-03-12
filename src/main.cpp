#include <Arduino.h>
#include "camera_utils.h"
#include "face_algo.h"

void setup() {
  Serial.begin(2000000);
  delay(2000);
  if (!initCamera()) {
      Serial.println("[LOI] Khoi tao camera that bai. Dung he thong!");
      while (true) { delay(100); }
  }
  Serial.println("[OK] Camera da khoi tao thanh cong!");
  initFaceAlgo();
  Serial.println("\n--- HE THONG SAN SANG SCAN KHUON MAT ---");
}
    

void loop() {
  camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
        Serial.println("[LOI] Khong lay duoc frame!");
        delay(100);
        return;
    }
    detectFace(fb);
    esp_camera_fb_return(fb);
}