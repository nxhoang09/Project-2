#include "liveness_algo.h"
#include "liveness_model.h"

#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"


const tflite::Model* tflite_model = nullptr;
tflite::MicroInterpreter* interpreter = nullptr;
tflite::ErrorReporter* error_reporter = nullptr;
TfLiteTensor* input = nullptr;
TfLiteTensor* output = nullptr;

constexpr int kTensorArenaSize = 250 * 1024; 
uint8_t* tensor_arena = nullptr;
bool is_liveness_ready = false;

bool initLivenessModel() {
    static tflite::MicroErrorReporter micro_error_reporter;
    error_reporter = &micro_error_reporter;

    tflite_model = tflite::GetModel(liveness_model_tflite);
    if (tflite_model->version() != TFLITE_SCHEMA_VERSION) {
        Serial.println("[LOI] Phien ban TFLite khong khop!");
        return false;
    }

    tensor_arena = (uint8_t*)heap_caps_malloc(kTensorArenaSize, MALLOC_CAP_SPIRAM | MALLOC_CAP_8BIT);
    if (tensor_arena == NULL) {
        Serial.println("[LOI] Khong du PSRAM cap phat cho Liveness!");
        return false;
    }

    static tflite::AllOpsResolver resolver;
    static tflite::MicroInterpreter static_interpreter(
        tflite_model, resolver, tensor_arena, kTensorArenaSize, error_reporter);
    interpreter = &static_interpreter;

    if (interpreter->AllocateTensors() != kTfLiteOk) {
        Serial.println("[LOI] Khong du RAM cap phat cho Tensors!");
        return false;
    }
    size_t used_bytes = interpreter->arena_used_bytes();
    Serial.printf("\n[PROFILER] Model Liveness thuc te chi ton: %d Bytes (%.2f KB)\n", 
                  used_bytes, used_bytes / 1024.0);

    input = interpreter->input(0);
    output = interpreter->output(0);
    
    is_liveness_ready = true; 
    Serial.println("-> Khoi tao Liveness AI (TFLite) thanh cong tren PSRAM!");
    return true;
}

bool checkLiveness(uint16_t* src_img, int src_w, int src_h, 
                   int box_x, int box_y, int box_w, int box_h) {
    if (!is_liveness_ready || input == nullptr) return false;

    int index = 0;
    for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
            int src_x = box_x + (x * box_w) / 112;
            int src_y = box_y + (y * box_h) / 112;
            
            src_x = max(0, min(src_w - 1, src_x));
            src_y = max(0, min(src_h - 1, src_y));

            uint16_t pixel = src_img[src_y * src_w + src_x];

            pixel = (pixel >> 8) | (pixel << 8); 
            uint8_t r = (pixel >> 11) & 0x1F;
            uint8_t g = (pixel >> 5)  & 0x3F;
            uint8_t b = pixel         & 0x1F;
            r = (r << 3) | (r >> 2);
            g = (g << 2) | (g >> 4);
            b = (b << 3) | (b >> 2);

            input->data.int8[index++] = (int8_t)(r - 128);
            input->data.int8[index++] = (int8_t)(g - 128);
            input->data.int8[index++] = (int8_t)(b - 128);
        }
    }

    if (interpreter->Invoke() != kTfLiteOk) {
        Serial.println("[LOI] Suy luan Liveness that bai!");
        return false;
    }

    int8_t out_int8 = output->data.int8[0];
    float confidence = (out_int8 - output->params.zero_point) * output->params.scale;
    
    Serial.printf("[LIVENESS] Ti le Real: %.2f%% ", confidence * 100);

    return (confidence >= 0.5f); 
}

