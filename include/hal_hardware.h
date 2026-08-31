#ifndef HAL_HARDWARE_H
#define HAL_HARDWARE_H

void initHardware();      
bool isButtonPressed();
void clearDisplay();   

void setUnlockData(int userId);
void setFailData(int count);

// Các hàm hiển thị
void showSystemReady();
void showSuccess();
void showWarning();
void showSpoof();

// Các hàm hiển thị luồng Enroll, Delete & BLE
void showEnrollStart();
void showEnrollProgress(int current, int total);
void showEnrollSuccess();
void showDeleteSuccess();
void showBLEProvisioning();

#endif