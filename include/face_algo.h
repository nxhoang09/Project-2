#ifndef FACE_ALGO_H
#define FACE_ALGO_H

#include "esp_camera.h"
void initFaceAlgo();

bool detectFace(camera_fb_t *fb);

void requestEnroll();

void deleteAllFaces();


#endif