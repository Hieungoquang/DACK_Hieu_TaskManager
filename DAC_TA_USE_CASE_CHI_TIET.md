# TÀI LIỆU ĐẶC TẢ CHI TIẾT USE CASE - TASKFLOW

Tài liệu này cung cấp mô tả chi tiết cho các Use Case quan trọng trong hệ thống quản lý công việc TaskFlow.

---

## NHÓM 1: QUẢN LÝ TÀI KHOẢN (ACCOUNT MANAGEMENT)

### UC01: Đăng nhập (Login)
*   **Tác nhân:** Người dùng, Firebase Auth.
*   **Mô tả:** Người dùng truy cập vào ứng dụng bằng tài khoản đã đăng ký.
*   **Luồng cơ bản:**
    1. Người dùng nhập Email và Mật khẩu.
    2. Người dùng nhấn nút "Đăng nhập".
    3. Hệ thống gửi yêu cầu xác thực đến Firebase Auth.
    4. Firebase xác nhận tài khoản hợp lệ.
    5. Hệ thống tải dữ liệu người dùng và chuyển đến màn hình Home.
*   **Luồng ngoại lệ:**
    *   3a. Sai thông tin: Hệ thống hiển thị thông báo "Email hoặc mật khẩu không chính xác".
    *   3b. Lỗi kết nối: Hiển thị thông báo "Không có kết nối mạng".

---

## NHÓM 2: QUẢN LÝ CÔNG VIỆC (TASK MANAGEMENT)

### UC02: Tạo công việc mới (Create Task)
*   **Tác nhân:** Người dùng.
*   **Mô tả:** Người dùng thiết lập một nhiệm vụ mới để quản lý.
*   **Luồng cơ bản:**
    1. Người dùng nhấn nút "+" tại màn hình Home hoặc Calendar.
    2. Người dùng nhập: Tiêu đề, Mô tả, Ngày hạn, Độ ưu tiên.
    3. Người dùng chọn Danh mục hoặc Dự án (tùy chọn).
    4. Người dùng nhấn "Lưu".
    5. Hệ thống lưu vào cơ sở dữ liệu nội bộ (Hive).
    6. Hệ thống thiết lập thông báo nhắc nhở (Notification).
    7. Hệ thống tự động đồng bộ lên Firestore (nếu có mạng).

### UC03: Quản lý nhiệm vụ phụ thuộc (Dependency Management)
*   **Tác nhân:** Người dùng.
*   **Mô tả:** Đảm bảo công việc B chỉ được thực hiện khi công việc A hoàn thành.
*   **Luồng cơ bản:**
    1. Người dùng chọn công việc B.
    2. Người dùng chọn "Thiết lập phụ thuộc" và chọn công việc A làm nhiệm vụ tiên quyết.
    3. Người dùng cố gắng đánh dấu hoàn thành Task B.
    4. Hệ thống kiểm tra trạng thái Task A.
    5. Nếu Task A đã hoàn thành (`completed`), hệ thống cho phép hoàn thành Task B.
*   **Luồng thay thế (4a):**
    *   Nếu Task A chưa hoàn thành, hệ thống chặn hành động và hiển thị thông báo "Nhiệm vụ A chưa hoàn thành, Task B đang bị khóa".

---

## NHÓM 3: QUẢN LÝ DỰ ÁN (PROJECT MANAGEMENT)

### UC04: Mời thành viên vào dự án (Invite Member)
*   **Tác nhân:** Chủ sở hữu dự án, Thành viên được mời, Firebase.
*   **Luồng cơ bản:**
    1. Chủ dự án vào phần cài đặt dự án.
    2. Nhập UID hoặc Email của người dùng muốn mời.
    3. Hệ thống gửi thông báo lời mời đến người dùng đó.
    4. Người dùng nhận thông báo và nhấn "Chấp nhận".
    5. Hệ thống cập nhật UID người dùng vào danh sách `memberIds` của Dự án trên Cloud.
    6. Dự án xuất hiện trên ứng dụng của thành viên mới sau khi đồng bộ.

---

## NHÓM 4: TRỢ LÝ THÔNG MINH AI (AI ASSISTANT)

### UC05: Gợi ý lộ trình AI (Request AI Roadmap)
*   **Tác nhân:** Người dùng, Hệ thống AI.
*   **Mô tả:** AI tự động chia nhỏ mục tiêu lớn thành các bước khả thi.
*   **Luồng cơ bản:**
    1. Người dùng nhập mục tiêu lớn (ví dụ: "Setup máy tính mới").
    2. Người dùng chọn số lượng bước đề xuất.
    3. Hệ thống gửi yêu cầu (Prompt) đến AI Service.
    4. AI trả về danh sách công việc con kèm thời lượng ước tính.
    5. Người dùng kiểm tra và nhấn "Áp dụng lộ trình".
    6. Hệ thống tự động tạo các Task trong danh sách vào DB.

---

## NHÓM 5: THỐNG KÊ & DỰ BÁO (ANALYTICS & PREDICTION)

### UC06: Xem báo cáo Reality Check (Procrastination Analysis)
*   **Tác nhân:** Người dùng, Hệ thống dự đoán.
*   **Luồng cơ bản:**
    1. Người dùng truy cập màn hình "Reality Check".
    2. Hệ thống thu thập dữ liệu lịch sử hoàn thành và trễ hạn.
    3. Hệ thống tính toán "Chỉ số lười biếng".
    4. Hệ thống xác định danh mục bị bỏ bê nhiều nhất.
    5. Hệ thống hiển thị biểu đồ và nhận xét từ AI Coach.

### UC07: Nhận cảnh báo khủng hoảng (Crisis Alert)
*   **Tác nhân:** Hệ thống Thông báo.
*   **Mô tả:** Tự động cảnh báo khi công việc sắp trễ hạn với xác suất cao.
*   **Luồng cơ bản:**
    1. Hệ thống định kỳ quét các công việc đang thực hiện.
    2. Tính toán xác suất trễ hạn dựa trên thời gian thực và tốc độ làm việc.
    3. Nếu xác suất > 70%, hệ thống đẩy thông báo "Cảnh báo khủng hoảng".
    4. Hiển thị thông tin công việc nguy cơ cao lên đầu màn hình Home.
