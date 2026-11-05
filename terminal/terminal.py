import serial
import time
import sys

# ====================== CẤU HÌNH ======================
COM_PORT = "COM16"          # ← THAY BẰNG CỔNG COM CỦA BẠN
BAUDRATE = 115200          # Tốc độ baudrate của UART_RX/TX
TIMEOUT  = 2               # Thời gian chờ (giây)

# Bảng dịch Toán học sang Opcode của ALU
ALU_MODE = {
    '+': 0x00, '-': 0x01, '&': 0x02, '|': 0x03, 
    '^': 0x04, '~a': 0x05, '~b': 0x06, 'cmp': 0x07, 
    'a': 0x08, 'b': 0x09
}
# =====================================================

def connect_uart():
    try:
        ser = serial.Serial(COM_PORT, BAUDRATE, timeout=TIMEOUT)
        print(f"✅ [SUCCESS] Đã kết nối thành công với FPGA qua {COM_PORT} ({BAUDRATE} baud)")
        return ser
    except Exception as e:
        print(f"❌ [ERROR] Không thể mở cổng {COM_PORT}. Hãy kiểm tra lại dây cáp hoặc tên cổng!")
        sys.exit()

def print_menu():
    print("\n" + "="*50)
    print(" 🚀 TRẠM ĐIỀU KHIỂN ALU FPGA - TUẤN ĐẸP TRAI DUT 🚀")
    print("="*50)
    print("🎯 CÁC TOOL DỊCH HỖ TRỢ:")
    print("  1. Nhập HEX trực tiếp   : Gõ 3 byte. (VD: 05 03 00)")
    print("  2. Tool dịch ASCII      : Gõ 'ascii <ký tự>'. (VD: ascii A B C)")
    print("  3. Tool dịch TOÁN HỌC   : Gõ 'math <A> <phép toán> <B>'. (VD: math 5 + 3)")
    print("     (Các phép toán hỗ trợ: +, -, &, |, ^, ~a, ~b, cmp, a, b)")
    print("  4. Gõ 'q' để thoát.")
    print("="*50)

def main():
    ser = connect_uart()
    print_menu()

    while True:
        try:
            user_input = input("\n👉 Nhập lệnh: ").strip().lower()
            
            if user_input == 'q':
                print("👋 Đã ngắt kết nối. Tạm biệt Tuấn đẹp trai!")
                break
            
            if not user_input:
                continue

            data_to_send = []

            # ---------------------------------------------------------
            # TOOL 1: DỊCH ASCII SANG HEX
            # ---------------------------------------------------------
            if user_input.startswith("ascii "):
                raw_chars = user_input[6:].replace(" ", "") # Lấy các ký tự sau chữ ascii
                if len(raw_chars) != 3:
                    print("❌ Lỗi: Cần đúng 3 ký tự ASCII! (VD: ascii a b c)")
                    continue
                
                # Hàm ord() dịch ký tự sang mã thập phân, sau đó gửi đi
                data_to_send = [ord(raw_chars[0]), ord(raw_chars[1]), ord(raw_chars[2])]
                print(f"🛠️  [Tool Dịch ASCII]: '{raw_chars[0]}'='{data_to_send[0]:02X}', '{raw_chars[1]}'='{data_to_send[1]:02X}', '{raw_chars[2]}'='{data_to_send[2]:02X}'")

            # ---------------------------------------------------------
            # TOOL 2: DỊCH TOÁN HỌC SANG MÃ ALU
            # ---------------------------------------------------------
            elif user_input.startswith("math "):
                parts = user_input[5:].split()
                if len(parts) != 3:
                    print("❌ Lỗi: Sai cú pháp Math! (VD: math 10 + 5)")
                    continue
                
                try:
                    val_A = int(parts[0])
                    val_B = int(parts[2])
                    op = parts[1]
                    
                    if op not in ALU_MODE:
                        print(f"❌ Lỗi: Phép toán '{op}' không được ALU hỗ trợ!")
                        continue
                    if not (0 <= val_A <= 255 and 0 <= val_B <= 255):
                        print("❌ Lỗi: Số A và B phải từ 0 đến 255 (1 byte)!")
                        continue
                        
                    mode_hex = ALU_MODE[op]
                    data_to_send = [val_A, val_B, mode_hex]
                    print(f"🛠️  [Tool Dịch Math]: A={val_A}(0x{val_A:02X}), B={val_B}(0x{val_B:02X}), Mode={op}(0x{mode_hex:02X})")
                
                except ValueError:
                    print("❌ Lỗi: A và B trong hàm math phải là số tự nhiên!")
                    continue

            # ---------------------------------------------------------
            # TOOL 3: NHẬP HEX TRỰC TIẾP (MẶC ĐỊNH)
            # ---------------------------------------------------------
            else:
                parts = user_input.split()
                if len(parts) != 3:
                    print("❌ Lỗi: Nhập sai định dạng! Cần 3 giá trị. (VD: 05 03 00)")
                    continue
                
                # Dịch từ chuỗi hex (hệ 16) sang số nguyên
                data_to_send = [int(parts[0], 16), int(parts[1], 16), int(parts[2], 16)]

            # ================= GỬI DỮ LIỆU XUỐNG FPGA =================
            ser.write(bytes(data_to_send))
            print(f"📤 [TX] Đã gửi xuống FPGA: 0x{data_to_send[0]:02X} 0x{data_to_send[1]:02X} 0x{data_to_send[2]:02X}")
            
            # ================= CHỜ VÀ ĐỌC KẾT QUẢ =====================
            time.sleep(0.05) # Chờ FPGA tính toán và UART truyền về (50ms)
            
            if ser.in_waiting > 0:
                result = ser.read(1)
                res_val = result[0]
                
                # Dịch ngược kết quả sang ASCII nếu hiển thị được
                res_ascii = chr(res_val) if 32 <= res_val <= 126 else "N/A"
                
                print("="*40)
                print(f"📥 [RX] KẾT QUẢ TỪ FPGA: ")
                print(f"   ▶ HEX   : 0x{res_val:02X}")
                print(f"   ▶ DEC   : {res_val} (Không dấu)")
                print(f"   ▶ ASCII : '{res_ascii}'")
                print("="*40)
            else:
                print("⚠️ [WARNING] Không nhận được phản hồi từ FPGA (Timeout). Hãy kiểm tra lại dây TX/RX!")

        except ValueError:
            print("❌ [ERROR] Giá trị nhập vào không hợp lệ!")
        except Exception as e:
            print(f"❌ [ERROR] Lỗi hệ thống: {e}")
            break

    ser.close()

if __name__ == "__main__":
    main()
