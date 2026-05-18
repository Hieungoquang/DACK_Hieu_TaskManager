# ĐẶC TẢ NGHIỆP VỤ HỆ THỐNG - TASKFLOW

Tài liệu này cung cấp mô tả chi tiết cho toàn bộ các Use Case (UC) có trong ứng dụng TaskFlow, phục vụ cho quá trình phát triển và kiểm thử.

---

## 1. PHÂN HỆ XÁC THỰC & TÀI KHOẢN

### UC-AUTH-01: Đăng ký tài khoản
*   **Mô tả:** Người dùng tạo tài khoản mới để bắt đầu sử dụng.
*   **Luồng cơ bản:**
    1. Người dùng nhập: Tên hiển thị, Email, Mật khẩu, Số điện thoại.
    2. Hệ thống kiểm tra định dạng email và độ mạnh mật khẩu.
    3. Hệ thống gửi yêu cầu tạo tài khoản đến Firebase Auth.
    4. Firebase tạo UID và lưu thông tin cơ bản.
    5. Hệ thống khởi tạo hồ sơ người dùng trong Firestore và Hive.
*   **Ngoại lệ:** Email đã tồn tại hoặc lỗi kết nối mạng.

### UC-AUTH-02: Cập nhật hồ sơ & Avatar
*   **Mô tả:** Thay đổi thông tin cá nhân và ảnh đại diện.
*   **Luồng cơ bản:**
    1. Người dùng chọn ảnh từ thư viện hoặc sửa thông tin văn bản.
    2. Hệ thống upload ảnh lên Firebase Storage (nếu có đổi ảnh).
    3. Hệ thống cập nhật bản ghi trong Firestore và ghi đè vào Hive local.

---

## 2. PHÂN HỆ QUẢN LÝ CÔNG VIỆC (TASK)

### UC-TASK-01: Tạo nhiệm vụ mới (CRUD Task)
*   **Mô tả:** Thiết lập công việc cá nhân hoặc trong dự án.
*   **Luồng cơ bản:**
    1. Người dùng nhập tiêu đề, chọn deadline và độ ưu tiên.
    2. Hệ thống kiểm tra xung đột thời gian (Overlap) với các Task quan trọng khác.
    3. Hệ thống lưu vào Hive và gán trạng thái `pending`.
    4. Hệ thống đặt lịch thông báo (Notification Service).

### UC-TASK-02: Quản lý Checklist (Subtasks)
*   **Mô tả:** Chia nhỏ nhiệm vụ chính thành các đầu việc cụ thể.
*   **Luồng cơ bản:**
    1. Người dùng thêm các Task con vào Task cha.
    2. Khi một Task con được tích chọn, hệ thống tính toán lại `% progress` của Task cha.
    3. Khi tất cả Task con hoàn thành, hệ thống hỏi người dùng có muốn chuyển Task cha sang `completed` không.

### UC-TASK-03: Theo dõi thời gian (Timer)
*   **Mô tả:** Đo lường thời gian thực hiện thực tế.
*   **Luồng cơ bản:**
    1. Người dùng nhấn nút Start trên một Task.
    2. Hệ thống chạy đồng hồ đếm giây.
    3. Khi nhấn Stop, hệ thống tạo bản ghi `Time_logs`.
    4. Hệ thống gợi ý cập nhật tiến độ dựa trên thời gian vừa làm.

---

## 3. PHÂN HỆ QUẢN LÝ DỰ ÁN (PROJECT)

### UC-PROJ-01: Tạo & Mời thành viên
*   **Mô tả:** Xây dựng không gian làm việc nhóm.
*   **Luồng cơ bản:**
    1. Chủ dự án tạo Project và chọn màu sắc nhận diện.
    2. Chủ dự án nhập email thành viên để gửi lời mời.
    3. Thành viên chấp nhận -> Hệ thống đồng bộ dự án về máy thành viên.

---

## 4. PHÂN HỆ TRỢ LÝ AI (AI FEATURES)

### UC-AI-01: Lập lộ trình mục tiêu bằng AI
*   **Mô tả:** AI tự động đề xuất các bước thực hiện cho một mục tiêu mơ hồ.
*   **Luồng cơ bản:**
    1. Người dùng nhập: "Tự học tiếng Nhật cơ bản".
    2. AI trả về lộ trình 5-10 bước kèm thời lượng và độ ưu tiên.
    3. Người dùng nhấn "Apply" -> Hệ thống tự động tạo chuỗi Task có liên kết phụ thuộc (Link Chain).

---

## 5. PHÂN HỆ PHÂN TÍCH & TỰ ĐỘNG HÓA

### UC-AUTO-01: Dự báo khủng hoảng (Crisis Prediction)
*   **Mô tả:** Cảnh báo rủi ro trễ hạn dựa trên dữ liệu thực tế.
*   **Luồng cơ bản:**
    1. Hệ thống lấy dữ liệu `delay_rate` trong quá khứ của User.
    2. Tính xác suất trễ hạn của Task hiện tại dựa trên: (Thời gian còn lại / Khối lượng việc).
    3. Nếu xác suất > 0.7 -> Phát cảnh báo khẩn cấp.

### UC-AUTO-02: Reality Check (Phân tích trì hoãn)
*   **Mô tả:** AI đưa ra nhận xét thực tế về năng suất của người dùng.
*   **Luồng cơ bản:**
    1. Hệ thống thống kê số việc trễ hạn và tồn đọng.
    2. AI Service chọn câu nhận xét (Roast Message) phù hợp với "Chỉ số lười biếng".
    3. Hiển thị biểu đồ đo mức độ trì hoãn cho người dùng.

### UC-AUTO-03: Chế độ đóng băng giấc ngủ (Sleep Mode)
*   **Mô tả:** Bảo vệ giấc ngủ và tránh lỗi trễ hạn ảo ban đêm.
*   **Luồng cơ bản:**
    1. Đến khung giờ cấu hình (ví dụ 22h - 6h).
    2. Hệ thống ngừng chuyển trạng thái Task sang trễ hạn.
    3. Hệ thống tự động tắt tiếng/hủy các thông báo nhắc nhở trong khoảng này.
