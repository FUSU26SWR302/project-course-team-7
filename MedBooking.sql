-- =======================================================================
-- MEDBOOKING DATABASE - PHIÊN BẢN 3.0 FINAL
-- Tổng: 28 bảng
-- Cập nhật: Tách bác sĩ tại gia/cơ sở, Clinic Manager, 
--           Onboarding, Examinations, Lab_Tests, Medicines,
--           Health_Books, Appointment_Ratings, Video_Calls,
--           Messages, Notification_Settings, Doctor_Health_Guides
-- =======================================================================

-- =======================================================================
-- BƯỚC 1: XÓA FOREIGN KEY CONSTRAINTS TRƯỚC KHI DROP BẢNG
-- =======================================================================
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql += 
    'ALTER TABLE ' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id))
    + '.' + QUOTENAME(OBJECT_NAME(parent_object_id))
    + ' DROP CONSTRAINT ' + QUOTENAME(name) + ';' + CHAR(13)
FROM sys.foreign_keys;
EXEC sp_executesql @sql;
GO

-- =======================================================================
-- BƯỚC 2: XÓA TẤT CẢ BẢNG CŨ (theo thứ tự phụ thuộc)
-- =======================================================================
DROP TABLE IF EXISTS Doctor_Health_Guides;
DROP TABLE IF EXISTS Lab_Tests;
DROP TABLE IF EXISTS Prescriptions;
DROP TABLE IF EXISTS Medicines;
DROP TABLE IF EXISTS Appointment_Ratings;
DROP TABLE IF EXISTS Video_Calls;
DROP TABLE IF EXISTS Messages;
DROP TABLE IF EXISTS Live_Chats;
DROP TABLE IF EXISTS Complaints;
DROP TABLE IF EXISTS Articles;
DROP TABLE IF EXISTS Medical_Records;
DROP TABLE IF EXISTS Examinations;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Doctor_Schedules;
DROP TABLE IF EXISTS Health_Books;
DROP TABLE IF EXISTS Facility_Info;
DROP TABLE IF EXISTS Private_Practice_Info;
DROP TABLE IF EXISTS Patients;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Clinic_Registrations;
DROP TABLE IF EXISTS Clinic_Managers;
DROP TABLE IF EXISTS Doctor_Approvals;
DROP TABLE IF EXISTS Doctor_Types;
DROP TABLE IF EXISTS Specialties;
DROP TABLE IF EXISTS Clinics;
DROP TABLE IF EXISTS Notification_Settings;
DROP TABLE IF EXISTS Password_Resets;
DROP TABLE IF EXISTS Users;
DROP TABLE IF EXISTS Roles;
GO

-- =======================================================================
-- PHÂN HỆ 1: QUẢN LÝ TÀI KHOẢN, PHÂN QUYỀN & BẢO MẬT
-- 5 bảng: Roles, Users, Doctor_Approvals, Password_Resets, 
--         Notification_Settings
-- =======================================================================

-- 1. Roles — Vai trò phân quyền
-- 4 vai trò: Admin / Doctor / Patient / ClinicManager
CREATE TABLE Roles (
    role_id   INT IDENTITY(1,1) PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL
);

-- 2. Users — Tài khoản tất cả người dùng (TRUNG TÂM)
-- email + password: đăng nhập thường
-- google_id: đăng nhập Google OAuth (2 cột bù trừ nhau, không NULL cả 2)
-- password lưu BCrypt hash 60 ký tự — KHÔNG lưu plain text
-- otp_code + otp_expires_at: xác thực email khi đăng ký
-- avatar_url: đổi ảnh đại diện (UC-P04)
-- address: gợi ý cảnh báo dịch bệnh theo khu vực (UC-P13)
CREATE TABLE Users (
    user_id        INT IDENTITY(1,1) PRIMARY KEY,
    email          VARCHAR(100) UNIQUE NULL,
    password       VARCHAR(255) NULL,
    google_id      VARCHAR(255) UNIQUE NULL,
    full_name      NVARCHAR(100) NOT NULL,
    phone          VARCHAR(15) UNIQUE NULL,
    avatar_url     NVARCHAR(500) NULL,
    gender         NVARCHAR(10) NULL,
    date_of_birth  DATE NULL,
    address        NVARCHAR(500) NULL,
    status         VARCHAR(20) DEFAULT 'Active',
    role_id        INT FOREIGN KEY REFERENCES Roles(role_id),
    otp_code       VARCHAR(10) NULL,
    otp_expires_at DATETIME NULL,
    created_at     DATETIME DEFAULT GETDATE()
);

-- 3. Doctor_Approvals — Duyệt hồ sơ bác sĩ TẠI GIA
-- CHỈ dùng cho luồng Private Doctor (bác sĩ tự đăng ký)
-- Bác sĩ cơ sở/bệnh viện: do Clinic_Registrations + Clinic_Managers quản lý
-- doctor_user_id → bác sĩ đang được xét duyệt
-- approved_by_admin_id → admin người xử lý
-- Lưu lịch sử: từ chối lần 1 nộp lại lần 2 → 2 bản ghi riêng
CREATE TABLE Doctor_Approvals (
    approval_id          INT IDENTITY(1,1) PRIMARY KEY,
    doctor_user_id       INT FOREIGN KEY REFERENCES Users(user_id),
    approved_by_admin_id INT FOREIGN KEY REFERENCES Users(user_id),
    status               VARCHAR(20) DEFAULT 'Pending',
    rejection_reason     NVARCHAR(255) NULL,
    processed_at         DATETIME NULL
);

-- 4. Password_Resets — Token reset mật khẩu
-- token_hash: lưu hash, không lưu token gốc → chống lộ DB
-- is_used = 1 ngay sau khi dùng → chống replay attack
-- expiry_time: token có hiệu lực 15-30 phút
CREATE TABLE Password_Resets (
    reset_id    INT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT FOREIGN KEY REFERENCES Users(user_id),
    token_hash  VARCHAR(255) NOT NULL,
    expiry_time DATETIME NOT NULL,
    is_used     BIT DEFAULT 0
);

-- 5. Notification_Settings — Cài đặt thông báo (UC-P06)
-- appointment_remind: nhắc lịch hẹn
-- epidemic_alert: cảnh báo dịch bệnh khu vực
-- news_update: tin tức sức khỏe mới
-- reminder_hours: nhắc trước bao nhiêu giờ (24h/2h/30 phút)
CREATE TABLE Notification_Settings (
    notification_id    INT IDENTITY(1,1) PRIMARY KEY,
    user_id            INT UNIQUE FOREIGN KEY REFERENCES Users(user_id),
    appointment_remind BIT DEFAULT 1,
    epidemic_alert     BIT DEFAULT 1,
    news_update        BIT DEFAULT 1,
    reminder_hours     INT DEFAULT 24
);

-- =======================================================================
-- PHÂN HỆ 2: CƠ SỞ Y TẾ, BÁC SĨ & BỆNH NHÂN
-- 10 bảng: Clinics, Clinic_Registrations, Clinic_Managers,
--          Specialties, Doctor_Types, Doctors,
--          Private_Practice_Info, Facility_Info, Patients, Health_Books
-- =======================================================================

-- 6. Clinics — Cơ sở y tế / Phòng khám / Bệnh viện
-- Được tạo sau khi Clinic_Registrations được Admin duyệt
-- status: Active / Suspended (Admin có thể khóa cả cơ sở)
CREATE TABLE Clinics (
    clinic_id   INT IDENTITY(1,1) PRIMARY KEY,
    clinic_name NVARCHAR(255) NOT NULL,
    address     NVARCHAR(500) NOT NULL,
    phone       VARCHAR(15) NULL,
    email       VARCHAR(100) NULL,
    website     NVARCHAR(255) NULL,
    status      VARCHAR(20) DEFAULT 'Active'
);

-- 7. Clinic_Registrations — Đơn đăng ký cơ sở chờ Admin duyệt
-- Luồng: Clinic Manager nộp đơn → Admin duyệt → Clinic được hoạt động
-- submitted_by: Clinic Manager nộp đơn
-- reviewed_by: Admin người duyệt
-- license_document_url: giấy phép hoạt động y tế
CREATE TABLE Clinic_Registrations (
    registration_id      INT IDENTITY(1,1) PRIMARY KEY,
    clinic_id            INT FOREIGN KEY REFERENCES Clinics(clinic_id),
    submitted_by         INT FOREIGN KEY REFERENCES Users(user_id),
    license_document_url NVARCHAR(500) NULL,
    status               VARCHAR(20) DEFAULT 'Pending',
    reviewed_by          INT FOREIGN KEY REFERENCES Users(user_id),
    rejection_reason     NVARCHAR(255) NULL,
    processed_at         DATETIME NULL,
    submitted_at         DATETIME DEFAULT GETDATE()
);

-- 8. Clinic_Managers — Tài khoản đại diện cơ sở y tế
-- Actor mới: người đại diện bệnh viện/phòng khám
-- Thêm/xóa bác sĩ vào cơ sở thay vì để bác sĩ tự đăng ký lẻ tẻ
-- 1 clinic có thể có nhiều manager (trưởng khoa các khoa)
CREATE TABLE Clinic_Managers (
    manager_id  INT IDENTITY(1,1) PRIMARY KEY,
    user_id     INT UNIQUE FOREIGN KEY REFERENCES Users(user_id),
    clinic_id   INT FOREIGN KEY REFERENCES Clinics(clinic_id),
    assigned_at DATETIME DEFAULT GETDATE()
);

-- 9. Specialties — Danh mục chuyên khoa
-- Nền tảng cho AI gợi ý chuyên khoa (UC-P12)
-- Tag bài viết theo chuyên khoa (UC-A07)
CREATE TABLE Specialties (
    specialty_id   INT IDENTITY(1,1) PRIMARY KEY,
    specialty_name NVARCHAR(150) NOT NULL,
    description    NVARCHAR(MAX) NULL
);

-- 10. Doctor_Types — Loại hình hành nghề bác sĩ
-- Private: bác sĩ tại gia (tự đăng ký, tự quản lý)
-- Clinic: bác sĩ phòng khám (do Clinic Manager thêm vào)
-- Hospital: bác sĩ bệnh viện lớn (do Clinic Manager thêm vào)
CREATE TABLE Doctor_Types (
    type_id   INT IDENTITY(1,1) PRIMARY KEY,
    type_name VARCHAR(50) NOT NULL
);

-- 11. Doctors — Thông tin chuyên môn bác sĩ
-- Tách khỏi Users: Users lưu đăng nhập, Doctors lưu chuyên môn
-- rating: tính tự động từ AVG(Appointment_Ratings.rating_score)
-- bio: giới thiệu chuyên môn hiển thị công khai
-- certificate_url: bằng cấp upload (dùng cho Doctor_Approvals)
-- clinic_id ĐÃ BỎ khỏi đây — chuyển sang Facility_Info
CREATE TABLE Doctors (
    doctor_id        INT IDENTITY(1,1) PRIMARY KEY,
    user_id          INT UNIQUE NOT NULL FOREIGN KEY REFERENCES Users(user_id),
    specialty_id     INT FOREIGN KEY REFERENCES Specialties(specialty_id),
    doctor_type_id   INT FOREIGN KEY REFERENCES Doctor_Types(type_id),
    experience_years INT NULL,
    examination_fee  DECIMAL(18,2) NULL,
    rating           DECIMAL(3,2) DEFAULT 5.0,
    bio              NVARCHAR(MAX) NULL,
    certificate_url  NVARCHAR(500) NULL
);

-- 12. Private_Practice_Info — Thông tin bổ sung bác sĩ TẠI GIA
-- Chỉ tồn tại khi doctor_type = 'Private'
-- practice_address: địa chỉ phòng khám tại nhà
-- available_home_visit: có đến khám tại nhà bệnh nhân không
-- service_radius_km: bán kính phục vụ
CREATE TABLE Private_Practice_Info (
    practice_id          INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id            INT UNIQUE FOREIGN KEY REFERENCES Doctors(doctor_id),
    practice_address     NVARCHAR(500) NOT NULL,
    practice_phone       VARCHAR(15) NULL,
    available_home_visit BIT DEFAULT 0,
    service_radius_km    INT NULL
);

-- 13. Facility_Info — Thông tin bổ sung bác sĩ THUỘC CƠ SỞ
-- Chỉ tồn tại khi doctor_type = 'Clinic' hoặc 'Hospital'
-- added_by_manager_id: Clinic Manager nào thêm bác sĩ này vào cơ sở
-- department: khoa/phòng ban (Khoa Tim mạch, Khoa Nhi...)
-- position: chức vụ (Trưởng khoa, BS thường trú, Phó giáo sư...)
CREATE TABLE Facility_Info (
    facility_id         INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id           INT UNIQUE FOREIGN KEY REFERENCES Doctors(doctor_id),
    clinic_id           INT FOREIGN KEY REFERENCES Clinics(clinic_id),
    added_by_manager_id INT FOREIGN KEY REFERENCES Clinic_Managers(manager_id),
    department          NVARCHAR(150) NULL,
    position            NVARCHAR(100) NULL,
    joined_at           DATETIME DEFAULT GETDATE()
);

-- 14. Patients — Hồ sơ sức khỏe bệnh nhân
-- Thu thập từ Onboarding Survey sau đăng ký (UC-P01)
-- blood_type: nhóm máu A/B/O/AB + Rh
-- chronic_diseases: bệnh mãn tính (tiểu đường, huyết áp...)
-- current_medications: thuốc đang dùng thường xuyên
-- vaccination_history: lịch sử tiêm chủng
-- Dữ liệu này là INPUT cho AI gợi ý chuyên khoa (UC-P12)
CREATE TABLE Patients (
    patient_id           INT IDENTITY(1,1) PRIMARY KEY,
    user_id              INT UNIQUE NOT NULL FOREIGN KEY REFERENCES Users(user_id),
    blood_type           VARCHAR(5) NULL,
    medical_history      NVARCHAR(MAX) NULL,
    allergies            NVARCHAR(255) NULL,
    chronic_diseases     NVARCHAR(MAX) NULL,
    current_medications  NVARCHAR(MAX) NULL,
    vaccination_history  NVARCHAR(MAX) NULL
);

-- 15. Health_Books — Sổ khám bệnh tổng
-- 1 bệnh nhân = 1 quyển sổ (UNIQUE patient_id)
-- Sổ chứa nhiều Medical_Records theo thời gian
-- Giải quyết góp ý cô: không phải mỗi lần khám là 1 sổ riêng lẻ
-- Bệnh nhân xem sổ: hiển thị timeline toàn bộ lịch sử khám
CREATE TABLE Health_Books (
    book_id    INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT UNIQUE FOREIGN KEY REFERENCES Patients(patient_id),
    created_at DATETIME DEFAULT GETDATE()
);

-- =======================================================================
-- PHÂN HỆ 3: ĐẶT LỊCH HẸN & KẾT QUẢ KHÁM (CORE LOGIC)
-- 8 bảng: Doctor_Schedules, Appointments, Appointment_Ratings,
--         Examinations, Lab_Tests, Medical_Records, 
--         Medicines, Prescriptions
-- =======================================================================

-- 16. Doctor_Schedules — Khung giờ làm việc bác sĩ
-- schedule_type: Offline (tại cơ sở) / Online (video call / chat)
-- is_available: 1=còn trống, 0=đã bị đặt hoặc bị khóa
-- Khi Appointment confirmed → is_available chuyển = 0
-- Khi Appointment cancelled → is_available chuyển lại = 1
CREATE TABLE Doctor_Schedules (
    schedule_id   INT IDENTITY(1,1) PRIMARY KEY,
    doctor_id     INT FOREIGN KEY REFERENCES Doctors(doctor_id),
    work_date     DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    schedule_type VARCHAR(20) DEFAULT 'Offline',
    is_available  BIT DEFAULT 1
);

-- 17. Appointments — Cuộc hẹn đặt lịch khám (TRỤC TRUNG TÂM)
-- Mọi thực thể sau đều xoay quanh appointment_id:
-- Examinations, Medical_Records, Prescriptions, Messages, Video_Calls,
-- Appointment_Ratings, Complaints
-- appointment_type: InPerson / VideoCall / Chat
-- status: Pending → Confirmed → Completed | Cancelled
-- cancelled_by: ghi lại ai hủy (bệnh nhân hay bác sĩ) — UC-P17/UC-D05
-- doctor_id giữ lại để tối ưu query (tránh JOIN thừa)
CREATE TABLE Appointments (
    appointment_id   INT IDENTITY(1,1) PRIMARY KEY,
    patient_id       INT FOREIGN KEY REFERENCES Patients(patient_id),
    doctor_id        INT FOREIGN KEY REFERENCES Doctors(doctor_id),
    schedule_id      INT FOREIGN KEY REFERENCES Doctor_Schedules(schedule_id),
    appointment_type VARCHAR(20) DEFAULT 'InPerson',
    booking_time     DATETIME DEFAULT GETDATE(),
    status           VARCHAR(50) DEFAULT 'Pending',
    reason_cancelled NVARCHAR(255) NULL,
    cancelled_by     INT FOREIGN KEY REFERENCES Users(user_id) NULL
);

-- 18. Appointment_Ratings — Đánh giá từng lần khám (UC-P25)
-- Giải quyết góp ý: rating phải gắn vào Appointment, không chỉ lưu 
-- tổng hợp ở Doctors
-- appointment_id UNIQUE: mỗi lần khám chỉ đánh giá 1 lần
-- Chỉ bệnh nhân có Appointment status='Completed' mới được đánh giá
-- Sau khi tạo → trigger cập nhật lại Doctors.rating = AVG
CREATE TABLE Appointment_Ratings (
    rating_id      INT IDENTITY(1,1) PRIMARY KEY,
    appointment_id INT UNIQUE FOREIGN KEY REFERENCES Appointments(appointment_id),
    patient_id     INT FOREIGN KEY REFERENCES Patients(patient_id),
    doctor_id      INT FOREIGN KEY REFERENCES Doctors(doctor_id),
    rating_score   INT NOT NULL CHECK (rating_score BETWEEN 1 AND 5),
    comment        NVARCHAR(MAX) NULL,
    created_at     DATETIME DEFAULT GETDATE()
);

-- 19. Examinations — Phiếu khám (quy trình trước khi ra bệnh án)
-- Giải quyết góp ý cô: phải có quy trình khám trước khi tạo Medical_Records
-- Luồng đúng: Appointment → Examination → (Lab_Tests) → Medical_Records
-- appointment_id UNIQUE: 1 lần khám chỉ có 1 phiếu khám
-- Bác sĩ điền: sinh hiệu, triệu chứng, ghi chú trong lúc khám
CREATE TABLE Examinations (
    examination_id    INT IDENTITY(1,1) PRIMARY KEY,
    appointment_id    INT UNIQUE FOREIGN KEY REFERENCES Appointments(appointment_id),
    symptoms          NVARCHAR(MAX) NULL,
    temperature       DECIMAL(4,1) NULL,
    blood_pressure    VARCHAR(20) NULL,
    heart_rate        INT NULL,
    weight            DECIMAL(5,2) NULL,
    height            DECIMAL(5,2) NULL,
    examination_notes NVARCHAR(MAX) NULL,
    examined_at       DATETIME DEFAULT GETDATE()
);

-- 20. Lab_Tests — Kết quả xét nghiệm (UC-D13)
-- Bác sĩ chỉ định xét nghiệm trong quá trình khám
-- Gắn với Examinations — có thể có nhiều xét nghiệm trong 1 lần khám
-- normal_range: chỉ số tham chiếu bình thường
CREATE TABLE Lab_Tests (
    test_id        INT IDENTITY(1,1) PRIMARY KEY,
    examination_id INT FOREIGN KEY REFERENCES Examinations(examination_id),
    test_name      NVARCHAR(150) NOT NULL,
    result         NVARCHAR(MAX) NULL,
    normal_range   NVARCHAR(100) NULL,
    unit           NVARCHAR(50) NULL,
    tested_at      DATETIME NULL
);

-- 21. Medical_Records — Hồ sơ bệnh án / Kết quả chẩn đoán (UC-D10)
-- book_id: liên kết vào sổ khám tổng Health_Books
--          → nhiều bệnh án trong 1 sổ = nhiều lần khám trong 1 sổ
-- appointment_id UNIQUE: 1 lần khám chỉ có đúng 1 bệnh án
-- follow_up_date: ngày hẹn tái khám
-- diagnosis NOT NULL: bắt buộc phải có chẩn đoán
CREATE TABLE Medical_Records (
    record_id      INT IDENTITY(1,1) PRIMARY KEY,
    book_id        INT FOREIGN KEY REFERENCES Health_Books(book_id),
    appointment_id INT UNIQUE FOREIGN KEY REFERENCES Appointments(appointment_id),
    diagnosis      NVARCHAR(MAX) NOT NULL,
    doctor_notes   NVARCHAR(MAX) NULL,
    follow_up_date DATE NULL,
    created_at     DATETIME DEFAULT GETDATE()
);

-- 22. Medicines — Danh mục thuốc chuẩn
-- Giải quyết góp ý cô: thuốc phải từ danh mục, không tự gõ tùy ý
-- Bác sĩ search và chọn từ bảng này khi kê đơn
-- generic_name: tên hoạt chất (VD: Paracetamol)
-- category: nhóm thuốc (Kháng sinh, Hạ sốt, Kháng viêm...)
-- is_active: Admin có thể ẩn thuốc không còn dùng
CREATE TABLE Medicines (
    medicine_id   INT IDENTITY(1,1) PRIMARY KEY,
    medicine_name NVARCHAR(150) NOT NULL,
    generic_name  NVARCHAR(150) NULL,
    category      NVARCHAR(100) NULL,
    unit          NVARCHAR(50) NULL,
    description   NVARCHAR(MAX) NULL,
    is_active     BIT DEFAULT 1
);

-- 23. Prescriptions — Chi tiết đơn thuốc (UC-D10)
-- medicine_id FK → Medicines: thay thế medicine_name text tự gõ
-- frequency: tần suất dùng (VD: 2 lần/ngày, sau bữa ăn)
-- duration_days: số ngày cần uống
-- Một bệnh án có thể có nhiều dòng thuốc
CREATE TABLE Prescriptions (
    prescription_id INT IDENTITY(1,1) PRIMARY KEY,
    record_id       INT FOREIGN KEY REFERENCES Medical_Records(record_id),
    medicine_id     INT FOREIGN KEY REFERENCES Medicines(medicine_id),
    dosage          NVARCHAR(100) NOT NULL,
    frequency       NVARCHAR(100) NULL,
    duration_days   INT NULL,
    quantity        INT NOT NULL,
    notes           NVARCHAR(255) NULL
);

-- =======================================================================
-- PHÂN HỆ 4: HỖ TRỢ, TƯ VẤN & TIN TỨC
-- 5 bảng: Messages, Video_Calls, Complaints, 
--         Articles, Doctor_Health_Guides
-- =======================================================================

-- 24. Messages — Tin nhắn tư vấn (đổi tên từ Live_Chats) (UC-P22/UC-D09)
-- Mỗi tin nhắn bắt buộc thuộc 1 appointment — không phải chat tự do
-- message_type: text / image / file
-- is_ai_assistant: tin nhắn từ AI chatbot hay người thật
-- Lấy toàn bộ chat: WHERE appointment_id = X ORDER BY sent_at
CREATE TABLE Messages (
    message_id      INT IDENTITY(1,1) PRIMARY KEY,
    appointment_id  INT FOREIGN KEY REFERENCES Appointments(appointment_id),
    sender_id       INT FOREIGN KEY REFERENCES Users(user_id),
    message_text    NVARCHAR(MAX) NOT NULL,
    message_type    VARCHAR(20) DEFAULT 'text',
    is_ai_assistant BIT DEFAULT 0,
    sent_at         DATETIME DEFAULT GETDATE()
);

-- 25. Video_Calls — Lịch sử cuộc gọi Video/Audio (UC-P21/UC-D08)
-- Giải quyết góp ý cô: tách call riêng khỏi Messages
-- call_type: 'video' / 'audio'
-- status: 'completed' / 'missed' / 'rejected'
-- duration_seconds: thống kê thời lượng tư vấn
CREATE TABLE Video_Calls (
    call_id          INT IDENTITY(1,1) PRIMARY KEY,
    appointment_id   INT FOREIGN KEY REFERENCES Appointments(appointment_id),
    initiated_by     INT FOREIGN KEY REFERENCES Users(user_id),
    call_type        VARCHAR(10) NOT NULL,
    status           VARCHAR(20) NOT NULL,
    started_at       DATETIME NULL,
    ended_at         DATETIME NULL,
    duration_seconds INT NULL
);

-- 26. Complaints — Khiếu nại (UC-A05)
-- appointment_id NOT NULL: khiếu nại phải gắn lịch hẹn → có bằng chứng
-- status: Pending / InProgress / Resolved
-- resolved_by_admin: admin nào xử lý → trách nhiệm giải trình
CREATE TABLE Complaints (
    complaint_id      INT IDENTITY(1,1) PRIMARY KEY,
    patient_id        INT FOREIGN KEY REFERENCES Patients(patient_id),
    appointment_id    INT FOREIGN KEY REFERENCES Appointments(appointment_id),
    title             NVARCHAR(150) NOT NULL,
    description       NVARCHAR(MAX) NOT NULL,
    status            VARCHAR(20) DEFAULT 'Pending',
    resolved_by_admin INT FOREIGN KEY REFERENCES Users(user_id),
    resolution_text   NVARCHAR(MAX) NULL,
    created_at        DATETIME DEFAULT GETDATE()
);

-- 27. Articles — Bài viết tin tức & cảnh báo dịch bệnh (UC-A06/UC-A07/UC-A08)
-- type: 'News' / 'Alert' / 'HealthGuide'
-- specialty_id: tag chuyên khoa → cá nhân hóa hiển thị theo bệnh nền (UC-P14)
-- target_region: cảnh báo dịch bệnh theo khu vực (UC-P13)
-- is_published: Admin soạn xong mới publish (có thể save draft trước)
CREATE TABLE Articles (
    article_id     INT IDENTITY(1,1) PRIMARY KEY,
    title          NVARCHAR(255) NOT NULL,
    content        NVARCHAR(MAX) NOT NULL,
    type           VARCHAR(50) NOT NULL,
    specialty_id   INT FOREIGN KEY REFERENCES Specialties(specialty_id) NULL,
    target_disease NVARCHAR(100) NULL,
    target_region  NVARCHAR(255) NULL,
    created_by     INT FOREIGN KEY REFERENCES Users(user_id),
    is_published   BIT DEFAULT 0,
    created_at     DATETIME DEFAULT GETDATE()
);

-- 28. Doctor_Health_Guides — Tài liệu hướng dẫn sau khám (UC-D11)
-- Bác sĩ gửi tài liệu chăm sóc hậu khám thẳng vào hồ sơ bệnh nhân
-- record_id: gắn với bệnh án cụ thể
-- document_url: file PDF / hình ảnh đính kèm
-- Bệnh nhân xem qua UC-P23 View Diagnosis
CREATE TABLE Doctor_Health_Guides (
    guide_id     INT IDENTITY(1,1) PRIMARY KEY,
    record_id    INT FOREIGN KEY REFERENCES Medical_Records(record_id),
    doctor_id    INT FOREIGN KEY REFERENCES Doctors(doctor_id),
    title        NVARCHAR(255) NOT NULL,
    content      NVARCHAR(MAX) NULL,
    document_url NVARCHAR(500) NULL,
    created_at   DATETIME DEFAULT GETDATE()
);

-- =======================================================================
-- DỮ LIỆU MẪU KHỞI TẠO (SEED DATA)
-- =======================================================================

-- Roles
INSERT INTO Roles (role_name) VALUES 
('Admin'), 
('Doctor'), 
('Patient'), 
('ClinicManager');

-- Doctor_Types
INSERT INTO Doctor_Types (type_name) VALUES 
('Private'),
('Clinic'),
('Hospital');

-- Specialties
INSERT INTO Specialties (specialty_name, description) VALUES
(N'Tim mạch', N'Chẩn đoán và điều trị các bệnh lý về tim và mạch máu'),
(N'Nội tiết', N'Điều trị tiểu đường, tuyến giáp và các rối loạn nội tiết'),
(N'Da liễu', N'Điều trị các bệnh về da, tóc, móng'),
(N'Nhi khoa', N'Chăm sóc sức khỏe trẻ em từ sơ sinh đến 16 tuổi'),
(N'Thần kinh', N'Chẩn đoán bệnh lý não, tủy sống và hệ thần kinh ngoại vi'),
(N'Cơ xương khớp', N'Điều trị các bệnh về xương, khớp, cột sống'),
(N'Tiêu hóa', N'Chẩn đoán và điều trị bệnh dạ dày, ruột, gan, mật'),
(N'Sản phụ khoa', N'Chăm sóc sức khỏe sinh sản và phụ khoa'),
(N'Tâm thần', N'Điều trị rối loạn tâm thần, lo âu, trầm cảm'),
(N'Mắt', N'Khám và điều trị các bệnh về mắt'),
(N'Tai mũi họng', N'Điều trị bệnh lý tai, mũi, họng'),
(N'Răng hàm mặt', N'Chăm sóc răng miệng và hàm mặt');

-- Medicines mẫu
INSERT INTO Medicines (medicine_name, generic_name, category, unit, description) VALUES
(N'Paracetamol 500mg', N'Paracetamol', N'Hạ sốt - Giảm đau', N'Viên', N'Hạ sốt, giảm đau. Không dùng quá 8 viên/ngày'),
(N'Amoxicillin 500mg', N'Amoxicillin', N'Kháng sinh', N'Viên', N'Kháng sinh nhóm Penicillin. Dị ứng Penicillin không dùng'),
(N'Omeprazole 20mg', N'Omeprazole', N'Dạ dày', N'Viên', N'Ức chế bơm proton, điều trị loét dạ dày'),
(N'Metformin 500mg', N'Metformin', N'Tiểu đường', N'Viên', N'Điều trị tiểu đường type 2. Uống trong bữa ăn'),
(N'Amlodipine 5mg', N'Amlodipine', N'Tim mạch', N'Viên', N'Điều trị huyết áp cao và đau thắt ngực'),
(N'Cetirizine 10mg', N'Cetirizine', N'Dị ứng', N'Viên', N'Kháng histamine, điều trị dị ứng, viêm mũi'),
(N'Ibuprofen 400mg', N'Ibuprofen', N'Giảm đau - Kháng viêm', N'Viên', N'Giảm đau, hạ sốt, kháng viêm. Uống sau ăn'),
(N'Vitamin C 500mg', N'Ascorbic Acid', N'Vitamin', N'Viên', N'Bổ sung Vitamin C, tăng sức đề kháng');