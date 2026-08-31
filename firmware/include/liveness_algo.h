#ifndef LIVENESS_ALGO_H
#define LIVENESS_ALGO_H

#include <Arduino.h>

bool initLivenessModel();

bool checkLiveness(uint16_t* src_img, int src_w, int src_h, 
                   int box_x, int box_y, int box_w, int box_h);

#endif