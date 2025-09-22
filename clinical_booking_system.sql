-- =====================================================
-- CLINICAL BOOKING SYSTEM DATABASE
-- =====================================================
-- Author: Ogayo Andrew
-- Date: September 2025
-- Description: Complete relational database for managing
-- clinical operations including patients, doctors, appointments,
-- medical records, prescriptions, and billing.
-- =====================================================

-- Drop database if exists and create new one
DROP DATABASE IF EXISTS clinical_booking_system;
CREATE DATABASE clinical_booking_system;
USE clinical_booking_system;

-- =====================================================
-- TABLE 1: DEPARTMENTS
-- =====================================================
CREATE TABLE departments (
    department_id INT AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    floor_number INT,
    phone_extension VARCHAR(10),
    head_doctor_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE 2: SPECIALIZATIONS
-- =====================================================
CREATE TABLE specializations (
    specialization_id INT AUTO_INCREMENT PRIMARY KEY,
    specialization_name VARCHAR(100) NOT NULL UNIQUE,
    specialization_code VARCHAR(20) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE 3: DOCTORS
-- =====================================================
CREATE TABLE doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    alternative_phone VARCHAR(20),
    address VARCHAR(255),
    city VARCHAR(100),
    postal_code VARCHAR(20),
    department_id INT NOT NULL,
    specialization_id INT NOT NULL,
    qualification VARCHAR(255) NOT NULL,
    experience_years INT DEFAULT 0 CHECK (experience_years >= 0),
    license_number VARCHAR(50) NOT NULL UNIQUE,
    consultation_fee DECIMAL(10, 2) NOT NULL CHECK (consultation_fee >= 0),
    join_date DATE NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    max_appointments_per_day INT DEFAULT 20 CHECK (max_appointments_per_day > 0),
    consultation_duration_minutes INT DEFAULT 30 CHECK (consultation_duration_minutes > 0),
    password_hash VARCHAR(255) NOT NULL,
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (department_id) REFERENCES departments(department_id) ON DELETE RESTRICT,
    FOREIGN KEY (specialization_id) REFERENCES specializations(specialization_id) ON DELETE RESTRICT,
    INDEX idx_doctor_email (email),
    INDEX idx_doctor_code (doctor_code),
    INDEX idx_doctor_department (department_id)
);

-- Add foreign key for department head after doctors table is created
ALTER TABLE departments 
ADD FOREIGN KEY (head_doctor_id) REFERENCES doctors(doctor_id) ON DELETE SET NULL;

-- =====================================================
-- TABLE 4: DOCTOR_SCHEDULES
-- =====================================================
CREATE TABLE doctor_schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    break_start_time TIME,
    break_end_time TIME,
    is_available BOOLEAN DEFAULT TRUE,
    effective_from DATE NOT NULL DEFAULT (CURRENT_DATE),
    effective_until DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    UNIQUE KEY unique_doctor_schedule (doctor_id, day_of_week, start_time),
    INDEX idx_schedule_doctor (doctor_id),
    CONSTRAINT chk_schedule_times CHECK (end_time > start_time),
    CONSTRAINT chk_break_times CHECK (
        (break_start_time IS NULL AND break_end_time IS NULL) OR
        (break_start_time IS NOT NULL AND break_end_time IS NOT NULL AND 
         break_end_time > break_start_time AND 
         break_start_time >= start_time AND 
         break_end_time <= end_time)
    )
);

-- =====================================================
-- TABLE 5: PATIENTS
-- =====================================================
CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    date_of_birth DATE NOT NULL,
    blood_group ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20) NOT NULL,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relationship VARCHAR(50),
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    occupation VARCHAR(100),
    marital_status ENUM('Single', 'Married', 'Divorced', 'Widowed', 'Other'),
    registration_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    allergies TEXT,
    chronic_conditions TEXT,
    current_medications TEXT,
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    password_hash VARCHAR(255),
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_patient_code (patient_code),
    INDEX idx_patient_email (email),
    INDEX idx_patient_phone (phone)
);

-- =====================================================
-- TABLE 6: APPOINTMENT_STATUS
-- =====================================================
CREATE TABLE appointment_status (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    status_color VARCHAR(7),
    description TEXT
);

-- Insert default appointment statuses
INSERT INTO appointment_status (status_name, status_color, description) VALUES
('Scheduled', '#007bff', 'Appointment has been scheduled'),
('Confirmed', '#28a745', 'Appointment has been confirmed by patient'),
('In Progress', '#ffc107', 'Patient is currently being seen'),
('Completed', '#6c757d', 'Appointment has been completed'),
('Cancelled', '#dc3545', 'Appointment was cancelled'),
('No Show', '#6f42c1', 'Patient did not show up'),
('Rescheduled', '#17a2b8', 'Appointment has been rescheduled');

-- =====================================================
-- TABLE 7: APPOINTMENTS
-- =====================================================
CREATE TABLE appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_code VARCHAR(30) NOT NULL UNIQUE,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    appointment_end_time TIME NOT NULL,
    appointment_type ENUM('Consultation', 'Follow-up', 'Emergency', 'Routine Checkup', 'Vaccination', 'Surgery') NOT NULL,
    status_id INT NOT NULL DEFAULT 1,
    reason_for_visit TEXT NOT NULL,
    symptoms TEXT,
    priority ENUM('Low', 'Medium', 'High', 'Urgent') DEFAULT 'Medium',
    notes TEXT,
    cancelled_reason TEXT,
    cancelled_by VARCHAR(50),
    cancelled_at DATETIME,
    rescheduled_from INT,
    created_by VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (status_id) REFERENCES appointment_status(status_id) ON DELETE RESTRICT,
    FOREIGN KEY (rescheduled_from) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    INDEX idx_appointment_patient (patient_id),
    INDEX idx_appointment_doctor (doctor_id),
    INDEX idx_appointment_date (appointment_date),
    INDEX idx_appointment_status (status_id),
    UNIQUE KEY unique_doctor_appointment (doctor_id, appointment_date, appointment_time),
    CONSTRAINT chk_appointment_times CHECK (appointment_end_time > appointment_time)
);

-- =====================================================
-- TABLE 8: MEDICAL_RECORDS
-- =====================================================
CREATE TABLE medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL UNIQUE,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    visit_date DATE NOT NULL,
    chief_complaint TEXT,
    present_illness_history TEXT,
    past_medical_history TEXT,
    family_history TEXT,
    social_history TEXT,
    vital_signs JSON,
    height_cm DECIMAL(5, 2),
    weight_kg DECIMAL(5, 2),
    bmi DECIMAL(4, 2),
    blood_pressure VARCHAR(20),
    pulse_rate INT,
    temperature_celsius DECIMAL(4, 2),
    respiratory_rate INT,
    examination_findings TEXT,
    diagnosis TEXT NOT NULL,
    treatment_plan TEXT,
    follow_up_required BOOLEAN DEFAULT FALSE,
    follow_up_date DATE,
    doctor_notes TEXT,
    is_confidential BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    INDEX idx_medical_record_patient (patient_id),
    INDEX idx_medical_record_date (visit_date)
);

-- =====================================================
-- TABLE 9: MEDICINES
-- =====================================================
CREATE TABLE medicines (
    medicine_id INT AUTO_INCREMENT PRIMARY KEY,
    medicine_code VARCHAR(50) NOT NULL UNIQUE,
    medicine_name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),
    category VARCHAR(100),
    manufacturer VARCHAR(200),
    unit_of_measure VARCHAR(50),
    strength VARCHAR(50),
    form ENUM('Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Inhaler', 'Powder', 'Other'),
    unit_price DECIMAL(10, 2) CHECK (unit_price >= 0),
    stock_quantity INT DEFAULT 0 CHECK (stock_quantity >= 0),
    reorder_level INT DEFAULT 10,
    expiry_date DATE,
    storage_conditions VARCHAR(200),
    requires_prescription BOOLEAN DEFAULT TRUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_medicine_name (medicine_name)
);

-- =====================================================
-- TABLE 10: PRESCRIPTIONS
-- =====================================================
CREATE TABLE prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_code VARCHAR(30) NOT NULL UNIQUE,
    medical_record_id INT NOT NULL,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    prescription_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    valid_until DATE,
    pharmacy_notes TEXT,
    is_dispensed BOOLEAN DEFAULT FALSE,
    dispensed_date DATETIME,
    dispensed_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (medical_record_id) REFERENCES medical_records(record_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    INDEX idx_prescription_patient (patient_id),
    INDEX idx_prescription_date (prescription_date)
);

-- =====================================================
-- TABLE 11: PRESCRIPTION_DETAILS (Many-to-Many)
-- =====================================================
CREATE TABLE prescription_details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    prescription_id INT NOT NULL,
    medicine_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration VARCHAR(100) NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    instructions TEXT,
    meal_instruction ENUM('Before Meal', 'After Meal', 'With Meal', 'Empty Stomach', 'As Directed'),
    FOREIGN KEY (prescription_id) REFERENCES prescriptions(prescription_id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id) ON DELETE RESTRICT,
    INDEX idx_prescription_detail (prescription_id)
);

-- =====================================================
-- TABLE 12: LAB_TESTS
-- =====================================================
CREATE TABLE lab_tests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_code VARCHAR(50) NOT NULL UNIQUE,
    test_name VARCHAR(200) NOT NULL,
    test_category VARCHAR(100),
    department VARCHAR(100),
    sample_type VARCHAR(100),
    normal_range VARCHAR(200),
    unit VARCHAR(50),
    price DECIMAL(10, 2) CHECK (price >= 0),
    turnaround_days INT DEFAULT 1,
    preparation_required TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================
-- TABLE 13: LAB_TEST_ORDERS
-- =====================================================
CREATE TABLE lab_test_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_code VARCHAR(30) NOT NULL UNIQUE,
    medical_record_id INT NOT NULL,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    test_id INT NOT NULL,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    priority ENUM('Routine', 'Urgent', 'STAT') DEFAULT 'Routine',
    clinical_notes TEXT,
    sample_collected BOOLEAN DEFAULT FALSE,
    sample_collected_at DATETIME,
    sample_collected_by VARCHAR(100),
    result_value VARCHAR(500),
    result_status ENUM('Pending', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Pending',
    result_date DATETIME,
    result_notes TEXT,
    verified_by VARCHAR(100),
    verified_at DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (medical_record_id) REFERENCES medical_records(record_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    FOREIGN KEY (test_id) REFERENCES lab_tests(test_id) ON DELETE RESTRICT,
    INDEX idx_lab_order_patient (patient_id),
    INDEX idx_lab_order_status (result_status)
);

-- =====================================================
-- TABLE 14: BILLING
-- =====================================================
CREATE TABLE billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_number VARCHAR(30) NOT NULL UNIQUE,
    patient_id INT NOT NULL,
    appointment_id INT,
    bill_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    consultation_fee DECIMAL(10, 2) DEFAULT 0 CHECK (consultation_fee >= 0),
    medicine_charges DECIMAL(10, 2) DEFAULT 0 CHECK (medicine_charges >= 0),
    lab_charges DECIMAL(10, 2) DEFAULT 0 CHECK (lab_charges >= 0),
    other_charges DECIMAL(10, 2) DEFAULT 0 CHECK (other_charges >= 0),
    subtotal DECIMAL(10, 2) GENERATED ALWAYS AS (consultation_fee + medicine_charges + lab_charges + other_charges) STORED,
    discount_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (discount_percentage >= 0 AND discount_percentage <= 100),
    discount_amount DECIMAL(10, 2) DEFAULT 0 CHECK (discount_amount >= 0),
    tax_percentage DECIMAL(5, 2) DEFAULT 0 CHECK (tax_percentage >= 0),
    tax_amount DECIMAL(10, 2) DEFAULT 0 CHECK (tax_amount >= 0),
    total_amount DECIMAL(10, 2) NOT NULL,
    paid_amount DECIMAL(10, 2) DEFAULT 0 CHECK (paid_amount >= 0),
    balance_amount DECIMAL(10, 2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,
    payment_status ENUM('Pending', 'Partial', 'Paid', 'Overdue', 'Cancelled') DEFAULT 'Pending',
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Insurance', 'Online', 'Cheque') DEFAULT 'Cash',
    insurance_claim_number VARCHAR(100),
    insurance_approved_amount DECIMAL(10, 2),
    notes TEXT,
    created_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id) ON DELETE SET NULL,
    INDEX idx_billing_patient (patient_id),
    INDEX idx_billing_status (payment_status),
    INDEX idx_billing_date (bill_date)
);

-- =====================================================
-- TABLE 15: PAYMENT_TRANSACTIONS
-- =====================================================
CREATE TABLE payment_transactions (
    transaction_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_code VARCHAR(30) NOT NULL UNIQUE,
    bill_id INT NOT NULL,
    patient_id INT NOT NULL,
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
    payment_method ENUM('Cash', 'Credit Card', 'Debit Card', 'Insurance', 'Online', 'Cheque') NOT NULL,
    reference_number VARCHAR(100),
    bank_name VARCHAR(100),
    card_last_four VARCHAR(4),
    received_by VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES billing(bill_id) ON DELETE RESTRICT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE RESTRICT,
    INDEX idx_payment_bill (bill_id),
    INDEX idx_payment_date (payment_date)
);

-- =====================================================
-- TABLE 16: STAFF (Non-Medical Staff)
-- =====================================================
CREATE TABLE staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    position VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    hire_date DATE NOT NULL,
    salary DECIMAL(12, 2),
    address VARCHAR(255),
    is_active BOOLEAN DEFAULT TRUE,
    can_manage_appointments BOOLEAN DEFAULT FALSE,
    can_manage_billing BOOLEAN DEFAULT FALSE,
    can_view_medical_records BOOLEAN DEFAULT FALSE,
    password_hash VARCHAR(255) NOT NULL,
    last_login DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_staff_email (email)
);

-- =====================================================
-- TABLE 17: AUDIT_LOG
-- =====================================================
CREATE TABLE audit_log (
    log_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_type ENUM('Patient', 'Doctor', 'Staff', 'System') NOT NULL,
    user_id INT,
    user_name VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50),
    record_id INT,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_user (user_type, user_id),
    INDEX idx_audit_timestamp (timestamp),
    INDEX idx_audit_table (table_name, record_id)
);

-- =====================================================
-- VIEWS
-- =====================================================

-- View for Today's Appointments
CREATE VIEW today_appointments AS
SELECT 
    a.appointment_id,
    a.appointment_code,
    a.appointment_date,
    a.appointment_time,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    dept.department_name,
    s.status_name,
    a.appointment_type,
    a.reason_for_visit
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
JOIN doctors d ON a.doctor_id = d.doctor_id
JOIN departments dept ON d.department_id = dept.department_id
JOIN appointment_status s ON a.status_id = s.status_id
WHERE a.appointment_date = CURRENT_DATE
ORDER BY a.appointment_time;

-- View for Doctor Availability
CREATE VIEW doctor_availability AS
SELECT 
    d.doctor_id,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    dept.department_name,
    s.specialization_name,
    ds.day_of_week,
    ds.start_time,
    ds.end_time,
    ds.break_start_time,
    ds.break_end_time,
    d.consultation_fee,
    d.consultation_duration_minutes
FROM doctors d
JOIN departments dept ON d.department_id = dept.department_id
JOIN specializations s ON d.specialization_id = s.specialization_id
LEFT JOIN doctor_schedules ds ON d.doctor_id = ds.doctor_id
WHERE d.is_available = TRUE 
    AND ds.is_available = TRUE
    AND (ds.effective_until IS NULL OR ds.effective_until >= CURRENT_DATE);

-- View for Pending Bills
CREATE VIEW pending_bills AS
SELECT 
    b.bill_id,
    b.bill_number,
    b.bill_date,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.phone AS patient_phone,
    b.total_amount,
    b.paid_amount,
    b.balance_amount,
    b.payment_status,
    DATEDIFF(CURRENT_DATE, b.bill_date) AS days_pending
FROM billing b
JOIN patients p ON b.patient_id = p.patient_id
WHERE b.payment_status IN ('Pending', 'Partial')
ORDER BY b.bill_date;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

DELIMITER //

-- Procedure to Book an Appointment
CREATE PROCEDURE book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_appointment_date DATE,
    IN p_appointment_time TIME,
    IN p_appointment_type VARCHAR(50),
    IN p_reason_for_visit TEXT,
    OUT p_appointment_id INT,
    OUT p_message VARCHAR(200)
)
BEGIN
    DECLARE v_appointment_end_time TIME;
    DECLARE v_consultation_duration INT;
    DECLARE v_day_of_week VARCHAR(20);
    DECLARE v_doctor_available INT DEFAULT 0;
    DECLARE v_slot_available INT DEFAULT 1;
    
    -- Get consultation duration
    SELECT consultation_duration_minutes INTO v_consultation_duration
    FROM doctors WHERE doctor_id = p_doctor_id;
    
    -- Calculate end time
    SET v_appointment_end_time = ADDTIME(p_appointment_time, SEC_TO_TIME(v_consultation_duration * 60));
    
    -- Get day of week
    SET v_day_of_week = DAYNAME(p_appointment_date);
    
    -- Check if doctor is available on that day
    SELECT COUNT(*) INTO v_doctor_available
    FROM doctor_schedules
    WHERE doctor_id = p_doctor_id
        AND day_of_week = v_day_of_week
        AND p_appointment_time >= start_time
        AND v_appointment_end_time <= end_time
        AND is_available = TRUE
        AND (effective_until IS NULL OR effective_until >= p_appointment_date);
    
    IF v_doctor_available = 0 THEN
        SET p_message = 'Doctor is not available at the selected time';
        SET p_appointment_id = NULL;
    ELSE
        -- Check if slot is already booked
        SELECT COUNT(*) INTO v_slot_available
        FROM appointments
        WHERE doctor_id = p_doctor_id
            AND appointment_date = p_appointment_date
            AND status_id NOT IN (5, 7) -- Not cancelled or rescheduled
            AND ((p_appointment_time >= appointment_time AND p_appointment_time < appointment_end_time)
                OR (v_appointment_end_time > appointment_time AND v_appointment_end_time <= appointment_end_time)
                OR (p_appointment_time <= appointment_time AND v_appointment_end_time >= appointment_end_time));
        
        IF v_slot_available > 0 THEN
            SET p_message = 'Time slot is already booked';
            SET p_appointment_id = NULL;
        ELSE
            -- Create appointment
            INSERT INTO appointments (
                appointment_code,
                patient_id,
                doctor_id,
                appointment_date,
                appointment_time,
                appointment_end_time,
                appointment_type,
                reason_for_visit,
                status_id
            ) VALUES (
                CONCAT('APT', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(FLOOR(RAND() * 10000), 4, '0')),
                p_patient_id,
                p_doctor_id,
                p_appointment_date,
                p_appointment_time,
                v_appointment_end_time,
                p_appointment_type,
                p_reason_for_visit,
                1
            );
            
            SET p_appointment_id = LAST_INSERT_ID();
            SET p_message = 'Appointment booked successfully';
        END IF;
    END IF;
END//

-- Procedure to Calculate Bill
CREATE PROCEDURE calculate_bill(
    IN p_appointment_id INT,
    OUT p_bill_id INT
)
BEGIN
    DECLARE v_patient_id INT;
    DECLARE v_doctor_id INT;
    DECLARE v_consultation_fee DECIMAL(10, 2);
    DECLARE v_medicine_charges DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_lab_charges DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_total_amount DECIMAL(10, 2);
    
    -- Get patient and doctor from appointment
    SELECT patient_id, doctor_id INTO v_patient_id, v_doctor_id
    FROM appointments WHERE appointment_id = p_appointment_id;
    
    -- Get consultation fee
    SELECT consultation_fee INTO v_consultation_fee
    FROM doctors WHERE doctor_id = v_doctor_id;
    
    -- Calculate medicine charges (if prescriptions exist)
    SELECT COALESCE(SUM(pd.quantity * m.unit_price), 0) INTO v_medicine_charges
    FROM medical_records mr
    JOIN prescriptions pr ON mr.record_id = pr.medical_record_id
    JOIN prescription_details pd ON pr.prescription_id = pd.prescription_id
    JOIN medicines m ON pd.medicine_id = m.medicine_id
    WHERE mr.appointment_id = p_appointment_id;
    
    -- Calculate lab charges
    SELECT COALESCE(SUM(lt.price), 0) INTO v_lab_charges
    FROM medical_records mr
    JOIN lab_test_orders lto ON mr.record_id = lto.medical_record_id
    JOIN lab_tests lt ON lto.test_id = lt.test_id
    WHERE mr.appointment_id = p_appointment_id;
    
    -- Calculate total
    SET v_total_amount = v_consultation_fee + v_medicine_charges + v_lab_charges;
    
    -- Insert bill
    INSERT INTO billing (
        bill_number,
        patient_id,
        appointment_id,
        consultation_fee,
        medicine_charges,
        lab_charges,
        total_amount
    ) VALUES (
        CONCAT('BILL', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD(FLOOR(RAND() * 10000), 4, '0')),
        v_patient_id,
        p_appointment_id,
        v_consultation_fee,
        v_medicine_charges,
        v_lab_charges,
        v_total_amount
    );
    
    SET p_bill_id = LAST_INSERT_ID();
END//

DELIMITER ;

-- =====================================================
-- INDEXES FOR OPTIMIZATION
-- =====================================================

-- Composite indexes for frequently joined queries
CREATE INDEX idx_appointment_lookup ON appointments(patient_id, doctor_id, appointment_date);
CREATE INDEX idx_medical_record_lookup ON medical_records(patient_id, visit_date);
CREATE INDEX idx_prescription_lookup ON prescriptions(patient_id, prescription_date);
CREATE INDEX idx_billing_lookup ON billing(patient_id, bill_date, payment_status);

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert Specializations
INSERT INTO specializations (specialization_name, specialization_code, description) VALUES
('General Medicine', 'GM', 'General medical practice and primary care'),
('Cardiology', 'CARD', 'Heart and cardiovascular system'),
('Dermatology', 'DERM', 'Skin, hair, and nail conditions'),
('Orthopedics', 'ORTH', 'Musculoskeletal system'),
('Pediatrics', 'PED', 'Medical care for infants, children, and adolescents'),
('Gynecology', 'GYN', 'Female reproductive system'),
('Neurology', 'NEURO', 'Nervous system disorders'),
('Ophthalmology', 'OPTH', 'Eye and vision care'),
('ENT', 'ENT', 'Ear, nose, and throat'),
('Psychiatry', 'PSYCH', 'Mental health and behavioral disorders');

-- Insert Departments
INSERT INTO departments (department_name, department_code, description, floor_number) VALUES
('General Medicine', 'GM', 'Primary care and general health services', 1),
('Cardiology', 'CARD', 'Heart and cardiovascular care', 2),
('Emergency', 'ER', 'Emergency and urgent care services', 1),
('Surgery', 'SURG', 'Surgical procedures and operations', 3),
('Pediatrics', 'PED', 'Child healthcare services', 2),
('Radiology', 'RAD', 'Medical imaging and diagnostics', 1),
('Laboratory', 'LAB', 'Diagnostic testing services', 1),
('Pharmacy', 'PHARM', 'Medication dispensing and management', 1);

-- Insert Membership Types (for any loyalty/discount programs)
INSERT INTO membership_types (type_name, max_books_allowed, max_days_allowed, fine_per_day, annual_fee, description) 
VALUES 
('Regular', 0, 0, 0, 0, 'Standard patient registration'),
('Silver', 0, 0, 0, 100, 'Silver membership with 5% discount'),
('Gold', 0, 0, 0, 200, 'Gold membership with 10% discount'),
('Platinum', 0, 0, 0, 500, 'Platinum membership with 15% discount');

-- Insert sample Medicines
INSERT INTO medicines (medicine_code, medicine_name, generic_name, category, manufacturer, unit_of_measure, strength, form, unit_price, stock_quantity) VALUES
('MED001', 'Paracetamol', 'Acetaminophen', 'Analgesic', 'PharmaCo', 'mg', '500mg', 'Tablet', 0.50, 1000),
('MED002', 'Amoxicillin', 'Amoxicillin', 'Antibiotic', 'MedLife', 'mg', '250mg', 'Capsule', 1.20, 500),
('MED003', 'Omeprazole', 'Omeprazole', 'Proton Pump Inhibitor', 'HealthCorp', 'mg', '20mg', 'Capsule', 2.00, 300),
('MED004', 'Metformin', 'Metformin HCl', 'Antidiabetic', 'DiabCare', 'mg', '500mg', 'Tablet', 1.50, 400),
('MED005', 'Lisinopril', 'Lisinopril', 'ACE Inhibitor', 'CardioHealth', 'mg', '10mg', 'Tablet', 1.80, 350),
('MED006', 'Salbutamol', 'Albuterol', 'Bronchodilator', 'RespiraCare', 'mcg', '100mcg', 'Inhaler', 15.00, 100),
('MED007', 'Cetirizine', 'Cetirizine HCl', 'Antihistamine', 'AllergyFree', 'mg', '10mg', 'Tablet', 0.80, 600),
('MED008', 'Ibuprofen', 'Ibuprofen', 'NSAID', 'PainRelief', 'mg', '400mg', 'Tablet', 0.75, 800),
('MED009', 'Insulin Glargine', 'Insulin Glargine', 'Insulin', 'DiabetesCare', 'units', '100U/ml', 'Injection', 45.00, 50),
('MED010', 'Hydrocortisone', 'Hydrocortisone', 'Corticosteroid', 'SkinCare', 'g', '1%', 'Cream', 8.50, 150);

-- Insert sample Lab Tests
INSERT INTO lab_tests (test_code, test_name, test_category, department, sample_type, normal_range, unit, price, turnaround_days) VALUES
('LAB001', 'Complete Blood Count', 'Hematology', 'Laboratory', 'Blood', 'WBC: 4.5-11 K/uL', 'cells/uL', 25.00, 1),
('LAB002', 'Blood Glucose Fasting', 'Chemistry', 'Laboratory', 'Blood', '70-100', 'mg/dL', 15.00, 1),
('LAB003', 'Lipid Profile', 'Chemistry', 'Laboratory', 'Blood', 'Total Cholesterol: <200', 'mg/dL', 45.00, 1),
('LAB004', 'Thyroid Function Test', 'Endocrinology', 'Laboratory', 'Blood', 'TSH: 0.4-4.0', 'mIU/L', 60.00, 2),
('LAB005', 'Liver Function Test', 'Chemistry', 'Laboratory', 'Blood', 'ALT: 7-56', 'U/L', 40.00, 1),
('LAB006', 'Kidney Function Test', 'Chemistry', 'Laboratory', 'Blood', 'Creatinine: 0.6-1.2', 'mg/dL', 35.00, 1),
('LAB007', 'Urinalysis', 'Urinalysis', 'Laboratory', 'Urine', 'pH: 4.6-8.0', 'pH', 20.00, 1),
('LAB008', 'ECG', 'Cardiology', 'Cardiology', 'None', 'Normal Sinus Rhythm', 'N/A', 30.00, 0),
('LAB009', 'Chest X-Ray', 'Radiology', 'Radiology', 'None', 'Clear lung fields', 'N/A', 50.00, 1),
('LAB010', 'HbA1c', 'Chemistry', 'Laboratory', 'Blood', '<5.7%', '%', 35.00, 1);

-- =====================================================
-- TRIGGERS
-- =====================================================

DELIMITER //

-- Trigger to update available copies when a book is borrowed
CREATE TRIGGER after_appointment_status_update
AFTER UPDATE ON appointments
FOR EACH ROW
BEGIN
    -- Log status changes
    IF NEW.status_id != OLD.status_id THEN
        INSERT INTO audit_log (
            user_type, 
            action, 
            table_name, 
            record_id, 
            old_values, 
            new_values
        ) VALUES (
            'System',
            'Appointment Status Changed',
            'appointments',
            NEW.appointment_id,
            JSON_OBJECT('status_id', OLD.status_id),
            JSON_OBJECT('status_id', NEW.status_id)
        );
    END IF;
END//

-- Trigger to validate appointment times don't overlap
CREATE TRIGGER before_appointment_insert
BEFORE INSERT ON appointments
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT;
    
    SELECT COUNT(*) INTO overlap_count
    FROM appointments
    WHERE doctor_id = NEW.doctor_id
        AND appointment_date = NEW.appointment_date
        AND status_id NOT IN (5, 7) -- Not cancelled or rescheduled
        AND ((NEW.appointment_time >= appointment_time AND NEW.appointment_time < appointment_end_time)
            OR (NEW.appointment_end_time > appointment_time AND NEW.appointment_end_time <= appointment_end_time));
    
    IF overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Appointment time conflicts with existing appointment';
    END IF;
END//

-- Trigger to generate patient code
CREATE TRIGGER before_patient_insert
BEFORE INSERT ON patients
FOR EACH ROW
BEGIN
    IF NEW.patient_code IS NULL THEN
        SET NEW.patient_code = CONCAT('PAT', DATE_FORMAT(NOW(), '%Y%m'), LPAD(FLOOR(RAND() * 100000), 5, '0'));
    END IF;
END//

-- Trigger to generate doctor code
CREATE TRIGGER before_doctor_insert
BEFORE INSERT ON doctors
FOR EACH ROW
BEGIN
    IF NEW.doctor_code IS NULL THEN
        SET NEW.doctor_code = CONCAT('DOC', DATE_FORMAT(NOW(), '%Y'), LPAD(FLOOR(RAND() * 10000), 4, '0'));
    END IF;
END//

-- Trigger to update billing status based on payment
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payment_transactions
FOR EACH ROW
BEGIN
    DECLARE total_paid DECIMAL(10, 2);
    DECLARE bill_total DECIMAL(10, 2);
    
    -- Calculate total paid for this bill
    SELECT SUM(amount) INTO total_paid
    FROM payment_transactions
    WHERE bill_id = NEW.bill_id;
    
    -- Get bill total
    SELECT total_amount INTO bill_total
    FROM billing
    WHERE bill_id = NEW.bill_id;
    
    -- Update billing status and paid amount
    UPDATE billing
    SET paid_amount = total_paid,
        payment_status = CASE
            WHEN total_paid >= bill_total THEN 'Paid'
            WHEN total_paid > 0 THEN 'Partial'
            ELSE 'Pending'
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE bill_id = NEW.bill_id;
END//

DELIMITER ;

-- =====================================================
-- FUNCTIONS
-- =====================================================

DELIMITER //

-- Function to calculate patient age
CREATE FUNCTION calculate_age(birth_date DATE) 
RETURNS INT
DETERMINISTIC
BEGIN
    RETURN TIMESTAMPDIFF(YEAR, birth_date, CURDATE());
END//

-- Function to check doctor availability
CREATE FUNCTION is_doctor_available(
    p_doctor_id INT, 
    p_date DATE, 
    p_time TIME
) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE is_available BOOLEAN DEFAULT FALSE;
    DECLARE day_name VARCHAR(20);
    DECLARE schedule_count INT;
    DECLARE appointment_count INT;
    
    SET day_name = DAYNAME(p_date);
    
    -- Check if doctor has schedule for this day
    SELECT COUNT(*) INTO schedule_count
    FROM doctor_schedules
    WHERE doctor_id = p_doctor_id
        AND day_of_week = day_name
        AND p_time >= start_time
        AND p_time < end_time
        AND is_available = TRUE
        AND (effective_until IS NULL OR effective_until >= p_date);
    
    IF schedule_count > 0 THEN
        -- Check if slot is free
        SELECT COUNT(*) INTO appointment_count
        FROM appointments
        WHERE doctor_id = p_doctor_id
            AND appointment_date = p_date
            AND p_time >= appointment_time
            AND p_time < appointment_end_time
            AND status_id NOT IN (5, 7); -- Not cancelled or rescheduled
        
        IF appointment_count = 0 THEN
            SET is_available = TRUE;
        END IF;
    END IF;
    
    RETURN is_available;
END//

-- Function to calculate outstanding balance for a patient
CREATE FUNCTION get_patient_balance(p_patient_id INT)
RETURNS DECIMAL(10, 2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_balance DECIMAL(10, 2);
    
    SELECT COALESCE(SUM(balance_amount), 0) INTO total_balance
    FROM billing
    WHERE patient_id = p_patient_id
        AND payment_status IN ('Pending', 'Partial');
    
    RETURN total_balance;
END//

DELIMITER ;

-- =====================================================
-- GRANT PERMISSIONS (Example for different user roles)
-- =====================================================

-- Create users
-- CREATE USER 'clinic_admin'@'localhost' IDENTIFIED BY 'admin_password';
-- CREATE USER 'doctor_user'@'localhost' IDENTIFIED BY 'doctor_password';
-- CREATE USER 'receptionist'@'localhost' IDENTIFIED BY 'reception_password';
-- CREATE USER 'patient_user'@'localhost' IDENTIFIED BY 'patient_password';

-- Grant permissions
-- Admin - Full access
-- GRANT ALL PRIVILEGES ON clinical_booking_system.* TO 'clinic_admin'@'localhost';

-- Doctor - Can view and update medical records, prescriptions
-- GRANT SELECT, INSERT, UPDATE ON clinical_booking_system.medical_records TO 'doctor_user'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON clinical_booking_system.prescriptions TO 'doctor_user'@'localhost';
-- GRANT SELECT ON clinical_booking_system.patients TO 'doctor_user'@'localhost';
-- GRANT SELECT, UPDATE ON clinical_booking_system.appointments TO 'doctor_user'@'localhost';

-- Receptionist - Can manage appointments and billing
-- GRANT SELECT, INSERT, UPDATE ON clinical_booking_system.appointments TO 'receptionist'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON clinical_booking_system.billing TO 'receptionist'@'localhost';
-- GRANT SELECT ON clinical_booking_system.patients TO 'receptionist'@'localhost';
-- GRANT SELECT ON clinical_booking_system.doctors TO 'receptionist'@'localhost';

-- Patient - Can view their own records
-- GRANT SELECT ON clinical_booking_system.appointments TO 'patient_user'@'localhost';
-- GRANT SELECT ON clinical_booking_system.medical_records TO 'patient_user'@'localhost';
-- GRANT SELECT ON clinical_booking_system.prescriptions TO 'patient_user'@'localhost';
-- GRANT SELECT ON clinical_booking_system.billing TO 'patient_user'@'localhost';

-- FLUSH PRIVILEGES;

-- =====================================================
-- DATABASE DOCUMENTATION
-- =====================================================

/*
CLINICAL BOOKING SYSTEM - DATABASE STRUCTURE

This database implements a comprehensive clinical management system with the following features:

1. ENTITIES AND RELATIONSHIPS:
   - Departments & Doctors (One-to-Many)
   - Doctors & Specializations (Many-to-One)
   - Doctors & Appointments (One-to-Many)
   - Patients & Appointments (One-to-Many)
   - Appointments & Medical Records (One-to-One)
   - Medical Records & Prescriptions (One-to-Many)
   - Prescriptions & Medicines (Many-to-Many via prescription_details)
   - Medical Records & Lab Test Orders (One-to-Many)
   - Appointments & Billing (One-to-One)
   - Billing & Payment Transactions (One-to-Many)

2. KEY FEATURES:
   - Complete appointment scheduling with conflict prevention
   - Medical record management with detailed patient history
   - Prescription management with medicine inventory
   - Laboratory test ordering and result tracking
   - Comprehensive billing and payment system
   - Audit logging for compliance
   - Doctor schedule management with availability checking

3. SECURITY FEATURES:
   - Password hashes for authentication
   - Role-based access control ready
   - Audit logging for all critical operations
   - Data integrity constraints

4. PERFORMANCE OPTIMIZATIONS:
   - Strategic indexes on frequently queried columns
   - Composite indexes for complex queries
   - Generated columns for calculated values
   - Views for common queries

5. BUSINESS LOGIC:
   - Stored procedures for complex operations
   - Triggers for data integrity and automation
   - Functions for common calculations

This database design follows best practices for:
- Normalization (3NF)
- Data integrity
- Security
- Performance
- Scalability
- Maintainability
*/

-- =====================================================
-- END OF CLINICAL BOOKING SYSTEM DATABASE
-- =====================================================
