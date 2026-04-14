#pragma once
#include <Arduino.h>

#define MAX_USERS 50
#define MAX_EMB_PER_USER 3
#define EMBEDDING_SIZE 128
#define FACE_THRESHOLD 0.5f

struct UserFace {
    int user_id;
    int emb_count;
    float embeddings[MAX_EMB_PER_USER][EMBEDDING_SIZE];
};

extern UserFace users[MAX_USERS];
extern int total_users;

// flash
void loadFaces();
void saveFaces();

// enroll
int createUser(float *embedding);
bool addEmbedding(int user_id, float *embedding);

// recognize
int recognizeFace(float *embedding);

// math
float cosine_similarity(float *a, float *b, int len);