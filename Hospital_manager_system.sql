CREATE DATABASE HOSPITAL_MANAGER_SYSTEM
-- Bảng bệnh nhân
CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    FullName VARCHAR(100),
    DOB DATE,
    Gender VARCHAR(10)
);

-- Hồ sơ y tế
CREATE TABLE MedicalRecords (
    RecordID INT PRIMARY KEY,
    PatientID INT,
    Diagnosis TEXT,
    Treatment TEXT,
    RecordDate DATE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

-- Bảng bác sĩ
CREATE TABLE Doctors (
    DoctorID INT PRIMARY KEY,
    Name VARCHAR(100),
    Specialty VARCHAR(50)
);

-- Cuộc hẹn
CREATE TABLE Appointments (
    AppointmentID INT PRIMARY KEY,
    PatientID INT,
    DoctorID INT,
    AppointmentDate DATETIME,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES Doctors(DoctorID)
);

-- Hóa đơn
CREATE TABLE Bills (
    BillID INT PRIMARY KEY,
    PatientID INT,
    Amount DECIMAL(12, 2),
    DateIssued DATE,
    FOREIGN KEY (PatientID) REFERENCES Patients(PatientID)
);

INSERT INTO Patients (PatientID, FullName, DOB, Gender)
VALUES 
  (1, 'Nguyen Van A', '1980-05-15', 'Male'),
  (2, 'Le Thi B', '1985-09-20', 'Female'),
  (3, 'Tran Van C', '1975-12-10', 'Male');
INSERT INTO MedicalRecords (RecordID, PatientID, Diagnosis, Treatment, RecordDate)
VALUES
  (101, 1, 'Hypertension', 'Medication and Diet', '2023-06-01'),
  (102, 2, 'Diabetes', 'Insulin Therapy', '2023-06-05'),
  (103, 1, 'Flu', 'Rest and Medication', '2023-07-10'),
  (104, 3, 'Arthritis', 'Physical Therapy', '2023-08-20');
INSERT INTO Doctors (DoctorID, Name, Specialty)
VALUES
  (201, 'Dr. Pham Van D', 'Cardiology'),
  (202, 'Dr. Tran Thi E', 'Endocrinology'),
  (203, 'Dr. Nguyen Van F', 'General Practice');
INSERT INTO Appointments (AppointmentID, PatientID, DoctorID, AppointmentDate)
VALUES
  (301, 1, 201, '2023-06-10 09:00:00'),
  (302, 2, 202, '2023-06-12 10:30:00'),
  (303, 3, 203, '2023-06-15 14:00:00'),
  (304, 1, 203, '2023-07-15 16:00:00');
INSERT INTO Bills (BillID, PatientID, Amount, DateIssued)
VALUES
  (401, 1, 200.50, '2023-06-11'),
  (402, 2, 350.75, '2023-06-13'),
  (403, 3, 150.00, '2023-06-16'),
  (404, 1, 100.00, '2023-07-16');


-- 1. Bệnh nhân đã khám với bác sĩ chuyên khoa "Tim mạch"
SELECT DISTINCT p.FullName, d.Name AS Doctor
FROM Appointments a
JOIN Patients p ON a.PatientID = p.PatientID
JOIN Doctors d ON a.DoctorID = d.DoctorID
WHERE d.Specialty = 'Cardiology';

-- 2. Tổng doanh thu bệnh viện từ hóa đơn
SELECT SUM(Amount) AS TotalRevenue
FROM Bills;

-- 3. Số lượng cuộc hẹn theo bác sĩ
SELECT d.Name, COUNT(*) AS NumAppointments
FROM Appointments a
JOIN Doctors d ON a.DoctorID = d.DoctorID
GROUP BY d.DoctorID, d.Name
ORDER BY NumAppointments DESC;

-- 4. Xếp hạng bệnh nhân theo số lần hẹn khám
-- Sử dụng window function để tính số cuộc hẹn cho mỗi bệnh nhân và xếp hạng theo số cuộc hẹn giảm dần
SELECT 
    p.PatientID,
    p.FullName,
    COUNT(a.AppointmentID) AS NumAppointments,
    RANK() OVER (ORDER BY COUNT(a.AppointmentID) DESC) AS AppointmentRank
FROM Patients p
JOIN Appointments a ON p.PatientID = a.PatientID
GROUP BY p.PatientID, p.FullName;

--  5. Tìm các bác sĩ có số cuộc hẹn vượt mức trung bình
-- Tính số cuộc hẹn cho từng bác sĩ và chỉ ra bác sĩ có số cuộc hẹn cao hơn mức trung bình của tất cả bác sĩ
SELECT 
    d.DoctorID,
    d.Name,
    COUNT(a.AppointmentID) AS NumAppointments
FROM Doctors d
LEFT JOIN Appointments a ON d.DoctorID = a.DoctorID
GROUP BY d.DoctorID, d.Name
HAVING COUNT(a.AppointmentID) > (
    SELECT AVG(AppointmentCount)
    FROM (
         SELECT COUNT(AppointmentID) AS AppointmentCount
         FROM Appointments
         GROUP BY DoctorID
    ) AS SubQ
);

-- 6. Tìm các bệnh nhân có tổng hóa đơn vượt trung bình
-- Nhóm các hóa đơn theo bệnh nhân, tính tổng số tiền của mỗi bệnh nhân và chỉ ra những bệnh nhân có tổng chi tiêu vượt mức trung bình của tất cả các bệnh nhân
SELECT 
    p.FullName,
    SUM(b.Amount) AS TotalSpending
FROM Patients p
JOIN Bills b ON p.PatientID = b.PatientID
GROUP BY p.FullName
HAVING SUM(b.Amount) > (
   SELECT AVG(TotalAmount)
   FROM (
       SELECT PatientID, SUM(Amount) AS TotalAmount
       FROM Bills
       GROUP BY PatientID
   ) AS sub
);
--  7. Tổng doanh thu bệnh viện theo bác sĩ (sử dụng CTE)
-- Đầu tiên, sử dụng CTE để lấy danh sách các bệnh nhân được khám bởi mỗi bác sĩ, sau đó tính tổng số tiền hóa đơn tương ứng với các bệnh nhân đó.
WITH DoctorPatients AS (
    SELECT 
        d.DoctorID,
        d.Name AS DoctorName,
        a.PatientID
    FROM Doctors d
    JOIN Appointments a ON d.DoctorID = a.DoctorID
)
SELECT 
    dp.DoctorID,
    dp.DoctorName,
    SUM(b.Amount) AS TotalRevenue
FROM DoctorPatients dp
JOIN Bills b ON dp.PatientID = b.PatientID
GROUP BY dp.DoctorID, dp.DoctorName;
-- 8. Liệt kê bác sĩ và số lượng bệnh nhân duy nhất mà họ đã khám
SELECT 
    d.Name AS DoctorName,
    COUNT(DISTINCT a.PatientID) AS UniquePatients
FROM Doctors d
JOIN Appointments a ON d.DoctorID = a.DoctorID
GROUP BY d.Name
ORDER BY UniquePatients DESC;
-- 9. Tìm bác sĩ có cuộc hẹn đầu tiên sớm nhất (ngày khám sớm nhất)
SELECT TOP 1 
    d.Name AS DoctorName,
    MIN(a.AppointmentDate) AS FirstAppointment
FROM Doctors d
JOIN Appointments a ON d.DoctorID = a.DoctorID
GROUP BY d.Name
ORDER BY FirstAppointment ASC;

-- 10. Pivot dữ liệu: Số lần bệnh nhân khám với từng bác sĩ
SELECT * FROM (
    SELECT 
        p.FullName AS Patient,
        d.Name AS Doctor
    FROM Appointments a
    JOIN Patients p ON a.PatientID = p.PatientID
    JOIN Doctors d ON a.DoctorID = d.DoctorID
) AS SourceTable
PIVOT (
    COUNT(Doctor)
    FOR Doctor IN ([Dr. Pham Van D], [Dr. Tran Thi E], [Dr. Nguyen Van F])
) AS PivotResult;
-- 11. Bệnh nhân có tổng chi phí điều trị cao nhất
SELECT TOP 1 
    p.FullName,
    SUM(b.Amount) AS TotalSpent
FROM Patients p
JOIN Bills b ON p.PatientID = b.PatientID
GROUP BY p.FullName
ORDER BY TotalSpent DESC;
-- 12. Lấy ra chẩn đoán gần nhất của mỗi bệnh nhân
WITH LastRecord AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY PatientID ORDER BY RecordDate DESC) AS rn
    FROM MedicalRecords
)
SELECT 
    p.FullName,
    lr.Diagnosis,
    lr.RecordDate
FROM LastRecord lr
JOIN Patients p ON lr.PatientID = p.PatientID
WHERE rn = 1;
-- 13. Tính trung bình số cuộc hẹn mỗi tháng
SELECT 
    FORMAT(AppointmentDate, 'yyyy-MM') AS Month,
    COUNT(*) AS NumAppointments
FROM Appointments
GROUP BY FORMAT(AppointmentDate, 'yyyy-MM')
ORDER BY Month;



