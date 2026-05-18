# MÔ TẢ THIẾT KẾ SƠ ĐỒ LỚP (CLASS DIAGRAM) - TASKFLOW

Tài liệu này mô tả chi tiết các lớp thực thể (Entities), thuộc tính và mối quan hệ giữa chúng để phục vụ việc vẽ sơ đồ lớp.

---

## 1. Các Lớp Thực Thể (Models)

### 1.1. Lớp User
Lớp lưu trữ thông tin người dùng hệ thống.
*   **Thuộc tính:**
    *   `user_id` (String): Khóa chính.
    *   `username` (String): Tên định danh.
    *   `email` (String): Email đăng ký.
    *   `full_name` (String): Tên đầy đủ.
    *   `avatar_url` (String): Ảnh đại diện.
    *   `phone_number` (String): Số điện thoại.

### 1.2. Lớp Task (Nhiệm vụ)
Lớp quan trọng nhất, chứa logic của một công việc.
*   **Thuộc tính:**
    *   `task_id` (String): Khóa chính.
    *   `user_id` (String): Khóa ngoại (User).
    *   `project_id` (String): Khóa ngoại (Project) - có thể null.
    *   `title` (String): Tiêu đề.
    *   `status` (String): Trạng thái (pending, in_progress, completed).
    *   `priority` (int): Độ ưu tiên (1-3).
    *   `progress` (int): Tiến độ (0-100).
    *   `due_day` (DateTime): Ngày bắt đầu.
    *   `deadline` (DateTime): Hạn chót.
    *   `dependencyTaskId` (String): Khóa ngoại (Self-reference) - Task tiên quyết.

### 1.3. Lớp Project (Dự án)
Lớp quản lý nhóm công việc chung.
*   **Thuộc tính:**
    *   `project_id` (String): Khóa chính.
    *   `user_id` (String): Khóa ngoại (Chủ sở hữu).
    *   `name` (String): Tên dự án.
    *   `memberIds` (List<String>): Danh sách ID thành viên tham gia.
    *   `colorValue` (int): Màu đại diện.

### 1.4. Lớp Subtask (Nhiệm vụ con)
*   **Thuộc tính:**
    *   `subtask_id` (String): Khóa chính.
    *   `task_id` (String): Khóa ngoại (Task cha).
    *   `title` (String).
    *   `is_completed` (bool).

### 1.5. Lớp Time_logs (Nhật ký thời gian)
*   **Thuộc tính:**
    *   `log_id` (String).
    *   `task_id` (String): Khóa ngoại (Task).
    *   `duration_minutes` (int): Số phút tập trung.

---

## 2. Mối Quan Hệ (Relationships)

| Cặp Lớp | Loại Quan Hệ | Mô tả |
| :--- | :--- | :--- |
| **User - Project** | 1 - n | Một người dùng có thể tạo nhiều dự án. |
| **User - Project** | n - n | Một người dùng có thể là thành viên của nhiều dự án (`memberIds`). |
| **User - Task** | 1 - n | Một người dùng sở hữu nhiều nhiệm vụ cá nhân. |
| **Project - Task** | 1 - n | Một dự án chứa nhiều nhiệm vụ. (Quan hệ Aggregation). |
| **Task - Subtask** | 1 - n | Một nhiệm vụ lớn chia thành nhiều đầu việc nhỏ. (Quan hệ Composition). |
| **Task - Time_logs** | 1 - n | Một nhiệm vụ có thể có nhiều phiên làm việc/bấm giờ. |
| **Task - Task** | 0..1 - 0..1 | Quan hệ tự thân (Self-reference) qua `dependencyTaskId`. |

---

## 3. Gợi ý hướng dẫn vẽ sơ đồ
1.  **Sử dụng Hình chữ nhật 3 phần:** Phần đầu ghi tên lớp, phần giữa ghi danh sách thuộc tính (kèm kiểu dữ liệu), phần cuối ghi các phương thức (ví dụ: `save()`, `delete()`, `toggleStatus()`).
2.  **Ký hiệu quan hệ:**
    *   Dùng hình thoi rỗng cho Project -> Task (Nhiệm vụ thuộc về dự án).
    *   Dùng hình thoi đặc cho Task -> Subtask (Nhiệm vụ con phụ thuộc hoàn toàn vào nhiệm vụ cha).
    *   Dùng đường kẻ có mũi tên cho các quan hệ Khóa ngoại (User_id, Project_id).
    *   Dùng đường kẻ vòng ngược lại chính nó cho `dependencyTaskId` trong lớp Task.
