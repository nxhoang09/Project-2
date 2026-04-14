#ifndef HAL_HARDWARE_H
#define HAL_HARDWARE_H

void initHardware();      
bool isButtonPressed();   
void setLedSuccess();     
void setLedWarning();    
void setLedSpoof();       
void turnOffAllLeds();  

#endif