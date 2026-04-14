#include "face_db.h"
#include "SPIFFS.h"
#include <math.h>

UserFace users[MAX_USERS];
int total_users = 0;

void loadFaces() {
    if (!SPIFFS.begin(true)) {
        Serial.println("SPIFFS mount failed");
        return;
    }

    File f = SPIFFS.open("/faces.bin", FILE_READ);
    if (!f) {
        Serial.println("No DB found");
        total_users = 0;
        return;
    }

    f.read((uint8_t*)&total_users, sizeof(int));
    f.read((uint8_t*)users, sizeof(UserFace) * total_users);
    f.close();

    Serial.printf("Loaded %d users\n", total_users);
}

void saveFaces() {
    File f = SPIFFS.open("/faces.bin", FILE_WRITE);
    if (!f) {
        Serial.println("Write failed");
        return;
    }

    f.write((uint8_t*)&total_users, sizeof(int));
    f.write((uint8_t*)users, sizeof(UserFace) * total_users);
    f.close();

    Serial.printf("Saved %d users\n", total_users);
}

int createUser(float *embedding) {
    if (total_users >= MAX_USERS) return -1;

    users[total_users].user_id = total_users;
    users[total_users].emb_count = 1;

    memcpy(users[total_users].embeddings[0], embedding,
           sizeof(float) * EMBEDDING_SIZE);

    total_users++;
    saveFaces();

    return total_users - 1;
}

bool addEmbedding(int user_id, float *embedding) {
    if (user_id >= total_users) return false;

    UserFace &u = users[user_id];

    if (u.emb_count >= MAX_EMB_PER_USER) {
        Serial.println("User full!");
        return false;
    }

    memcpy(u.embeddings[u.emb_count], embedding,
           sizeof(float) * EMBEDDING_SIZE);

    u.emb_count++;
    saveFaces();

    return true;
}

float cosine_similarity(float *a, float *b, int len) {
    float dot = 0, na = 0, nb = 0;

    for (int i = 0; i < len; i++) {
        dot += a[i] * b[i];
        na += a[i] * a[i];
        nb += b[i] * b[i];
    }

    return dot / (sqrt(na) * sqrt(nb) + 1e-6);
}

int recognizeFace(float *embedding) {
    float best = 0;
    int best_id = -1;

    for (int i = 0; i < total_users; i++) {
        for (int j = 0; j < users[i].emb_count; j++) {

            float score = cosine_similarity(
                embedding,
                users[i].embeddings[j],
                EMBEDDING_SIZE
            );

            if (score > best) {
                best = score;
                best_id = users[i].user_id;
            }
        }
    }

    if (best > FACE_THRESHOLD) {
        Serial.printf("Match user %d (%.3f)\n", best_id, best);
        return best_id;
    }

    Serial.printf("Unknown (%.3f)\n", best);
    return -1;
}