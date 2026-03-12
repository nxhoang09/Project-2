#include "face_algo.h"
#include <Arduino.h>

// Include thư viện model MSR01 của Espressif (Nằm trong esp-dl / esp-who)
#include "human_face_detect_msr01.hpp"
// Buffer ảnh đã được resize về 112x112, định dạng RGB888 (3 bytes/pixel)
uint8_t aligned_face_buffer[112*112*3];

void cropAndResize(camera_fb_t *fb, int16_t x, int16_t y, int16_t w, int16_t h, uint8_t *out_buffer) {
   int16_t size =(w > h)? w : h;
   int16_t cx = x + w/2;
   int16_t cy = y + h/2;
   int16_t nx = cx - size/2;
   int16_t ny = cy - size/2;

   uint16_t * src_pixels = (uint16_t *)fb->buf;
   int src_w = fb->width;
   int src_h = fb->height;

   int out_idx =0;

   for(int ty = 0; ty < 112; ty++){
    for(int tx = 0; tx < 112; tx++){
        int sx = nx + (tx*size)/112;
        int sy = ny + (ty * size)/112;

        if(sx < 0) sx = 0;
        if(sx >= src_w) sx = src_w -1;
        if (sy < 0) sy = 0;
        if (sy >= src_h) sy = src_h - 1;

        uint16_t pixel565 = src_pixels[sy*src_w + sx];

        //rgb565->rgb888
        uint8_t r =((pixel565 >> 11) & 0x1F) * 255/31;
        uint8_t g = ((pixel565 >> 5) & 0x3F) * 255/63;
        uint8_t b = (pixel565 & 0x1F) *255/31;

        out_buffer[out_idx++] = b;
        out_buffer[out_idx++] = g;
        out_buffer[out_idx++] = r;
    }
   }

}

// Khởi tạo model với các tham số:
// 0.1F: Ngưỡng tự tin (Confidence threshold) - Đặt thấp để dễ nhận, sau này có thể tăng lên 0.5
// 0.5F: NMS threshold (Loại bỏ các khung hình trùng lặp)
// 10: Số khuôn mặt tối đa nhận diện cùng lúc
// 0.2F: Tham số nội bộ của mạng
HumanFaceDetectMSR01 detector(0.1F, 0.5F, 10, 0.2F);

void initFaceAlgo() {
    Serial.println("--- KHOI TAO MODEL AI: MSR01 ---");
    // Model được nạp thẳng từ Flash vào PSRAM khi chạy
}

bool detectFace(camera_fb_t *fb) {
    if (!fb) return false;

    // Đo thời gian Inference
    uint32_t start_time = millis();

    // Đưa ảnh RGB565 vào mạng nơ-ron. 
    // Hàm infer() ở phiên bản này đã tự động làm NMS và lọc kết quả.
    std::list<dl::detect::result_t> &results = detector.infer((uint16_t *)fb->buf, {(int)fb->height, (int)fb->width, 3});

    uint32_t inference_time = millis() - start_time;

    if (results.size() > 0) {
        auto &res = results.front();
        // Dùng int16_t để xử lý được tọa độ âm (ví dụ Y = -3)
        int16_t x = res.box[0];
        int16_t y = res.box[1];
        int16_t w = res.box[2] - res.box[0];
        int16_t h = res.box[3] - res.box[1];

        uint32_t crop_start = millis();
        cropAndResize(fb, x, y, w, h, aligned_face_buffer);
        uint32_t crop_time = millis() - crop_start;
        Serial.printf("=> Mat 1: X=%d, Y=%d, W=%d, H=%d (Cat & Ép size tốn %d ms)\n", x, y, w, h, crop_time);

        // --- STREAM TEST ---
        Serial.print("CROP");
        
        // Gửi 37,632 bytes ảnh RGB888 (112 * 112 * 3)
        Serial.write(aligned_face_buffer, sizeof(aligned_face_buffer));


        return true;
    } else {
        return false;
    }
}