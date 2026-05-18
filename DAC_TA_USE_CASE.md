# ĐẶC TẢ CHI TIẾT USE CASE - TASKFLOW

Tài liệu này đặc tả chi tiết các luồng nghiệp vụ quan trọng nhất trong ứng dụng.

---

## 1. UC: Tạo Lộ Trình Công Việc Bằng AI (Request AI Roadmap)

*   **Tác nhân:** Người dùng, Hệ thống AI (OpenRouter).
*   **Tiền điều kiện:** Người dùng đã đăng nhập và có kết nối Internet.
*   **Hậu điều kiện:** Một nhiệm vụ chính và các nhiệm vụ con phụ thuộc được tạo ra trong hệ thống.

### Luồng sự kiện chính (Basic Flow):
1.  Người dùng truy cập màn hình "Trợ lý AI".
2.  Người dùng nhập mục tiêu lớn (ví dụ: "Học Flutter trong 30 ngày").
3.  Người dùng chọn quy mô (số bước con) và cấu hình dự án.
4.  Người dùng nhấn nút "Gợi ý lộ trình".
5.  Hệ thống gửi yêu cầu đến **AI Service**.
6.  AI phân tích và trả về danh sách các bước cụ thể (Tiêu đề, Thời lượng, Độ ưu tiên).
7.  Hệ thống hiển thị danh sách gợi ý để người dùng xem xét.
8.  Người dùng nhấn "Thêm lộ trình vào danh sách".
9.  Hệ thống tạo Task chính và chuỗi các Task con có gắn link `dependencyTaskId` (nếu chọn chế độ nối chuỗi).
10. Hệ thống gửi thông báo xác nhận thành công.

### Luồng thay thế (Alternative Flow):
*   **7a. Chỉnh sửa:** Người dùng có thể chỉnh sửa tiêu đề, thời lượng hoặc bỏ chọn một số bước trước khi lưu.

### Luồng ngoại lệ (Exception Flow):
*   **5a. Lỗi kết nối:** Nếu không có Internet hoặc API Key hết hạn, hệ thống hiển thị thông báo lỗi "Không thể kết nối với AI".
*   **6a. Phản hồi lỗi:** AI trả về dữ liệu không đúng định dạng, hệ thống yêu cầu người dùng thử lại.

---

## 2. UC: Theo Dõi Và Tự Động Chuyển Trạng Thái (Automated Progress Tracking)

*   **Tác nhân:** Hệ thống (System Timer).
*   **Tiền điều kiện:** Có các nhiệm vụ ở trạng thái `pending`.

### Luồng sự kiện chính (Basic Flow):
1.  Hệ thống chạy bộ quét (Scan Timer) mỗi 10 giây (qua `ProgressTrackingService`).
2.  Hệ thống kiểm tra thời gian hiện tại với `due_day` của các nhiệm vụ.
3.  Nếu thời gian hiện tại nằm trong khoảng `due_day` và `deadline`, hệ thống tự động chuyển trạng thái từ `pending` sang `in_progress`.
4.  Hệ thống cập nhật thuộc tính `updatedAt` và đánh dấu `isSynced = false`.
5.  Hệ thống phát thông báo đẩy (Push Notification) báo hiệu công việc bắt đầu.

### Luồng ngoại lệ (Exception Flow):
*   **2a. Chế độ ngủ (Sleep Mode):** Nếu thời gian hiện tại nằm trong khung giờ ngủ đã cấu hình, hệ thống tạm dừng việc chuyển trạng thái và đóng băng các thông báo để bảo vệ giấc ngủ.

---

## 3. UC: Quản Lý Nhiệm Vụ Phụ Thuộc (Dependency Management)

*   **Tác nhân:** Người dùng.
*   **Tiền điều kiện:** Đã có ít nhất một nhiệm vụ tiên quyết được thiết lập.

### Luồng sự kiện chính (Basic Flow):
1.  Người dùng cố gắng bắt đầu hoặc đánh dấu hoàn thành Task B (Nhiệm vụ bị khóa).
2.  Hệ thống kiểm tra thuộc tính `dependencyTaskId` của Task B.
3.  Hệ thống truy vấn trạng thái của Task A (Nhiệm vụ tiên quyết).
4.  Nếu Task A chưa ở trạng thái `completed`:
    *   Hệ thống hiển thị cảnh báo "Nhiệm vụ đang bị khóa".
    *   Hệ thống ngăn chặn việc thay đổi trạng thái của Task B.
5.  Nếu Task A đã hoàn thành:
    *   Hệ thống cho phép thực hiện Task B.
    *   Gửi thông báo "Nhiệm vụ đã được mở khóa".

---

## 4. UC: Xem Báo Cáo Reality Check (View Procrastination Report)

*   **Tác nhân:** Người dùng, Hệ thống Dự đoán (Prediction Service).
*   **Tiền điều kiện:** Người dùng đã có dữ liệu lịch sử công việc (trễ hạn hoặc hoàn thành).

### Luồng sự kiện chính (Basic Flow):
1.  Người dùng chọn chức năng "Reality Check" từ Home hoặc Analytics.
2.  Hệ thống thu thập dữ liệu từ `tasksBox` và `timeLogsBox`.
3.  Hệ thống tính toán **Chỉ số lười biếng (Laziness Quotient)** dựa trên: (70% tỷ lệ trễ hạn + 30% tỷ lệ tồn đọng).
4.  Hệ thống xác định nhóm công việc bị trì hoãn nhiều nhất.
5.  Hệ thống sinh câu nhận xét (Roast Message) tương ứng với cấp độ lười biếng.
6.  Hiển thị biểu đồ Gauge (đo mức độ) và danh sách các Task đang gây trễ hạn.

---

## 5. UC: Đồng Bộ Hóa Dữ Liệu (Data Synchronization)

*   **Tác nhân:** Người dùng, Firebase Firestore.
*   **Tiền điều kiện:** Người dùng đã đăng nhập.

### Luồng sự kiện chính (Basic Flow):
1.  Khi có thay đổi dữ liệu (Create/Update/Delete), hệ thống lưu vào **Hive (Local)** trước.
2.  Hệ thống gọi `SyncService.pushLocalToCloud()`.
3.  Hệ thống lọc các bản ghi có `isSynced == false`.
4.  Gửi dữ liệu lên Firestore.
5.  Nếu thành công, cập nhật bản ghi local thành `isSynced = true`.
6.  Định kỳ, hệ thống thực hiện `pullCloudToLocal()` để lấy các thay đổi từ thiết bị khác.

### Luồng ngoại lệ (Exception Flow):
*   **2a. Mất mạng:** Hệ thống giữ nguyên cờ `isSynced = false` và sẽ thực hiện lại khi có kết nối mạng ở lần khởi động sau.
