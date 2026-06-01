# 🏥 SWR302 – Hệ thống Hỗ trợ Đặt lịch Khám bệnh

> **Nhóm 1** | FPT University  
> Môn: SWP391 – Software Project

---

## 👥 Thành viên nhóm

| MSSV | Họ và tên |
|------|-----------|
| DE190205 | Nguyễn Đắc Dũng | 
| DE190388 | Nguyễn Văn Đức | 
| DE190541 | Chu Cao Huy | 
| DE190522 | Nguyễn Minh Trung | 
| DE190512 | Mai Văn Lượng |

---

## 📌 Giới thiệu dự án

Hệ thống hỗ trợ đặt lịch khám bệnh trực tuyến — kết nối bệnh nhân, bác sĩ, cơ sở y tế và nhà thuốc trong một nền tảng duy nhất. Hệ thống tích hợp AI OCR, Chatbot triệu chứng, Telemedicine và bản đồ y tế tương tác.

---

## 🔬 RBL – Research by Learning

Dự án tập trung nghiên cứu và ứng dụng các nội dung sau:

### 1. Thuật toán
- **Thuật toán tìm kiếm & lọc bác sĩ**: Lọc theo chuyên khoa, khoảng cách GPS, rating, timeslot còn trống
- **Thuật toán lập lịch (Scheduling)**: Quản lý timeslot không trùng lịch, xử lý đặt lịch đồng thời (concurrency)
- **OCR Pipeline**: Tiền xử lý ảnh → nhận diện ký tự (Tesseract.js) → mapping tên thuốc

### 2. Kiến trúc hệ thống
- **MVC Architecture** phía backend (Express.js)
- **Component-based Architecture** phía frontend (ReactJS)
- **RESTful API** chuẩn giao tiếp client–server
- **WebSocket (Socket.io)** cho realtime chat và video call
- **Event-driven** cho hệ thống thông báo email tự động

### 3. Công nghệ áp dụng
- So sánh và lý giải lựa chọn **Node.js vs Java Spring Boot** (xem mục Technology Stack bên dưới)
- Tích hợp **Google Maps API** cho bản đồ y tế
- Ứng dụng **Tesseract.js / Google Vision API** cho OCR đơn thuốc
- Triển khai **JWT Authentication** bảo mật

---

## 🛠️ Technology Stack

### Tại sao chọn Node.js thay vì Java Spring Boot?

| Tiêu chí | Node.js ✅ (lựa chọn) | Java Spring Boot ❌ |
|----------|----------------------|---------------------|
| **Tốc độ khởi động** | Nhanh, nhẹ (~50MB RAM) | Chậm hơn, nặng hơn (~300MB RAM) |
| **Realtime (Socket.io)** | Hỗ trợ native, non-blocking I/O | Cần cấu hình thêm (Spring WebSocket) |
| **Cùng ngôn ngữ với Frontend** | JavaScript xuyên suốt (ReactJS + Node.js) | Khác ngôn ngữ (Java ≠ JavaScript) |
| **Hệ sinh thái npm** | 2M+ packages, dễ tích hợp AI/OCR | Maven/Gradle, ít thư viện AI hơn |
| **Phù hợp nhóm sinh viên** | Học nhanh, cộng đồng lớn | Curve học dốc hơn |
| **Deploy miễn phí** | Render / Railway hỗ trợ tốt | Cần VPS, khó deploy miễn phí |

> **Kết luận:** Node.js phù hợp hơn cho dự án này vì tính đồng nhất ngôn ngữ, hỗ trợ realtime tốt và hệ sinh thái phong phú cho các tính năng AI/OCR.

### Stack đầy đủ

```
Frontend   : ReactJS + TailwindCSS + React Router
Backend    : Node.js + Express.js
Database   : MongoDB Atlas + Mongoose
Auth       : JWT + bcryptjs
Realtime   : Socket.io (chat + notification)
Email      : Nodemailer
Maps       : Google Maps API
OCR        : Tesseract.js
Deploy     : Vercel (FE) + Render (BE) + MongoDB Atlas (DB)
```

---

## 📋 Tính năng chính

### Tính năng cơ bản
- [x] Đăng ký / Đăng nhập (Email + JWT)
- [x] Khảo sát sức khỏe đầu vào (Onboarding Survey)
- [x] Hồ sơ sức khỏe điện tử & quản lý người thân
- [x] Tìm kiếm bác sĩ theo chuyên khoa / vị trí
- [x] Đặt lịch khám — chọn ngày, khung giờ, xác nhận
- [x] Quản lý lịch hẹn (xem, hủy, đổi lịch)
- [x] Gửi email xác nhận & nhắc lịch tự động
- [x] Dashboard bác sĩ & Admin

### Tính năng nâng cao
- [ ] Telemedicine: Video Call + Chat realtime (Socket.io / WebRTC)
- [ ] Đặt hộ lý / điều dưỡng tại nhà
- [ ] Lấy mẫu xét nghiệm tại nhà
- [ ] E-Pharmacy: mua thuốc trực tuyến
- [ ] AI OCR đơn thuốc (Tesseract.js)
- [ ] AI Chatbot triệu chứng (Symptom Checker)
- [ ] Bài test sức khỏe: BMI, PHQ-9, Stress
- [ ] Sổ tiêm chủng điện tử
- [ ] Bản đồ y tế tương tác (Google Maps API)
- [ ] Tin tức & bản đồ dịch bệnh realtime



## 🔗 Quản lý công việc (Jira)

> 📌 **Link Jira của nhóm:**https://swp391healthcare.atlassian.net/jira/software/projects/SCRUM/boards/1?atlOrigin=eyJpIjoiODk3Nzg2Y2NhM2IwNGM0ZGI0ZGQ1M2M4OTAwOGQwYzkiLCJwIjoiaiJ9

