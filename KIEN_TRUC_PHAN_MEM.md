# CHI TIẾT KIẾN TRÚC PHẦN MỀM - TASKFLOW

Ứng dụng TaskFlow được xây dựng dựa trên kiến trúc phân lớp (Layered Architecture) kết hợp với mô hình quản lý trạng thái **Provider (MVVM pattern)**. Kiến trúc này giúp tách biệt rõ ràng giữa logic nghiệp vụ, dữ liệu và giao diện người dùng.

---

## 1. Sơ đồ kiến trúc tổng quát
Dữ liệu di chuyển theo luồng sau:
**UI (Screens/Widgets)** <-> **Provider (State Management)** <-> **Services** <-> **Data (Hive/Firebase)**

---

## 2. Chi tiết các lớp (Layers)

### 2.1. Lớp Dữ liệu (Model Layer) - `lib/models/`
Đây là lớp nền tảng, định nghĩa cấu trúc dữ liệu của toàn bộ hệ thống.
*   **Thực thi:** Sử dụng các class Dart đi kèm với `@HiveType` để lưu trữ cục bộ và các hàm convert JSON để làm việc với API/Firebase.
*   **Vai trò:** Đảm bảo tính nhất quán của dữ liệu (Task, Project, User, TimeLogs...) trên cả local và cloud.

### 2.2. Lớp Dịch vụ (Service Layer) - `lib/services/`
Chứa các logic nghiệp vụ "nặng" hoặc các kết nối với bên thứ ba.
*   **AI Service:** Xử lý giao tiếp với OpenRouter/GPT để nhận diện ý tưởng và chia nhỏ lộ trình.
*   **Sync Service:** Quản lý logic đồng bộ hóa phức tạp giữa SQLite/Hive (Local) và Firestore (Cloud).
*   **Prediction Service:** Chứa các thuật toán toán học để tính toán xác suất trễ hạn (Crisis) và phân tích năng suất (Reality Check).
*   **Notification Service:** Quản lý lịch trình thông báo ở tầng hệ thống (Android/iOS).

### 2.3. Lớp Quản lý Trạng thái (Provider Layer) - `lib/provider/`
Đóng vai trò như một **ViewModel** trong mô hình MVVM.
*   **Nhiệm vụ:**
    *   Giữ trạng thái hiện tại của ứng dụng (danh sách task đang hiển thị, project hiện tại...).
    *   Làm cầu nối: Khi UI gọi một hàm (ví dụ `addTask`), Provider sẽ gọi Service tương ứng để lưu dữ liệu, sau đó thông báo cho UI cập nhật (`notifyListeners()`).
    *   Xử lý logic phản ứng: Ví dụ, khi một Task hoàn thành, Provider tự động kiểm tra xem có Task nào khác được mở khóa hay không.

### 2.4. Lớp Giao diện (View Layer) - `lib/screens/` & `lib/widgets/`
Lớp hiển thị thông tin và nhận tương tác từ người dùng.
*   **Screens:** Các trang lớn (Home, Calendar, Analytics).
*   **Widgets:** Các thành phần tái sử dụng (TaskCard, Sidebar, CustomButton).
*   **Nguyên tắc:** UI không trực tiếp xử lý dữ liệu hay gọi API. Nó chỉ "lắng nghe" sự thay đổi từ Provider và hiển thị.

---

## 3. Chiến lược lưu trữ "Offline-First Sync"

Đây là điểm đặc biệt nhất trong kiến trúc của TaskFlow:

1.  **Ghi Local trước:** Mọi thao tác (tạo task, sửa dự án) đều được ghi vào **Hive** ngay lập tức. Điều này giúp ứng dụng có tốc độ phản hồi cực nhanh (0ms trễ).
2.  **Đánh dấu đồng bộ:** Các bản ghi mới được gán cờ `isSynced = false`.
3.  **Đẩy lên Cloud:** **SyncService** sẽ chạy ngầm hoặc chạy khi có mạng để đẩy các bản ghi có cờ `false` lên **Firebase Firestore**.
4.  **Hòa nhập dữ liệu:** Khi khởi động, ứng dụng sẽ "Pull" dữ liệu mới nhất từ Cloud về để cập nhật lại vào Local Hive.

---

## 4. Ưu điểm của kiến trúc này
*   **Khả năng bảo trì:** Khi muốn đổi từ GPT sang Gemini AI, bạn chỉ cần sửa duy nhất file `ai_service.dart`.
*   **Khả năng mở rộng:** Dễ dàng thêm các tính năng mới (ví dụ: Team Chat) bằng cách thêm Provider và Service mới mà không ảnh hưởng đến code cũ.
*   **Trải nghiệm người dùng:** Nhờ Offline-first, người dùng có thể dùng app ở bất cứ đâu, ngay cả khi vào hầm gửi xe hay mất mạng.
*   **Kiểm thử (Testing):** Các lớp được tách biệt giúp việc viết Unit Test cho các thuật toán trong `prediction_service.dart` trở nên dễ dàng.
