# THỐNG KÊ HIỆU SUẤT — Mô tả, Hướng dẫn sử dụng & Kịch bản kiểm thử

> Tài liệu tính năng **Thống kê hiệu suất** (Analytics Dashboard) trong ứng dụng TaskFlow.
> File nguồn: `lib/screens/analytics_dashboard_screen.dart`

---

## 1. Mô tả tính năng

**Thống kê hiệu suất** là bảng điều khiển (dashboard) phân tích sâu xu hướng phân bổ thời gian và năng suất hoạt động của người dùng. Tính năng tổng hợp dữ liệu từ:

- **Tasks** (`tasks`) — danh sách công việc đã/đang/sẽ làm.
- **Time logs** (`timeLogsBox` — Hive Box `Time_logs`) — các phiên làm việc thực tế.
- **AppProvider** — số lần cảnh báo bị tự động im lặng trong giờ ngủ.

### 1.1. Các thành phần hiển thị

| # | Thành phần | Nguồn dữ liệu | Ý nghĩa |
|---|---|---|---|
| 1 | **TẬP TRUNG TÍCH LŨY** (giờ) | `Σ duration_minutes` từ `timeLogsBox` | Tổng số giờ thực tế đã tập trung làm việc |
| 2 | **TỶ LỆ HOÀN THÀNH** (%) | `completed / total` (loại bỏ `isDeleted`) | Phần trăm công việc đã đạt 100% tiến độ |
| 3 | **BẢO VỆ GIẤC NGỦ** (lần) | `AppProvider.silencedAlarmsCount` | Số lần thông báo bị đóng băng vì rơi vào giờ ngủ |
| 4 | **PHÂN BỔ THỜI GIAN** (Pie Chart) | Tổng phút làm việc theo `category` | Cho biết bạn dành nhiều thời gian cho nhóm việc nào nhất |
| 5 | **NĂNG SUẤT 7 NGÀY** (Bar Chart) | Số task `completed` mỗi ngày trong 7 ngày qua | Xu hướng hoàn thành công việc gần đây |
| 6 | **AN TOÀN GIẤC NGỦ** | Cấu hình `sleepStart`/`sleepEnd` từ `AppProvider` | Trạng thái và khung giờ chế độ ngủ |
| 7 | **NHẬT KÝ PHIÊN LÀM VIỆC** | Danh sách `Time_logs` đã sắp xếp theo `created_at` giảm dần | Lịch sử các phiên focus gần nhất |

### 1.2. Đường vào tính năng

- **Web (≥ 900 px):** sidebar trái → mục **PHÂN TÍCH** (icon `analytics_outlined`, màu tím).
- **Mobile / màn hình nhỏ:** thanh điều hướng dưới cùng → tab **Phân tích**.
- Route nội bộ: `analytics` (tham khảo `WebSidebar` và `MobileBottomNav`).

---

## 2. Hướng dẫn sử dụng

### 2.1. Mở màn hình

1. Đăng nhập vào ứng dụng.
2. Trên web: bấm **PHÂN TÍCH** ở sidebar trái.
   Trên mobile: bấm icon **Phân tích** ở bottom nav.
3. Màn hình tự động cuộn được, hiển thị các block theo thứ tự ở mục 1.1.

### 2.2. Đọc các chỉ số tóm tắt

- **Tập trung tích lũy:** giá trị càng cao càng tốt — phản ánh thời gian thực sự ngồi làm.
- **Tỷ lệ hoàn thành:** mục tiêu lý tưởng `≥ 70%`. Nếu thấp → có thể đang ôm quá nhiều việc hoặc trì hoãn.
- **Bảo vệ giấc ngủ:** đếm số lần app tự tắt thông báo trong khung giờ ngủ. Số > 0 cho thấy chế độ ngủ đang hoạt động.

### 2.3. Đọc biểu đồ phân bổ thời gian (Pie)

- Mỗi lát cắt = 1 nhãn (`category`) của task gắn với time-log.
- Time-log không tìm thấy task tương ứng sẽ rơi vào nhóm **"Khác"**.
- Hover/Tap vào lát để xem số phút.

### 2.4. Đọc biểu đồ năng suất 7 ngày (Bar)

- Trục X: **dd/MM** của 7 ngày gần nhất (hôm nay ở bên phải).
- Trục Y: số task được đánh `status = 'completed'` trong ngày đó (dựa vào `updatedAt` hoặc `createdAt`).
- Cột cao = ngày làm việc hiệu quả.

### 2.5. Nhật ký phiên làm việc

- Hiển thị các bản ghi `Time_logs` sắp xếp mới nhất ở trên.
- Mỗi dòng: tiêu đề task + thời lượng (phút) + thời điểm `created_at`.

---

## 3. Kịch bản kiểm thử (Test Cases)

### TC-01 — Hiển thị mặc định khi chưa có dữ liệu

**Tiền điều kiện:** tài khoản mới, chưa có task và chưa có time-log nào.

**Các bước:**
1. Đăng nhập.
2. Vào **PHÂN TÍCH**.

**Kết quả mong đợi:**
- Tập trung tích lũy: `0.0 giờ`.
- Tỷ lệ hoàn thành: `0%`.
- Bảo vệ giấc ngủ: `0 lần`.
- Pie chart hiển thị empty-state hoặc 1 lát "Khác" = 0.
- Bar chart 7 ngày: tất cả cột bằng 0.
- Nhật ký phiên: trống (không lỗi).

### TC-02 — Tính tổng giờ tập trung

**Tiền điều kiện:** đã có 3 time-log với `duration_minutes` lần lượt: 30, 45, 75 phút.

**Bước:** Mở **PHÂN TÍCH**.

**Kết quả:** Card "TẬP TRUNG TÍCH LŨY" hiển thị `(30+45+75)/60 = 2.5 giờ` (làm tròn 1 chữ số).

### TC-03 — Tỷ lệ hoàn thành

**Tiền điều kiện:** 10 task, trong đó 4 task `status = 'completed'`, 0 task `isDeleted`.

**Kết quả:** Card "TỶ LỆ HOÀN THÀNH" hiển thị `40%`.

### TC-04 — Loại bỏ task đã xóa khỏi mẫu số

**Tiền điều kiện:** 10 task, 2 task `isDeleted = true`, 4 task `completed`.

**Kết quả:** Tỷ lệ = `4 / 8 = 50%`.

### TC-05 — Phân bổ thời gian theo category

**Tiền điều kiện:**
- Task A (category = "Công việc") có 2 logs: 30 + 60 phút.
- Task B (category = "Cá nhân") có 1 log: 45 phút.
- 1 log mồ côi (task không tồn tại): 20 phút.

**Kết quả Pie chart:**
- "Công việc" = 90 phút.
- "Cá nhân" = 45 phút.
- "Khác" = 20 phút.

### TC-06 — Năng suất 7 ngày

**Tiền điều kiện:** Hôm nay là `T`. Có 2 task hoàn thành ngày `T-2`, 1 task ngày `T`.

**Kết quả Bar chart:** cột `T-2` = 2; cột `T` = 1; các cột còn lại = 0; nhãn trục X đúng định dạng `dd/MM` cho 7 ngày `T-6 → T`.

### TC-07 — Bảo vệ giấc ngủ

**Tiền điều kiện:** `AppProvider.silencedAlarmsCount = 5`.

**Kết quả:** Card "BẢO VỆ GIẤC NGỦ" hiển thị `5 lần`.

### TC-08 — Nhật ký phiên sắp xếp đúng

**Tiền điều kiện:** 3 logs với `created_at`: hôm qua 9:00, hôm nay 8:00, hôm nay 14:00.

**Kết quả:** Thứ tự hiển thị từ trên xuống: hôm nay 14:00 → hôm nay 8:00 → hôm qua 9:00.

### TC-09 — Bền vững với dữ liệu lỗi

**Tiền điều kiện:** Trong `timeLogsBox` có 1 log với `duration_minutes = null` và 1 log có `created_at = null`.

**Kết quả:**
- App **không crash**.
- Log null `duration` được tính như 0 phút (không cộng vào tổng).
- Log null `created_at` vẫn được sắp xếp (dùng `DateTime.now()` làm fallback).

### TC-10 — Responsive layout

**Bước:**
1. Mở web > 900 px → 2 biểu đồ (Pie + Bar) **xếp ngang**, có sidebar.
2. Thu nhỏ cửa sổ < 900 px hoặc mở mobile → biểu đồ **xếp dọc**, hiện bottom nav.

**Kết quả:** Layout chuyển mượt, không tràn pixel.

### TC-11 — Dark mode

**Bước:** Bật chế độ tối ở Cài đặt → vào lại Phân tích.

**Kết quả:** Toàn bộ card nền `#161B22`, viền `#30363D`, chữ `#C9D1D9`. Biểu đồ vẫn đọc rõ.

### TC-12 — Điều hướng quay lại

**Trên mobile:** bấm nút back ở header → quay về màn hình trước (Home).

---

## 4. Ghi chú kỹ thuật cho dev

- Dữ liệu được tính lại **mỗi lần `build`** (không cache). Với data lớn (>10k logs) cần xem xét memoize.
- `Hive.box<Time_logs>('timeLogsBox')` phải được mở trước (đảm bảo trong `main.dart`).
- Sử dụng `fl_chart` cho Pie & Bar.
- Mọi cast `as int` đối với `duration_minutes` đã được wrap try-safe (xem `(mins is int) ? mins : 0`).
- Khi thêm field mới vào `Time_logs`, nhớ chạy lại Hive code-gen.

---

## 5. Câu hỏi thường gặp (FAQ)

**Q: Tại sao tổng giờ tập trung không khớp với cảm nhận?**
A: Chỉ tính từ những phiên đã được lưu vào `timeLogsBox` (ví dụ qua nút **Xác nhận kết quả** ở `ActiveTaskTrackerWidget`). Việc làm không bấm xác nhận sẽ không vào thống kê.

**Q: Vì sao có nhãn "Khác" trên Pie?**
A: Time-log có `task_id` nhưng task đã bị xóa cứng / không tìm thấy → fallback "Khác".

**Q: Năng suất luôn 0?**
A: Kiểm tra: (1) đã có task `status = 'completed'`; (2) `updatedAt` rơi trong vòng 7 ngày qua.

---

*Tài liệu cập nhật cùng phiên bản code hiện tại; nếu sửa logic trong `analytics_dashboard_screen.dart`, cập nhật lại file này.*
