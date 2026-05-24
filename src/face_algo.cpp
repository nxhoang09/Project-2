#include "face_algo.h"
#include <Arduino.h>
#include "globals.h"
#include "SPIFFS.h"
#include "human_face_detect_msr01.hpp"
#include "human_face_detect_mnp01.hpp"
#include "face_recognition_112_v1_s8.hpp"
#include "liveness_algo.h"

#include "face_db.h"
#include "enroll_flow.h"
#include "NetworkManager.h" 

HumanFaceDetectMSR01 s1_detector(0.1F, 0.5F, 10, 0.2F);
HumanFaceDetectMNP01 s2_detector(0.1F, 0.5F, 10);
FaceRecognition112V1S8 recognizer;

extern QueueHandle_t frame_queue;

int failed_attempts = 0; 

void initFaceAlgo() {
    Serial.println("Dang khoi tao Face System...");

    initLivenessModel();
    loadFaces();

    Serial.println("Face system ready!");
}

void deleteAllFaces() {
    SPIFFS.remove("/faces.bin");
    total_users = 0;
    Serial.println("Da xoa toan bo du lieu khuon mat!");
}

bool detectFace(camera_fb_t *fb) {

    if (!fb) return false;

    std::list<dl::detect::result_t> &candidates =
        s1_detector.infer((uint16_t *)fb->buf,
        {(int)fb->height, (int)fb->width, 3});

    if (candidates.size() == 0) return false;

    auto &best_face = candidates.front();

    int orig_x = best_face.box[0];
    int orig_y = best_face.box[1];
    int orig_w = best_face.box[2] - best_face.box[0];
    int orig_h = best_face.box[3] - best_face.box[1];

    float PADDING_RATIO = 0.1f;

    int pad_w = (int)(orig_w * PADDING_RATIO);
    int pad_h = (int)(orig_h * PADDING_RATIO);

    int box_x = orig_x - pad_w;
    int box_y = orig_y - pad_h;
    int box_w = orig_w + 2 * pad_w;
    int box_h = orig_h + 2 * pad_h;

    if (box_x < 0) { box_w += box_x; box_x = 0; }
    if (box_y < 0) { box_h += box_y; box_y = 0; }

    if (box_x + box_w > (int)fb->width)
        box_w = fb->width - box_x;

    if (box_y + box_h > (int)fb->height)
        box_h = fb->height - box_y;

    uint32_t live_start = millis();

    bool is_real = checkLiveness(
        (uint16_t*)fb->buf,
        fb->width,
        fb->height,
        box_x, box_y, box_w, box_h
    );

    Serial.printf("| Liveness time: %d ms\n", millis() - live_start);

    if (!is_real) {
       current_state = STATE_SPOOF;
        Serial.println("[CANH BAO] GIA MAO!");
        failed_attempts++;
        if (failed_attempts >= 2) {
            sendAlert("INTRUDER_ALARM", nullptr);
            failed_attempts = 0;
        }
        return false;
    }

    std::list<dl::detect::result_t> &results =
        s2_detector.infer(
            (uint16_t *)fb->buf,
            {(int)fb->height, (int)fb->width, 3},
            candidates
        );

    if (results.size() == 0) return false;

    auto &res = results.front();

    recognizer.recognize(
        (uint16_t *)fb->buf,
        {(int)fb->height, (int)fb->width, 3},
        res.keypoint
    );

    Tensor<float> &emb = recognizer.get_face_emb(-1);

    float embedding[128];
    memcpy(embedding, emb.get_element_ptr(), 128 * sizeof(float));

    if (isEnrolling()) {

        Serial.println("Dang lay mau...");

        processEnroll(embedding);

        Serial.println("Doi frame tiep theo...");
        vTaskDelay(pdMS_TO_TICKS(1000));

        xQueueReset(frame_queue);

        return true;
    }

    uint32_t start_time = millis();

    int id = recognizeFace(embedding);

    uint32_t infer_time = millis() - start_time;

    if (id >= 0) {
        current_state = STATE_OPENED;
        failed_attempts = 0;
        Serial.printf("[MO CUA] USER %d | %d ms\n", id, infer_time);
        sendAlert("UNLOCK_SUCCESS", users[id].profile_id);
    } else {
      current_state = STATE_STRANGER;
        failed_attempts++;
        Serial.printf("[NGUOI LA] Sai lần %d | %d ms\n", failed_attempts, infer_time);

        if (failed_attempts >= 2) {
            Serial.println("🚨 PHÁT HIỆN ĐỘT NHẬP (NGƯỜI LẠ)! Khóa hệ thống!");
            sendAlert("INTRUDER_ALARM", nullptr);
            failed_attempts = 0;
        }
    }

    return true;
}