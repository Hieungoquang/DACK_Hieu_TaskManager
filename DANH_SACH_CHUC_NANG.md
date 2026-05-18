# TỔNG HỢP CÁC CHỨC NĂNG ỨNG DỤNG TASKFLOW

Ứng dụng TaskFlow là một hệ thống quản lý công việc thông minh tích hợp trí tuệ nhân tạo (AI), tập trung vào việc tối ưu hóa hiệu suất cá nhân và quản lý dự án nhóm.

## 1. Quản lý Công việc & Dự án (Core Management)
*   **Quản lý Dự án (Project Management):**
    *   Tạo, chỉnh sửa và xóa dự án với màu sắc và mô tả riêng biệt.
    *   Theo dõi tiến độ tổng thể của dự án dựa trên các nhiệm vụ thành phần.
    *   Quản lý thành viên trong dự án (mời thành viên, xác nhận tham gia).
*   **Quản lý Nhiệm vụ (Task Management):**
    *   Thêm mới nhiệm vụ với đầy đủ thông tin: Tiêu đề, mô tả, ngày bắt đầu, hạn chót (deadline), độ ưu tiên (1-3) và danh mục.
    *   Hệ thống Checklist (Subtasks): Chia nhỏ nhiệm vụ lớn thành các bước nhỏ hơn để dễ dàng kiểm soát.
    *   Hệ thống Phụ thuộc (Task Dependency): Thiết lập các nhiệm vụ "khóa", chỉ có thể bắt đầu khi nhiệm vụ tiên quyết đã hoàn thành.
    *   Thùng rác (Trash): Cho phép khôi phục hoặc xóa vĩnh viễn các nhiệm vụ/dự án đã xóa.
*   **Phân loại & Lọc (Filtering):**
    *   Quản lý danh mục cá nhân (Categories) với màu sắc tùy chỉnh.
    *   Tìm kiếm nhiệm vụ theo từ khóa và lọc nhanh theo độ ưu tiên (Cao/Vừa/Thấp).

## 2. Trợ lý Kế hoạch AI (AI Features)
*   **AI Planning Assistant (Lập kế hoạch tự động):**
    *   Phân tích mục tiêu lớn và tự động chia nhỏ thành lộ trình hành động cụ thể (3, 5, 8 hoặc 10 bước).
    *   Ước tính thời gian thực hiện (duration) và gán độ ưu tiên cho từng bước bằng AI.
    *   Tự động thiết lập chuỗi liên kết tuần tự (Task 1 -> Task 2 -> Task 3) cho lộ trình vừa tạo.
*   **AI Productivity Insights:**
    *   Phân tích hành vi hoàn thành công việc để tìm ra "Giờ Vàng" (Golden Hours) - khung giờ người dùng tập trung nhất.

## 3. Dự đoán & Cảnh báo Rủi ro (Analytics & Prediction)
*   **Dự báo Khủng hoảng (Crisis Probability):**
    *   Tính toán xác suất một công việc sẽ bị trễ hạn dựa trên tiến độ hiện tại, thời gian còn lại và thói quen làm việc trong quá khứ.
    *   Phát cảnh báo đỏ ngay trên màn hình chính khi nguy cơ trễ hạn vượt ngưỡng 70%.
*   **Báo cáo Reality Check (Procrastination Report):**
    *   Tính toán "Chỉ số lười biếng" (Laziness Quotient) dựa trên tỷ lệ trễ hạn và tồn đọng công việc.
    *   Phân tích nhóm công việc nào đang bị trì hoãn nhiều nhất.
    *   AI Coach: Đưa ra các phản hồi châm biếm hài hước hoặc nhắc nhở nghiêm túc (Roast messages) để thúc đẩy động lực người dùng.
*   **Dashboard Thống kê (Performance Analytics):**
    *   Biểu đồ Pie Chart: Xu hướng phân bổ thời gian thực tế theo từng danh mục công việc.
    *   Biểu đồ Bar Chart: Năng suất làm việc (số việc hoàn thành) trong 7 ngày gần nhất.
    *   Thống kê thời gian tập trung tích lũy (Time Logs).

## 4. Theo dõi Thời gian & Tự động hóa (Automation)
*   **Hệ thống Timer (Focus Tracking):**
    *   Theo dõi thời gian thực hiện nhiệm vụ theo thời gian thực.
    *   Tự động lưu nhật ký thời gian (Time Logs) khi dừng Timer.
*   **Tự động cập nhật trạng thái:**
    *   Hệ thống tự động quét và chuyển trạng thái nhiệm vụ từ "Đang chờ" (Pending) sang "Đang làm" (In Progress) khi đến giờ bắt đầu.
*   **Chế độ Đóng băng Giờ ngủ (Sleep Mode Freeze):**
    *   Tự động tắt tất cả thông báo nhắc nhở trong khung giờ ngủ do người dùng thiết lập.
    *   Ngừng quét lỗi trễ hạn trong đêm để bảo vệ sức khỏe và giấc ngủ người dùng.

## 5. Lịch & Điều hướng (Calendar & UI)
*   **Lịch thông minh (Calendar View):**
    *   Hiển thị công việc theo Ngày, Tuần, Tháng.
    *   Thao tác Kéo - Thả (Drag & Drop) để thay đổi thời gian thực hiện nhiệm vụ.
    *   Thay đổi kích thước nhiệm vụ trực tiếp trên lịch để điều chỉnh thời lượng (Resize).
    *   Hệ thống lọc theo dự án và danh mục ngay trên giao diện lịch.
*   **Giao diện Đa nền tảng:**
    *   Tối ưu hóa giao diện cho cả Mobile (Bottom Nav) và Web (Sidebar).
    *   Hỗ trợ Chế độ Sáng/Tối (Dark Mode) chuẩn GitHub Style.

## 6. Đồng bộ & Bảo mật (Sync & Auth)
*   **Đồng bộ hóa (Cloud Sync):**
    *   Sử dụng Firebase Firestore để đồng bộ dữ liệu giữa nhiều thiết bị.
    *   Cơ chế Offline-first: Lưu trữ dữ liệu local bằng Hive, đảm bảo ứng dụng vẫn hoạt động khi không có internet và tự động đẩy dữ liệu lên Cloud khi có mạng.
*   **Xác thực người dùng:**
    *   Đăng ký, Đăng nhập (Email/Password & Google).
    *   Quên mật khẩu: Gửi email khôi phục và đặt lại mật khẩu bằng mã xác thực oobCode.

## 7. Thông báo (Notifications)
*   **Thông báo đẩy (Push Notifications):**
    *   Nhắc nhở trước khi hết hạn (30 phút và 5 phút).
    *   Thông báo khi có nhiệm vụ mới được mở khóa (Dependencies).
    *   Tổng kết năng suất hàng ngày vào 20:00 mỗi tối.
    *   Thông báo khi được mời vào dự án nhóm.
