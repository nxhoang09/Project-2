#include "enroll_flow.h"
#include "face_db.h"
#include "NetworkManager.h"

static bool enrolling = false;
static int current_local_id = -1;
static int sample_count = 0;
static char current_profile_id[37];

#define REQUIRED_SAMPLES 4

void startEnroll(const char* profile_id) {
    enrolling = true;
    current_local_id = -1;
    sample_count = 0;

    strncpy(current_profile_id, profile_id, sizeof(current_profile_id) - 1);
    current_profile_id[36] = '\0';
    Serial.println("=== START ENROLL ===");
}

bool isEnrolling() {
    return enrolling;
}

void processEnroll(float *embedding) {

    if (!enrolling) return;

    if (current_local_id == -1) {
        current_local_id = createUserWithProfileId(current_profile_id, embedding);
        Serial.printf("Create user %d\n", current_local_id);
    } else {
        addEmbedding(current_local_id, embedding);
    }

    sample_count++;

    Serial.printf("Sample %d/%d\n", sample_count, REQUIRED_SAMPLES);

    if (sample_count >= REQUIRED_SAMPLES) {
        enrolling = false;
        int local_ids[1] = { current_local_id };
        float* vectors = (float*)users[current_local_id].embeddings;
        sendEnrollResult(current_profile_id, "success", local_ids, 1, vectors, REQUIRED_SAMPLES);
        Serial.println("=== ENROLL DONE ===");
    }
}