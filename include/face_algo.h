#ifndef FACE_ALGO_H
#define FACE_ALGO_H

#include "esp_camera.h"

// Hàm khởi tạo các tham số AI
void initFaceAlgo();

// Hàm nhận diện khuôn mặt, trả về true nếu có người
bool detectFace(camera_fb_t *fb);

#endif