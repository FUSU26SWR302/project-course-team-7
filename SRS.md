# SRS – Software Requirements Specification
## Hệ thống Hỗ trợ Đặt lịch Khám bệnh Trực tuyến

| Thông tin | Chi tiết |
|-----------|---------|
| **Tên dự án** | Healthcare Appointment Booking System |
| **Nhóm** | Nhóm 1 – SWP391 |
| **Phiên bản** | v1.0 |
| **Ngày tạo** | Tháng 5, 2025 |
| **Trạng thái** | Draft |

---

## 1. Giới thiệu

### 1.1 Mục đích tài liệu
Tài liệu này mô tả đầy đủ các yêu cầu chức năng và phi chức năng của hệ thống đặt lịch khám bệnh trực tuyến. Đây là cơ sở để nhóm phát triển, giáo viên hướng dẫn và các bên liên quan thống nhất phạm vi và tiêu chí hoàn thành của sản phẩm.

### 1.2 Phạm vi hệ thống
Hệ thống bao gồm ứng dụng web hỗ trợ bệnh nhân đặt lịch khám, bác sĩ quản lý lịch hẹn và admin quản lý toàn bộ nền tảng. Hệ thống chạy trên trình duyệt web và thiết bị di động.

### 1.3 Định nghĩa và từ viết tắt

| Từ viết tắt | Giải thích |
|-------------|-----------|
| SRS | Software Requirements Specification |
| UC | Use Case |
| FR | Functional Requirement |
| NFR | Non-Functional Requirement |
| JWT | JSON Web Token |
| OCR | Optical Character Recognition |
| API | Application Programming Interface |

---

## 2. Mô tả tổng quan hệ thống

### 2.1 Kiến trúc hệ thống

```
[Browser / Mobile]
       |
   [ReactJS Frontend]
       |  REST API + WebSocket
   [Node.js + Express Backend]
       |              |
  [MongoDB Atlas]  [External APIs]
                   (Google Maps, Agora, Nodemailer)
```

### 2.2 Các Actor (Người dùng hệ thống)

| Actor | Mô tả |
|-------|-------|
| **Bệnh nhân (Patient)** | Người dùng cuối, đặt lịch khám và sử dụng dịch vụ |
| **Bác sĩ (Doctor)** | Thiết lập lịch, xác nhận và quản lý ca khám |
| **Hộ lý (Nurse)** | Nhận lệnh chăm sóc tại nhà |
| **Admin** | Quản lý toàn bộ hệ thống, phê duyệt tài khoản |
| **Hệ thống Email** | Actor ngoài, nhận lệnh gửi thông báo tự động |

---

## 3. Yêu cầu chức năng (Functional Requirements)

### 3.1 Module Quản lý Người dùng

| ID | Tên chức năng | Mô tả | Ưu tiên |
|----|--------------|-------|---------|
| FR-01 | Đăng ký tài khoản | Bệnh nhân đăng ký bằng email + mật khẩu | Cao |
| FR-02 | Đăng nhập | Xác thực JWT, nhớ phiên đăng nhập | Cao |
| FR-03 | Khảo sát sức khỏe | Thu thập tuổi, bệnh nền, dị ứng khi đăng nhập lần đầu | Cao |
| FR-04 | Hồ sơ sức khỏe | Xem và cập nhật thông tin cá nhân | Cao |
| FR-05 | Quản lý người thân | Thêm/sửa/xóa hồ sơ người thân để đặt lịch hộ | Trung bình |
| FR-06 | Đổi mật khẩu | Đổi mật khẩu qua email OTP | Trung bình |

### 3.2 Module Đặt lịch Khám

| ID | Tên chức năng | Mô tả | Ưu tiên |
|----|--------------|-------|---------|
| FR-10 | Tìm kiếm bác sĩ | Lọc theo chuyên khoa, tên, bệnh viện, vị trí GPS | Cao |
| FR-11 | Xem thông tin bác sĩ | Xem profile, chuyên khoa, rating, lịch trống | Cao |
| FR-12 | Đặt lịch khám | Chọn bác sĩ → ngày → khung giờ → xác nhận | Cao |
| FR-13 | Xác nhận lịch | Gửi email xác nhận tự động đến bệnh nhân | Cao |
| FR-14 | Hủy lịch hẹn | Bệnh nhân hủy trước 24h | Cao |
| FR-15 | Đổi lịch hẹn | Chọn ngày/giờ mới thay thế | Trung bình |
| FR-16 | Nhắc lịch tự động | Gửi email nhắc trước 24h và 1h trước khám | Cao |
| FR-17 | Lịch sử khám | Xem các ca khám đã qua và trạng thái | Trung bình |

### 3.3 Module Dashboard

| ID | Tên chức năng | Mô tả | Ưu tiên |
|----|--------------|-------|---------|
| FR-20 | Dashboard Bác sĩ | Xem danh sách bệnh nhân hôm nay | Cao |
| FR-21 | Thiết lập lịch làm việc | Bác sĩ chọn ngày và khung giờ hoạt động | Cao |
| FR-22 | Dashboard Admin | Thống kê tổng quan (số lịch, bác sĩ, bệnh nhân) | Cao |
| FR-23 | Phê duyệt bác sĩ | Admin xét duyệt hồ sơ bác sĩ mới đăng ký | Cao |
| FR-24 | Quản lý chuyên khoa | Thêm/sửa/xóa danh mục chuyên khoa | Trung bình |

### 3.4 Module Tính năng Nâng cao

| ID | Tên chức năng | Mô tả | Ưu tiên |
|----|--------------|-------|---------|
| FR-30 | Video Call | Gọi video realtime giữa bệnh nhân và bác sĩ | Cao |
| FR-31 | Chat realtime | Nhắn tin trực tiếp trong phòng khám ảo | Cao |
| FR-32 | OCR đơn thuốc | Chụp ảnh đơn thuốc → tự động thêm vào giỏ hàng | Trung bình |
| FR-33 | AI Chatbot | Chatbot hỏi triệu chứng, gợi ý chuyên khoa | Trung bình |
| FR-34 | E-Pharmacy | Tìm kiếm và mua thuốc trực tuyến | Trung bình |
| FR-35 | Bản đồ y tế | Hiển thị phòng khám và hiệu thuốc gần nhất (Google Maps) | Trung bình |
| FR-36 | Bài test sức khỏe | BMI, PHQ-9, Stress — có kết quả và tư vấn | Thấp |
| FR-37 | Sổ tiêm chủng | Theo dõi và nhắc lịch tiêm định kỳ | Thấp |

---

## 4. Yêu cầu phi chức năng (Non-Functional Requirements)

### 4.1 Hiệu năng
- **NFR-01:** API phản hồi trong vòng < 2 giây với điều kiện mạng bình thường
- **NFR-02:** Hệ thống hỗ trợ ít nhất 100 người dùng đồng thời (scope dự án sinh viên)
- **NFR-03:** Video call duy trì độ trễ < 500ms trong điều kiện mạng ổn định

### 4.2 Bảo mật
- **NFR-04:** Mật khẩu được mã hóa bằng bcryptjs (salt rounds ≥ 10)
- **NFR-05:** JWT token có thời hạn 24 giờ, refresh token 7 ngày
- **NFR-06:** API endpoint yêu cầu xác thực phải kiểm tra token hợp lệ
- **NFR-07:** Không lưu thông tin nhạy cảm trong localStorage (dùng httpOnly cookie hoặc memory)

### 4.3 Khả dụng
- **NFR-08:** Uptime tối thiểu 95% trong giờ demo và bảo vệ
- **NFR-09:** Giao diện responsive, hoạt động trên màn hình từ 375px (mobile) trở lên

### 4.4 Khả năng bảo trì
- **NFR-10:** Code phải có comment giải thích cho các hàm xử lý logic phức tạp
- **NFR-11:** Tuân theo cấu trúc MVC phía backend, component-based phía frontend
- **NFR-12:** Tất cả API endpoint phải được ghi chép trong API documentation

---

## 5. Mô hình Database

### 5.1 Collections chính

**Users**
```json
{
  "_id": ObjectId,
  "email": String,
  "password": String (hashed),
  "role": "patient" | "doctor" | "nurse" | "admin",
  "name": String,
  "phone": String,
  "healthProfile": {
    "age": Number,
    "gender": String,
    "conditions": [String],
    "allergies": [String]
  },
  "relatives": [{ "name": String, "relation": String, "dob": Date }],
  "createdAt": Date
}
```

**Doctors**
```json
{
  "_id": ObjectId,
  "userId": ObjectId (ref: Users),
  "specialization": String,
  "hospital": String,
  "experience": Number,
  "rating": Number,
  "bio": String,
  "workingSchedule": [{
    "date": Date,
    "slots": [{ "time": String, "isBooked": Boolean }]
  }],
  "isApproved": Boolean
}
```

**Bookings**
```json
{
  "_id": ObjectId,
  "patientId": ObjectId (ref: Users),
  "doctorId": ObjectId (ref: Doctors),
  "date": Date,
  "timeSlot": String,
  "status": "pending" | "confirmed" | "completed" | "cancelled",
  "type": "in-person" | "telemedicine" | "home-care",
  "notes": String,
  "createdAt": Date
}
```

**Medicines (E-Pharmacy)**
```json
{
  "_id": ObjectId,
  "name": String,
  "category": String,
  "price": Number,
  "stock": Number,
  "description": String,
  "imageUrl": String
}
```

---

## 6. API Endpoints (Tóm tắt)

### Auth
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | /api/auth/register | Đăng ký |
| POST | /api/auth/login | Đăng nhập |
| POST | /api/auth/forgot-password | Quên mật khẩu |

### Doctors
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | /api/doctors | Danh sách bác sĩ (có filter) |
| GET | /api/doctors/:id | Chi tiết bác sĩ |
| GET | /api/doctors/:id/slots | Lịch trống của bác sĩ |

### Bookings
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| POST | /api/bookings | Đặt lịch mới |
| GET | /api/bookings/my | Lịch của bệnh nhân hiện tại |
| PUT | /api/bookings/:id/cancel | Hủy lịch |

### Admin
| Method | Endpoint | Mô tả |
|--------|----------|-------|
| GET | /api/admin/stats | Thống kê tổng quan |
| PUT | /api/admin/doctors/:id/approve | Phê duyệt bác sĩ |

---

## 7. Kế hoạch kiểm thử

| Loại test | Công cụ | Phạm vi |
|-----------|---------|---------|
| Unit Test | Jest | Controllers, utility functions |
| API Test | Postman / Thunder Client | Tất cả endpoints |
| Integration Test | Jest + Supertest | Auth flow, Booking flow |
| Manual Test | Trình duyệt | UI/UX, responsive |

---

## 8. Lịch sử thay đổi tài liệu

| Phiên bản | Ngày | Người thực hiện | Nội dung thay đổi |
|-----------|------|-----------------|-------------------|
| v1.0 | Tháng 5, 2025 | Nhóm 1 | Tạo tài liệu ban đầu |
