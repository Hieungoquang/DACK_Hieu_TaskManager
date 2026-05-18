# TÀI LIỆU ĐẶC TẢ USE CASE TOÀN DIỆN - TASKFLOW

Tài liệu này cung cấp chi tiết các luồng sự kiện cho toàn bộ các chức năng cốt lõi của hệ thống TaskFlow.

---

## 1. NHÓM QUẢN LÝ TÀI KHOẢN (ACCOUNT MANAGEMENT)

### UC-AC01: Đăng ký & Đăng nhập
*   **Mô tả:** Cho phép người dùng tạo tài khoản mới hoặc truy cập vào hệ thống.
*   **Tiền điều kiện:** Ứng dụng đã được cài đặt và có kết nối mạng.
*   **Luồng cơ bản (Login):**
    1. Người dùng nhập Email/Mật khẩu.
    2. Hệ thống xác thực qua Firebase Auth.
    3. Hệ thống kiểm tra dữ liệu local (Hive), nếu chưa có sẽ pull từ Cloud.
    4. Chuyển hướng người dùng vào màn hình Home.
*   **Luồng ngoại lệ:** Sai thông tin hoặc tài khoản chưa kích hoạt -> Hiển thị thông báo lỗi tương ứng.

### UC-AC02: Cập nhật Hồ sơ (Update Profile)
*   **Mô tả:** Thay đổi thông tin cá nhân và ảnh đại diện.
*   **Luồng cơ bản:**
    1. Người dùng vào màn hình Profile.
    2. Thay đổi Họ tên, Số điện thoại hoặc chọn ảnh từ thư viện (Image Picker).
    3. Nhấn "Lưu".
    4. Hệ thống cập nhật Firestore và đồng bộ lại Hive.

---

## 2. NHÓM QUẢN LÝ CÔNG VIỆC (TASK MANAGEMENT)

### UC-TM01: Tạo & Quản lý Nhiệm vụ (CRUD Task)
*   **Mô tả:** Quản lý vòng đời của một nhiệm vụ.
*   **Luồng cơ bản:**
    1. Người dùng tạo Task với Tiêu đề, Hạn chót, Độ ưu tiên.
    2. Hệ thống lưu vào local (Hive) với cờ `isSynced = false`.
    3. Hệ thống tính toán thời gian và đặt `Notification`.
    4. Task xuất hiện trên Home/Calendar.
*   **Luồng ngoại lệ:** Người dùng xóa Task -> Chuyển vào Thùng rác (isDeleted = true).

### UC-TM02: Quản lý Phụ thuộc (Task Dependency)
*   **Mô tả:** Ràng buộc thứ tự thực hiện giữa các Task.
*   **Luồng cơ bản:**
    1. Người dùng chọn Task B, thiết lập Task A làm tiên quyết.
    2. Hệ thống kiểm tra trạng thái Task A mỗi khi User tương tác với Task B.
    3. Nếu Task A hoàn thành -> Task B mở khóa.
*   **Luồng ngoại lệ:** Nếu Task A bị xóa hoặc bị hủy -> Task B trở lại trạng thái độc lập hoặc cảnh báo lỗi link.

### UC-TM03: Theo dõi thời gian (Time Tracking)
*   **Mô tả:** Sử dụng Timer để đo lường nỗ lực thực tế.
*   **Luồng cơ bản:**
    1. Người dùng nhấn "Start" trên một Task.
    2. Hệ thống chạy bộ đếm giờ (StreamProvider).
    3. Nhấn "Stop" -> Hệ thống tạo một bản ghi trong `timeLogsBox`.
    4. Cập nhật tiến độ (% progress) tự động nếu cấu hình.

---

## 3. NHÓM QUẢN LÝ DỰ ÁN (PROJECT MANAGEMENT)

### UC-PM01: Hợp tác Dự án (Project Collaboration)
*   **Mô tả:** Quản lý dự án chung giữa nhiều người dùng.
*   **Luồng cơ bản:**
    1. Người dùng tạo Dự án, thêm mô tả và màu sắc.
    2. Gửi lời mời (Invite) cho thành viên khác qua Email.
    3. Thành viên chấp nhận lời mời -> Hệ thống cập nhật `memberIds` trên Firestore.
    4. Mọi thay đổi Task trong Dự án sẽ được đồng bộ theo thời gian thực (Real-time) cho tất cả thành viên.

---

## 4. NHÓM TRỢ LÝ THÔNG MINH AI (AI ASSISTANT)

### UC-AI01: Chia nhỏ lộ trình AI (AI Roadmap Generation)
*   **Tác nhân:** User, AI Service (OpenRouter).
*   **Mô tả:** Chuyển đổi một ý tưởng thành danh sách Task cụ thể.
*   **Luồng cơ bản:**
    1. Người dùng nhập: "Học lập trình Flutter".
    2. AI phân tích và trả về cấu trúc: [Tên bước | Thời lượng | Độ ưu tiên | Mô tả].
    3. Người dùng chọn lọc các bước ưng ý.
    4. Nhấn "Apply" -> Hệ thống tự động tạo chuỗi Task nối tiếp nhau.

---

## 5. NHÓM THỐNG KÊ & DỰ BÁO (ANALYTICS & PREDICTION)

### UC-AN01: Reality Check & Roast AI
*   **Mô tả:** Phân tích sự trì hoãn và phản hồi thực tế.
*   **Luồng cơ bản:**
    1. Hệ thống tính: `Chỉ số lười = (0.7 * Tỷ lệ trễ) + (0.3 * Tỷ lệ tồn đọng)`.
    2. Xác định danh mục (Category) có hiệu suất kém nhất.
    3. AI Service chọn "giọng điệu" nhận xét phù hợp (Roast Message).
    4. Hiển thị báo cáo trực quan cho User.

### UC-AN02: Dự báo Khủng hoảng (Crisis Prediction)
*   **Mô tả:** Cảnh báo sớm rủi ro trễ hạn.
*   **Luồng cơ bản:**
    1. Background Service quét Task đang thực hiện.
    2. Tính xác suất trễ hạn dựa trên tốc độ làm việc thực tế và thời gian còn lại.
    3. Nếu `xác suất > 70%` -> Gửi thông báo khẩn cấp và đánh dấu đỏ trên giao diện.
