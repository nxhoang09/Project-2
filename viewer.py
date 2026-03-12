import serial
import cv2
import numpy as np

SERIAL_PORT = '/dev/ttyACM0' 
BAUD_RATE = 2000000

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
    print("Đang chờ khuôn mặt từ ESP32...")
except Exception as e:
    print(f"Lỗi kết nối: {e}")
    exit()

cv2.namedWindow("ESP32 Cropped Face 112x112", cv2.WINDOW_AUTOSIZE)

while True:
    if ser.read(1) == b'C':
        if ser.read(3) == b'ROP':
            
            # Đọc đúng 37,632 bytes (112 x 112 x 3 kênh màu)
            img_data = ser.read(37632)
            
            if len(img_data) == 37632:
                # Ảnh ESP32 gửi lên đã là 8-bit, 3 kênh màu, ta chỉ việc định hình lại
                img_888 = np.frombuffer(img_data, dtype=np.uint8).reshape((112, 112, 3))
                
                # Phóng to ảnh lên 400x400 để dễ nhìn
                img_show = cv2.resize(img_888, (400, 400), interpolation=cv2.INTER_LINEAR)
                
                cv2.imshow("ESP32 Cropped Face 112x112", img_show)
            
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

ser.close()
cv2.destroyAllWindows()