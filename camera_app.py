import serial
import cv2
import numpy as np
import os

# ================= CẤU HÌNH =================
SERIAL_PORT = '/dev/ttyACM0' 
BAUD_RATE = 2000000
LABEL = "spoof"          # Thay bằng 'spoof' khi bạn muốn chụp ảnh giả
TARGET_COUNT = 800    # Số lượng ảnh cần thu thập
# ============================================

# Tự động tạo thư mục chứa ảnh
os.makedirs(f"dataset/{LABEL}", exist_ok=True)
print(f"--- BẮT ĐẦU THU THẬP: {LABEL.upper()} ---")

try:
    ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2)
    print(f"Đã kết nối {SERIAL_PORT} ở tốc độ {BAUD_RATE}")
    print("Đang chờ khuôn mặt từ ESP32...")
except Exception as e:
    print(f"Lỗi kết nối: {e}")
    exit()

cv2.namedWindow("Thu Thap Data Liveness", cv2.WINDOW_AUTOSIZE)

count = 0
is_recording = False

while True:
    # 1. Đợi ESP32 gửi ký tự 'C'
    if ser.read(1) == b'C':
        # 2. Đợi tiếp 3 ký tự 'ROP' để chắc chắn là header "CROP"
        if ser.read(3) == b'ROP':
            
            # 3. Đọc đúng 37,632 bytes (112 x 112 x 3 kênh màu)
            img_data = ser.read(37632)
            
            if len(img_data) == 37632:
                # 4. Định hình lại mảng Byte thành ảnh 112x112
                img_888 = np.frombuffer(img_data, dtype=np.uint8).reshape((112, 112, 3))
                
                # MẸO: Mạch ESP thường gửi hệ màu RGB, nhưng OpenCV lại hiển thị theo hệ BGR. 
                # Nếu không chuyển đổi, mặt bạn trên màn hình sẽ có màu xanh giống Avatar/Xì-trum.
                img_bgr = cv2.cvtColor(img_888, cv2.COLOR_RGB2BGR)
                
                # 5. Phóng to ảnh lên 400x400 để bạn soi gương cho rõ
                img_show = cv2.resize(img_bgr, (400, 400), interpolation=cv2.INTER_LINEAR)
                
                # 6. Logic thu thập ảnh
                if is_recording:
                    # LƯU Ý: Ta chỉ lưu bức ảnh GỐC 112x112 vào ổ cứng (img_bgr) 
                    # để sau này mang lên Colab train AI chuẩn xác nhất!
                    filepath = f"dataset/{LABEL}/{LABEL}_{count:04d}.jpg"
                    cv2.imwrite(filepath, img_bgr)
                    count += 1
                    
                    # Vẽ chữ đỏ đang quay lên màn hình phóng to
                    cv2.putText(img_show, f"REC: {count}/{TARGET_COUNT}", (10, 30), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 0, 255), 2)
                    
                    if count >= TARGET_COUNT:
                        is_recording = False
                        print(f"\n[XONG] Đã thu thập đủ {TARGET_COUNT} ảnh cho nhãn {LABEL}!")
                else:
                    # Vẽ chữ xanh báo sẵn sàng
                    cv2.putText(img_show, "San sang! Bam 's' de chup", (10, 30), 
                                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
                
                # Hiển thị lên màn hình máy tính
                cv2.imshow("Thu Thap Data Liveness", img_show)
            
            # 7. Bắt sự kiện bàn phím
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('s') and not is_recording:
                is_recording = True
                count = 750
                print(f"\n>>> BẮT ĐẦU CHỤP {TARGET_COUNT} ẢNH! Hãy đổi các góc mặt liên tục nhé...")

ser.close()
cv2.destroyAllWindows()