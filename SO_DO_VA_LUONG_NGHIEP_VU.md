# DANH SÁCH CÁC CHỨC NĂNG CẦN VẼ SƠ ĐỒ (USE CASE & FLOW)

Tài liệu này tổng hợp các nghiệp vụ quan trọng trong ứng dụng TaskFlow để bạn có thể thực hiện vẽ sơ đồ Use Case và sơ đồ Luồng (Activity/Sequence Diagram).

## 1. Các Tác nhân (Actors)
*   **Người dùng (User):** Tác nhân chính thực hiện hầu hết các chức năng.
*   **Hệ thống AI (AI Service):** Tác nhân hỗ trợ phân tích mục tiêu và đưa ra nhận xét.
*   **Hệ thống Firebase:** Tác nhân hỗ trợ xác thực và lưu trữ đám mây.
*   **Hệ thống Thông báo (Notification System):** Tác nhân hỗ trợ gửi nhắc nhở.

---

## 2. Phân tích chi tiết Sơ đồ Use Case
Bạn nên chia sơ đồ thành các khối hệ thống (System Boundary) để dễ theo dõi.

### 2.1. Nhóm Quản lý Tài khoản (Account Management)
*   **UC Đăng ký (Register):** Tạo tài khoản mới.
*   **UC Đăng nhập (Login):** Truy cập hệ thống.
*   **UC Quên mật khẩu (Forgot Password):** Nhận email khôi phục.
*   **UC Cập nhật hồ sơ (Update Profile):** Thay đổi thông tin cá nhân (Avatar, tên...).
*   **UC Đổi mật khẩu (Change Password):** Thay đổi bảo mật khi đã đăng nhập.

### 2.2. Nhóm Quản lý Công việc (Task Management)
*   **UC Tạo nhiệm vụ (Create Task):** Nhập tên, hạn chót, độ ưu tiên.
    *   *Extend:* **UC Đặt lời nhắc (Set Reminder)**.
    *   *Extend:* **UC Thiết lập phụ thuộc (Set Dependency)** - chọn Task tiên quyết.
*   **UC Quản lý Checklist (Manage Subtasks):** Thêm/Sửa/Xóa các đầu việc con.
*   **UC Theo dõi thời gian (Track Time):** Bật Timer để ghi lại thời gian làm việc thực tế.
*   **UC Cập nhật tiến độ (Update Progress):** Đánh dấu % hoàn thành hoặc kéo thả trạng thái.
*   **UC Quản lý Thùng rác (Manage Trash):** Khôi phục hoặc xóa vĩnh viễn Task.

### 2.3. Nhóm Quản lý Dự án (Project Management)
*   **UC Tạo dự án (Create Project):** Thiết lập không gian làm việc nhóm.
*   **UC Mời thành viên (Invite Member):** Thêm người khác qua Email/UID.
*   **UC Theo dõi tiến độ dự án (View Project Board):** Xem tổng quan các Task thuộc dự án.
*   **UC Quản lý thành viên (Manage Members):** Chấp nhận lời mời hoặc xóa thành viên.

### 2.4. Nhóm Trợ lý thông minh AI (AI Smart Assistant)
*   **UC Yêu cầu lộ trình AI (Request AI Roadmap):** Nhập mục tiêu lớn để AI chia nhỏ việc.
    *   *Include:* **UC Phân tích mục tiêu (AI Analyze)**.
*   **UC Chấp nhận lộ trình (Apply Roadmap):** Tự động tạo hàng loạt Task từ đề xuất của AI.
*   **UC Xem gợi ý giờ vàng (View Golden Hours):** Xem khung giờ làm việc hiệu quả nhất do AI phân tích.

### 2.5. Nhóm Thống kê & Dự báo (Analytics & Prediction)
*   **UC Xem Dashboard hiệu suất (View Performance Dashboard):** Xem biểu đồ năng suất 7 ngày.
*   **UC Xem báo cáo Reality Check (View Procrastination Report):** Xem chỉ số lười biếng và nhận xét từ AI Coach.
*   **UC Nhận cảnh báo khủng hoảng (Receive Crisis Alert):** Hệ thống tự động đẩy thông báo khi nguy cơ trễ hạn cao.

---

## 3. Danh sách các Luồng Nghiệp vụ cần vẽ (Flowchart/Activity Diagram)

### 3.1. Luồng Xác thực & Đồng bộ (Auth & Sync Flow)
*   **Mục tiêu:** Mô tả cách dữ liệu được tải từ Local (Hive) và đồng bộ với Cloud (Firebase) sau khi đăng nhập.
*   **Các bước chính:** Đăng nhập -> Kiểm tra kết nối -> Pull dữ liệu từ Firestore -> Lưu vào Hive -> Hiển thị màn hình Home.

### 3.2. Luồng Trợ lý AI lập kế hoạch (AI Planning Flow)
*   **Mục tiêu:** Quy trình từ khi người dùng nhập ý tưởng đến khi có lộ trình hoàn chỉnh.
*   **Các bước chính:** Nhập mục tiêu -> Gửi request tới OpenRouter -> Nhận danh sách bước đề xuất -> Người dùng chỉnh sửa/chọn bước -> Lưu vào hệ thống (tự động gắn link Dependency).

### 3.3. Luồng Kiểm tra Khủng hoảng Deadline (Crisis Prediction Flow)
*   **Mục tiêu:** Cách hệ thống tính toán và đưa ra cảnh báo.
*   **Các bước chính:** Quét danh sách Task -> Lấy lịch sử Delay Rate -> Tính xác suất dựa trên thời gian còn lại & tiến độ -> Nếu > 70% -> Đẩy thông báo & Hiển thị cảnh báo đỏ trên Home.

### 3.4. Luồng Chế độ Đóng băng Giờ ngủ (Sleep Mode Flow)
*   **Mục tiêu:** Cách hệ thống xử lý thông báo trong đêm.
*   **Các bước chính:** Đến giờ quét -> Kiểm tra cấu hình Sleep Mode -> Nếu trong khung giờ ngủ -> Hủy/Tắt tiếng các thông báo sắp tới -> Tăng biến đếm "Silenced Alarms" -> Không cập nhật trạng thái trễ hạn.

### 3.5. Luồng Quản lý Nhiệm vụ phụ thuộc (Task Dependency Flow)
*   **Mục tiêu:** Đảm bảo công việc được làm theo trình tự.
*   **Các bước chính:** Task B phụ thuộc Task A -> Người dùng cố gắng bắt đầu Task B -> Hệ thống kiểm tra Task A -> Nếu Task A chưa xong -> Hiển thị thông báo "Bị khóa" -> Nếu Task A hoàn thành -> Thông báo "Mở khóa" Task B.

### 3.6. Luồng Reality Check & Roast AI (Analysis Flow)
*   **Mục tiêu:** Phân tích mức độ trì hoãn.
*   **Các bước chính:** Thu thập dữ liệu (Task trễ, Task tồn đọng) -> Tính Chỉ số lười biếng -> AI Service chọn mẫu câu "Roast" phù hợp -> Hiển thị báo cáo trực quan cho người dùng.

---

## 4. Gợi ý công cụ vẽ
*   **Draw.io (Diagrams.net):** Phổ biến, miễn phí, tích hợp Google Drive.
*   **Lucidchart:** Chuyên nghiệp, nhiều template mẫu.
*   **Mermaid.js:** Nếu bạn muốn viết code để tự động render sơ đồ trong file Markdown.
*   **Figma/FigJam:** Phù hợp nếu bạn muốn vẽ sơ đồ kết hợp với thiết kế UI.
