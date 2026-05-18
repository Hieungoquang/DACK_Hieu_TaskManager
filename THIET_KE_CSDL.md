# THIẾT KẾ CƠ SỞ DỮ LIỆU - TASKFLOW

Ứng dụng sử dụng kiến trúc cơ sở dữ liệu NoSQL với sự kết hợp giữa **Hive** (Lưu trữ cục bộ tốc độ cao) và **Firebase Firestore** (Đồng bộ hóa đám mây và cộng tác nhóm).

---

## 1. Danh sách các Thực thể (Entities/Collections)

### 1.1. Người dùng (User)
Lưu trữ thông tin định danh và cấu hình cá nhân.
*   `user_id` (String): ID duy nhất (UID từ Firebase Auth).
*   `username` (String): Tên hiển thị/đăng nhập.
*   `email` (String): Địa chỉ email liên hệ.
*   `full_name` (String): Họ và tên đầy đủ.
*   `phone_number` (String): Số điện thoại.
*   `avatar_url` (String): Đường dẫn ảnh đại diện.
*   `last_sync_at` (DateTime): Thời điểm cuối cùng đồng bộ với Cloud.
*   `created_at` / `updated_at` (DateTime).

### 1.2. Dự án (Project)
Quản lý các nhóm công việc chung hoặc dự án cộng tác.
*   `project_id` (String): ID định danh dự án.
*   `user_id` (String): Chủ sở hữu dự án.
*   `name` (String): Tên dự án.
*   `description` (String): Mô tả chi tiết mục tiêu dự án.
*   `colorValue` (int): Màu sắc đại diện (dạng mã màu Hex/ARGB).
*   `memberIds` (List<String>): Danh sách UID của các thành viên tham gia.
*   `memberStatuses` (Map<String, String>): Trạng thái của từng thành viên (ví dụ: `confirmed`, `invited`).
*   `startDate` / `endDate` (DateTime): Khoảng thời gian diễn ra dự án.
*   `isDeleted` (bool): Đánh dấu xóa logic (để đưa vào Thùng rác).

### 1.3. Công việc (Task)
Thành phần cốt lõi của ứng dụng.
*   `task_id` (String): ID định danh công việc.
*   `user_id` (String): Người tạo/sở hữu công việc.
*   `project_id` (String, optional): Liên kết với dự án (nếu có).
*   `title` (String): Tiêu đề ngắn gọn của công việc.
*   `description` (String): Mô tả chi tiết hành động.
*   `priority` (int): Độ ưu tiên (1: Thấp, 2: Vừa, 3: Cao).
*   `status` (String): Trạng thái (`pending`, `in_progress`, `completed`).
*   `progress` (int): Tiến độ hoàn thành (0 - 100).
*   `due_day` (DateTime): Thời điểm bắt đầu dự kiến.
*   `deadline` (DateTime): Hạn chót phải hoàn thành.
*   `duration` (int): Tổng thời gian thực hiện ước tính (phút).
*   `category` (String): Tên danh mục phân loại.
*   `dependencyTaskId` (String, optional): ID của nhiệm vụ tiên quyết (khóa).
*   `isSynced` (bool): Cờ đánh dấu đã đồng bộ lên Cloud hay chưa.
*   `isDeleted` (bool): Đánh dấu xóa logic.

### 1.4. Công việc con (Subtask)
*   `subtask_id` (String).
*   `task_id` (String): Liên kết với Task cha (Foreign Key).
*   `title` (String).
*   `is_completed` (bool).

### 1.5. Nhật ký thời gian (Time Logs)
Lưu trữ lịch sử sử dụng Timer để theo dõi hiệu suất thực tế.
*   `log_id` (String).
*   `task_id` (String): Liên kết với Task đang thực hiện.
*   `start_time` / `end_time` (DateTime).
*   `duration_minutes` (int): Số phút tập trung thực tế.
*   `notes` (String): Ghi chú cho phiên tập trung (mặc định: "Tập trung").

### 1.6. Thông báo (Notification)
*   `notification_id` (String).
*   `user_id` (String).
*   `task_id` (String, optional).
*   `title` / `message` (String).
*   `type` (String): Phân loại (`daily_summary`, `crisis_alert`, `ai_suggestion`...).
*   `isRead` (bool).

---

## 2. Quan hệ giữa các bảng (Relationships)

1.  **User - Project:** Một User có thể tạo nhiều Project (1-N). Một Project có thể có nhiều User tham gia (N-N qua `memberIds`).
2.  **Project - Task:** Một Project chứa nhiều Task (1-N). Khi xóa Project, tất cả Task bên trong sẽ bị xóa theo (Cascade Delete logic).
3.  **Task - Subtask:** Một Task có nhiều Subtask (1-N). Tiến độ của Task cha được tính toán dựa trên % Subtask hoàn thành.
4.  **Task - TimeLogs:** Một Task có thể có nhiều bản ghi nhật ký thời gian (1-N) từ các phiên làm việc khác nhau.
5.  **Task - Task (Self-Reference):** Thông qua `dependencyTaskId`, tạo ra mối quan hệ cha-con hoặc tuần tự (Nhiệm vụ A phải xong thì nhiệm vụ B mới mở khóa).

---

## 3. Cấu trúc lưu trữ Hive (Local Boxes)

Dữ liệu được chia thành các "Box" để tối ưu tốc độ truy xuất:
*   `tasksBox`: Lưu trữ toàn bộ object `Task`.
*   `projectsBox`: Lưu trữ object `Project`.
*   `timeLogsBox`: Lưu trữ lịch sử Timer.
*   `subtasksBox`: Lưu trữ các đầu việc nhỏ.
*   `notificationsBox`: Lưu trữ thông báo offline.
*   `settingsBox`: Lưu trữ cấu hình ứng dụng (Dark mode, Sleep mode settings).

---

## 4. Cấu trúc Firestore (Cloud Collections)

Firestore tổ chức dữ liệu theo phân cấp để hỗ trợ bảo mật (Rules):
*   `/users/{userId}`: Thông tin profile.
*   `/users/{userId}/tasks/{taskId}`: Công việc cá nhân (chỉ chủ sở hữu thấy).
*   `/projects/{projectId}`: Thông tin dự án chung.
*   `/projects/{projectId}/tasks/{taskId}`: Công việc dự án (tất cả thành viên thấy).
*   `/users/{userId}/notifications/{notifId}`: Thông báo đẩy từ hệ thống.
