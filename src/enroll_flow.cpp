#include "enroll_flow.h"
#include "face_db.h"

static bool enrolling = false;
static int current_user = -1;
static int sample_count = 0;

#define REQUIRED_SAMPLES 4

void startEnroll() {
    enrolling = true;
    current_user = -1;
    sample_count = 0;

    Serial.println("=== START ENROLL ===");
}

bool isEnrolling() {
    return enrolling;
}

void processEnroll(float *embedding) {

    if (!enrolling) return;

    if (current_user == -1) {
        current_user = createUser(embedding);
        Serial.printf("Create user %d\n", current_user);
    } else {
        addEmbedding(current_user, embedding);
    }

    sample_count++;

    Serial.printf("Sample %d/%d\n", sample_count, REQUIRED_SAMPLES);

    if (sample_count >= REQUIRED_SAMPLES) {
        enrolling = false;
        Serial.println("=== ENROLL DONE ===");
    }
}