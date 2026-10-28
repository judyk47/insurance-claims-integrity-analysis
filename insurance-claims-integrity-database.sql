-- 01_build_database.sql --
-- SIMULATED DATA ONLY --

SET SQL_SAFE_UPDATES = 0;  

DROP DATABASE IF EXISTS claims_fraud_sim;
CREATE DATABASE claims_fraud_sim CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE claims_fraud_sim;

CREATE TABLE digits (d TINYINT PRIMARY KEY);
INSERT INTO digits (d) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);
CREATE TABLE numbers (n INT PRIMARY KEY);
INSERT INTO numbers (n)
SELECT a.d + 10*b.d + 100*c.d + 1000*e.d + 10000*f.d + 1
FROM digits a CROSS JOIN digits b CROSS JOIN digits c CROSS JOIN digits e CROSS JOIN digits f;
DROP TABLE digits;

-- RANDOM NUMBERS + CLAIM-TYPE PARAMETERS --
CREATE TABLE sim_rand (
  n INT PRIMARY KEY,
  u1 DOUBLE, u2 DOUBLE, u3 DOUBLE, u4 DOUBLE, u5 DOUBLE, u6 DOUBLE,
  u7 DOUBLE, u8 DOUBLE, u9 DOUBLE, u10 DOUBLE, u11 DOUBLE, u12 DOUBLE,
  u13 DOUBLE, u14 DOUBLE, u15 DOUBLE, u16 DOUBLE, u17 DOUBLE, u18 DOUBLE
);
INSERT INTO sim_rand
SELECT n,
  CAST(CONV(SUBSTRING(MD5(CONCAT('1-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('2-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('3-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('4-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('5-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('6-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('7-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('8-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('9-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('10-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('11-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('12-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('13-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('14-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('15-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('16-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('17-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0,
  CAST(CONV(SUBSTRING(MD5(CONCAT('18-',n)),1,8),16,10) AS UNSIGNED)/4294967296e0
FROM numbers WHERE n <= 40000;

-- Generator parameters --
CREATE TABLE sim_type_params (
  claim_type       VARCHAR(20) PRIMARY KEY,
  median_kes       DECIMAL(12,2) NOT NULL,
  sigma            DOUBLE NOT NULL,
  sum_insured_base DECIMAL(14,2) NOT NULL,
  premium_rate     DOUBLE NOT NULL
);
INSERT INTO sim_type_params VALUES
 ('MOTOR',         60000, 0.8,  600000, 0.04),
 ('MEDICAL',       20000, 0.9,  500000, 0.06),
 ('PROPERTY',      90000, 1.0, 3000000, 0.01),
 ('PERS_ACCIDENT', 45000, 0.8, 1000000, 0.01),
 ('LIFE',         150000, 0.7, 2000000, 0.015);

-- REFERENCE TABLES --
CREATE TABLE claim_types (
  claim_type  VARCHAR(20) PRIMARY KEY,
  description VARCHAR(60) NOT NULL
);
INSERT INTO claim_types VALUES
 ('MOTOR','Motor vehicle damage or theft'),
 ('MEDICAL','Inpatient or outpatient medical'),
 ('PROPERTY','Home or commercial property'),
 ('PERS_ACCIDENT','Personal accident'),
 ('LIFE','Life or funeral benefit');

CREATE TABLE branches (
  branch_id   INT PRIMARY KEY,
  branch_name VARCHAR(40) NOT NULL,
  county      VARCHAR(30) NOT NULL
);
INSERT INTO branches VALUES
 (1,'Nairobi CBD','Nairobi'),  (2,'Westlands','Nairobi'),
 (3,'Mombasa','Mombasa'),     (4,'Kisumu','Kisumu'),
 (5,'Nakuru','Nakuru'),       (6,'Eldoret','Uasin Gishu'),
 (7,'Thika','Kiambu'),        (8,'Nyeri','Nyeri'),
 (9,'Machakos','Machakos'),   (10,'Kisii','Kisii');

CREATE TABLE assessors (
  assessor_id   INT PRIMARY KEY,
  assessor_code VARCHAR(10) NOT NULL UNIQUE,
  branch_id     INT NOT NULL,
  hire_date     DATE NOT NULL,
  grade         VARCHAR(10) NOT NULL,
  FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
);
INSERT INTO assessors (assessor_id, assessor_code, branch_id, hire_date, grade)
SELECT n, CONCAT('A', LPAD(n,3,'0')), ((n-1) MOD 10) + 1,
       DATE_ADD('2015-01-01', INTERVAL ((n*97) MOD 3000) DAY),
       CASE WHEN n MOD 5 = 0 THEN 'SENIOR' ELSE 'STANDARD' END
FROM numbers WHERE n <= 40;

-- ILLUSTRATIVE thresholds (KES).--
CREATE TABLE approval_threshold_policy (
  claim_type       VARCHAR(20) NOT NULL,
  authority_level  VARCHAR(20) NOT NULL,
  amount_limit_kes DECIMAL(14,2) NOT NULL,
  is_illustrative  TINYINT NOT NULL DEFAULT 1,
  PRIMARY KEY (claim_type, authority_level),
  FOREIGN KEY (claim_type) REFERENCES claim_types(claim_type)
);
INSERT INTO approval_threshold_policy (claim_type, authority_level, amount_limit_kes) VALUES
 ('MOTOR','ASSESSOR',100000),         ('MOTOR','MANAGER',500000),
 ('MEDICAL','ASSESSOR',50000),        ('MEDICAL','MANAGER',250000),
 ('PROPERTY','ASSESSOR',150000),      ('PROPERTY','MANAGER',1000000),
 ('PERS_ACCIDENT','ASSESSOR',100000), ('PERS_ACCIDENT','MANAGER',500000),
 ('LIFE','ASSESSOR',250000),          ('LIFE','MANAGER',2000000);

-- Documents every claim type should have (ILLUSTRATIVE requirements) --
CREATE TABLE required_documents (
  claim_type VARCHAR(20) NOT NULL,
  doc_seq    TINYINT NOT NULL,
  doc_type   VARCHAR(30) NOT NULL,
  PRIMARY KEY (claim_type, doc_seq),
  FOREIGN KEY (claim_type) REFERENCES claim_types(claim_type)
);
INSERT INTO required_documents VALUES
 ('MOTOR',1,'CLAIM_FORM'),('MOTOR',2,'POLICE_ABSTRACT'),('MOTOR',3,'ASSESSMENT_REPORT'),
 ('MEDICAL',1,'CLAIM_FORM'),('MEDICAL',2,'INVOICE'),('MEDICAL',3,'DISCHARGE_SUMMARY'),
 ('PROPERTY',1,'CLAIM_FORM'),('PROPERTY',2,'PHOTOS'),('PROPERTY',3,'LOSS_ADJUSTER_REPORT'),
 ('PERS_ACCIDENT',1,'CLAIM_FORM'),('PERS_ACCIDENT',2,'MEDICAL_REPORT'),('PERS_ACCIDENT',3,'POLICE_ABSTRACT'),
 ('LIFE',1,'CLAIM_FORM'),('LIFE',2,'DEATH_CERTIFICATE'),('LIFE',3,'BENEFICIARY_ID');

-- CUSTOMERS AND IDENTIFIERS --
CREATE TABLE sim_truth_customer (
  customer_id       INT PRIMARY KEY,
  household_head_id INT NOT NULL,
  is_ring           TINYINT NOT NULL,
  ring_id           INT NULL,
  is_family         TINYINT NOT NULL,
  is_apartment      TINYINT NOT NULL,
  is_joint_account  TINYINT NOT NULL
);
INSERT INTO sim_truth_customer
SELECT n,
       CASE WHEN n MOD 40 = 2 THEN n-1 WHEN n MOD 80 = 3 THEN n-2 ELSE n END,
       (n MOD 200 = 11),
       CASE WHEN n MOD 200 = 11 THEN (((n-11) DIV 200) MOD 15) + 1 END,
       (n MOD 40 IN (1,2) OR n MOD 80 = 3),
       (n MOD 50 = 7),
       (n MOD 120 = 2)
FROM numbers WHERE n <= 20000;

CREATE TABLE customers (
  customer_id     INT PRIMARY KEY,
  customer_ref    VARCHAR(10) NOT NULL UNIQUE,
  home_county     VARCHAR(30) NOT NULL,
  registered_date DATE NOT NULL,
  segment         VARCHAR(10) NOT NULL
);
INSERT INTO customers (customer_id, customer_ref, home_county, registered_date, segment)
SELECT t.customer_id, CONCAT('C', LPAD(t.customer_id, 6, '0')), b.county,
       DATE_ADD('2018-01-01', INTERVAL ((t.customer_id * 131) MOD 2400) DAY),
       CASE WHEN t.customer_id MOD 12 = 0 THEN 'SME' ELSE 'RETAIL' END
FROM sim_truth_customer t
JOIN branches b ON b.branch_id = ((t.household_head_id * 7) MOD 10) + 1;

-- RAW identifiers --
CREATE TABLE customer_identifiers (
  identifier_id   INT AUTO_INCREMENT PRIMARY KEY,
  customer_id     INT NOT NULL,
  identifier_type VARCHAR(15) NOT NULL,
  identifier_raw  VARCHAR(120) NOT NULL,
  UNIQUE KEY uq_cust_type (customer_id, identifier_type),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

INSERT INTO customer_identifiers (customer_id, identifier_type, identifier_raw)   -- PHONES
SELECT customer_id, 'PHONE',
  CASE
    WHEN customer_id MOD 101 = 5 AND is_ring = 0 AND is_family = 0 THEN '0000000000'
    WHEN customer_id MOD 4 = 0 THEN CONCAT('0', digits)
    WHEN customer_id MOD 4 = 1 THEN CONCAT('+254', digits)
    WHEN customer_id MOD 4 = 2 THEN CONCAT('254', digits)
    ELSE CONCAT('0', SUBSTRING(digits,1,3), ' ', SUBSTRING(digits,4,3), ' ', SUBSTRING(digits,7,3))
  END
FROM (
  SELECT customer_id, is_ring, is_family,
         CAST(CASE WHEN is_ring = 1 AND ring_id MOD 2 = 0 THEN 799000000 + ring_id
                   ELSE 700000000 + household_head_id * 13 END AS CHAR) AS digits
  FROM sim_truth_customer
) p
WHERE NOT (customer_id MOD 37 = 0 AND is_ring = 0 AND is_family = 0);

INSERT INTO customer_identifiers (customer_id, identifier_type, identifier_raw)   -- BANK ACCOUNTS
SELECT customer_id, 'BANK_ACCOUNT',
  CASE customer_id MOD 3
    WHEN 0 THEN CONCAT(bank, '-', acct)
    WHEN 1 THEN CONCAT(LOWER(bank), ' ', acct)
    ELSE CONCAT(bank, acct)
  END
FROM (
  SELECT customer_id, is_ring, is_family,
         CASE WHEN is_ring = 1 THEN 'EQUITY'
              ELSE ELT(((CASE WHEN is_joint_account = 1 THEN household_head_id ELSE customer_id END) MOD 5) + 1,
                       'KCB','EQUITY','COOP','ABSA','NCBA') END AS bank,
         CASE WHEN is_ring = 1 THEN CAST(9000000000 + ring_id AS CHAR)
              ELSE CAST(1000000000 + (CASE WHEN is_joint_account = 1 THEN household_head_id ELSE customer_id END) * 7 AS CHAR)
         END AS acct
  FROM sim_truth_customer
) b
WHERE NOT (customer_id MOD 53 = 0 AND is_ring = 0 AND is_family = 0);

INSERT INTO customer_identifiers (customer_id, identifier_type, identifier_raw)   -- ADDRESSES
SELECT customer_id, 'ADDRESS',
  CASE WHEN customer_id MOD 9 = 0 THEN CONCAT(addr, ' ') ELSE addr END
FROM (
  SELECT customer_id,
         CASE WHEN customer_id MOD 5 = 0 THEN UPPER(base) ELSE base END AS addr
  FROM (
    SELECT t.customer_id,
      CASE WHEN t.is_apartment = 1 THEN CONCAT('Sunrise Apartments, ', c.home_county)
           ELSE CONCAT('Plot ', t.household_head_id, ', ',
                       ELT((t.household_head_id MOD 6) + 1,
                           'Kenyatta Ave','Moi Rd','Ngong Rd','Uhuru Hwy','Mama Ngina St','Lenana Rd'),
                       ', ', c.home_county)
      END AS base
    FROM sim_truth_customer t
    JOIN customers c ON c.customer_id = t.customer_id
  ) z
) y;

-- POLICIES (30,000: customers 1-10,000 hold two) --
CREATE TABLE policies (
  policy_id          INT PRIMARY KEY,
  customer_id        INT NOT NULL,
  product_type       VARCHAR(20) NOT NULL,
  branch_id          INT NOT NULL,
  inception_date     DATE NOT NULL,
  sum_insured_kes    DECIMAL(14,2) NOT NULL,
  annual_premium_kes DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (customer_id)  REFERENCES customers(customer_id),
  FOREIGN KEY (product_type) REFERENCES claim_types(claim_type),
  FOREIGN KEY (branch_id)    REFERENCES branches(branch_id)
);
INSERT INTO policies (policy_id, customer_id, product_type, branch_id, inception_date, sum_insured_kes, annual_premium_kes)
SELECT d.policy_id, d.customer_id, d.product_type, d.branch_id, d.inception_date,
       ROUND(tp.sum_insured_base * (1 + MOD(d.policy_id*37,100)/100), -3),
       ROUND(tp.sum_insured_base * (1 + MOD(d.policy_id*37,100)/100) * tp.premium_rate, -1)
FROM (
  SELECT nm.n AS policy_id, t.customer_id,
         ((t.household_head_id * 7) MOD 10) + 1 AS branch_id,
         -- Mombasa (branch 3) is deliberately property-heavy: a legitimate mix effect
         CASE WHEN ((t.household_head_id * 7) MOD 10) + 1 = 3 AND nm.n MOD 3 = 0 THEN 'PROPERTY'
              ELSE ELT(((nm.n + nm.n DIV 20000) MOD 5) + 1,'MOTOR','MEDICAL','PROPERTY','PERS_ACCIDENT','LIFE')
         END AS product_type,
         DATE_ADD(DATE '2021-01-01', INTERVAL MOD(nm.n*53,1200) DAY) AS inception_date
  FROM numbers nm
  JOIN sim_truth_customer t ON t.customer_id = ((nm.n - 1) MOD 20000) + 1
  WHERE nm.n <= 30000
) d
JOIN sim_type_params tp ON tp.claim_type = d.product_type;

-- CLAIMS --
CREATE TABLE claims (
  claim_id            INT PRIMARY KEY,
  claim_ref           VARCHAR(12) NOT NULL UNIQUE,
  policy_id           INT NOT NULL,
  customer_id         INT NOT NULL,
  claim_type          VARCHAR(20) NOT NULL,
  loss_date           DATE NOT NULL,
  reported_date       DATE NOT NULL,
  claim_amount_kes    DECIMAL(14,2) NOT NULL,
  branch_id           INT NOT NULL,
  assessor_id         INT NULL,
  status              VARCHAR(12) NOT NULL,
  decision_date       DATE NULL,
  approved_amount_kes DECIMAL(14,2) NULL,
  approval_level      VARCHAR(12) NULL,
  FOREIGN KEY (policy_id)   REFERENCES policies(policy_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (claim_type)  REFERENCES claim_types(claim_type),
  FOREIGN KEY (branch_id)   REFERENCES branches(branch_id),
  FOREIGN KEY (assessor_id) REFERENCES assessors(assessor_id)
);

-- 6a. Baseline claims --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT q.n, CONCAT('CLM', LPAD(q.n,7,'0')), q.policy_id, q.customer_id, q.product_type, q.loss_dt,
       LEAST(DATE '2025-12-31', DATE_ADD(q.loss_dt, INTERVAL CAST(FLOOR(q.u3*q.u3*45) AS SIGNED) DAY)),
       GREATEST(1000, LEAST(q.sum_insured_kes,
            ROUND(q.median_kes * EXP(q.sigma * (q.u4+q.u5+q.u6+q.u7-2) * 1.7320508), -2))),
       q.branch_id,
       q.branch_id + 10 * CASE WHEN q.u8 < 0.4 THEN 0 WHEN q.u8 < 0.7 THEN 1 WHEN q.u8 < 0.9 THEN 2 ELSE 3 END,
       'PENDING'
FROM (
  SELECT nm.n, p.policy_id, p.customer_id, p.product_type, p.branch_id, p.sum_insured_kes,
         tp.median_kes, tp.sigma, r.u3, r.u4, r.u5, r.u6, r.u7, r.u8,
         DATE_ADD(p.inception_date,
                  INTERVAL CAST(FLOOR(r.u2 * DATEDIFF(DATE '2025-12-31', p.inception_date)) AS SIGNED) DAY) AS loss_dt
  FROM numbers nm
  JOIN sim_rand r ON r.n = nm.n
  JOIN policies p ON p.policy_id = CAST(FLOOR(r.u1 * 30000) AS UNSIGNED) + 1
  JOIN sim_type_params tp ON tp.claim_type = p.product_type
  WHERE nm.n <= 36000
) q;

-- Repeat-claim bursts 36001..36300 (60 customers x 5 claims soon after inception) --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT q.n, CONCAT('CLM', LPAD(q.n,7,'0')), q.policy_id, q.customer_id, q.product_type, q.loss_dt,
       LEAST(DATE '2025-12-31', DATE_ADD(q.loss_dt, INTERVAL CAST(FLOOR(q.u3*q.u3*45) AS SIGNED) DAY)),
       GREATEST(1000, LEAST(q.sum_insured_kes,
            ROUND(q.median_kes * 0.7 * EXP(q.sigma * (q.u4+q.u5+q.u6+q.u7-2) * 1.7320508), -2))),
       q.branch_id,
       q.branch_id + 10 * CASE WHEN q.u8 < 0.4 THEN 0 WHEN q.u8 < 0.7 THEN 1 WHEN q.u8 < 0.9 THEN 2 ELSE 3 END,
       'PENDING'
FROM (
  SELECT nm.n, p.policy_id, p.customer_id, p.product_type, p.branch_id, p.sum_insured_kes,
         tp.median_kes, tp.sigma, r.u3, r.u4, r.u5, r.u6, r.u7, r.u8,
         DATE_ADD(p.inception_date,
                  INTERVAL (20 + ((nm.n - 36001) DIV 60) * 11 + CAST(FLOOR(r.u2 * 5) AS SIGNED)) DAY) AS loss_dt
  FROM numbers nm
  JOIN sim_rand r ON r.n = nm.n
  JOIN policies p ON p.policy_id = (((nm.n - 36001) MOD 60) + 1) * 331
  JOIN sim_type_params tp ON tp.claim_type = p.product_type
  WHERE nm.n BETWEEN 36001 AND 36300
) q;

-- Just-below-limit splitting 36301..36420 (40 customers x 3 claims at 93-99.5% of assessor limit) --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT q.n, CONCAT('CLM', LPAD(q.n,7,'0')), q.policy_id, q.customer_id, q.product_type, q.loss_dt,
       LEAST(DATE '2025-12-31', DATE_ADD(q.loss_dt, INTERVAL CAST(FLOOR(q.u3*q.u3*45) AS SIGNED) DAY)),
       ROUND(q.assessor_limit * (0.93 + 0.065 * q.u5), -2),
       q.branch_id,
       q.branch_id + 10 * CASE WHEN q.u8 < 0.4 THEN 0 WHEN q.u8 < 0.7 THEN 1 WHEN q.u8 < 0.9 THEN 2 ELSE 3 END,
       'PENDING'
FROM (
  SELECT nm.n, p.policy_id, p.customer_id, p.product_type, p.branch_id, ta.amount_limit_kes AS assessor_limit,
         r.u3, r.u5, r.u8,
         DATE_ADD(p.inception_date,
                  INTERVAL (200 + (((nm.n - 36301) MOD 40) + 1) * 5 + ((nm.n - 36301) DIV 40) * 9
                            + CAST(FLOOR(r.u2 * 3) AS SIGNED)) DAY) AS loss_dt
  FROM numbers nm
  JOIN sim_rand r ON r.n = nm.n
  JOIN policies p ON p.policy_id = (((nm.n - 36301) MOD 40) + 1) * 463
  JOIN approval_threshold_policy ta ON ta.claim_type = p.product_type AND ta.authority_level = 'ASSESSOR'
  WHERE nm.n BETWEEN 36301 AND 36420
) q;

-- Ring-member claims 36421..36620 (100 ring members x 2 claims, each ring inside a ~5-week window) --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT q.n, CONCAT('CLM', LPAD(q.n,7,'0')), q.policy_id, q.customer_id, q.product_type, q.loss_dt,
       LEAST(DATE '2025-12-31', DATE_ADD(q.loss_dt, INTERVAL CAST(FLOOR(q.u3*q.u3*45) AS SIGNED) DAY)),
       GREATEST(1000, LEAST(q.sum_insured_kes,
            ROUND(q.median_kes * 2.5 * EXP(q.sigma * (q.u4+q.u5+q.u6+q.u7-2) * 1.7320508), -2))),
       q.branch_id,
       q.branch_id + 10 * CASE WHEN q.u8 < 0.4 THEN 0 WHEN q.u8 < 0.7 THEN 1 WHEN q.u8 < 0.9 THEN 2 ELSE 3 END,
       'PENDING'
FROM (
  SELECT nm.n, p.policy_id, p.customer_id, p.product_type, p.branch_id, p.sum_insured_kes,
         tp.median_kes, tp.sigma, r.u3, r.u4, r.u5, r.u6, r.u7, r.u8,
         DATE_ADD(DATE '2024-06-01',
                  INTERVAL ((((nm.n - 36421) DIV 2) MOD 15 + 1) * 25 + ((nm.n - 36421) MOD 2) * 8
                            + CAST(FLOOR(r.u2 * 12) AS SIGNED)) DAY) AS loss_dt
  FROM numbers nm
  JOIN sim_rand r ON r.n = nm.n
  JOIN policies p ON p.policy_id = 11 + 200 * ((nm.n - 36421) DIV 2)
  JOIN sim_type_params tp ON tp.claim_type = p.product_type
  WHERE nm.n BETWEEN 36421 AND 36620
) q;

-- Legitimate family claims 36621..36820 (100 household pairs claiming within a day of each other) --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT q.n, CONCAT('CLM', LPAD(q.n,7,'0')), q.policy_id, q.customer_id, q.product_type, q.loss_dt,
       LEAST(DATE '2025-12-31', DATE_ADD(q.loss_dt, INTERVAL CAST(FLOOR(q.u3*q.u3*45) AS SIGNED) DAY)),
       GREATEST(1000, LEAST(q.sum_insured_kes,
            ROUND(q.median_kes * EXP(q.sigma * (q.u4+q.u5+q.u6+q.u7-2) * 1.7320508), -2))),
       q.branch_id,
       q.branch_id + 10 * CASE WHEN q.u8 < 0.4 THEN 0 WHEN q.u8 < 0.7 THEN 1 WHEN q.u8 < 0.9 THEN 2 ELSE 3 END,
       'PENDING'
FROM (
  SELECT nm.n, p.policy_id, p.customer_id, p.product_type, p.branch_id, p.sum_insured_kes,
         tp.median_kes, tp.sigma, r.u3, r.u4, r.u5, r.u6, r.u7, r.u8,
         DATE_ADD(DATE '2024-05-01',
                  INTERVAL (((nm.n - 36621) DIV 2) * 6 + ((nm.n - 36621) MOD 2)) DAY) AS loss_dt
  FROM numbers nm
  JOIN sim_rand r ON r.n = nm.n
  JOIN policies p ON p.policy_id = 1 + 40 * ((nm.n - 36621) DIV 2) + ((nm.n - 36621) MOD 2)
  JOIN sim_type_params tp ON tp.claim_type = p.product_type
  WHERE nm.n BETWEEN 36621 AND 36820
) q;

--  ANSWER KEY FOR CLAIMS --
CREATE TABLE sim_truth_claim (
  claim_id             INT PRIMARY KEY,
  is_inflated          TINYINT NOT NULL DEFAULT 0,
  is_serial_burst      TINYINT NOT NULL DEFAULT 0,
  is_split_below_limit TINYINT NOT NULL DEFAULT 0,
  is_threshold_gamer   TINYINT NOT NULL DEFAULT 0,
  is_ring_claim        TINYINT NOT NULL DEFAULT 0,
  is_family_claim      TINYINT NOT NULL DEFAULT 0,
  is_duplicate_of      INT NULL,
  is_lenient_assessor  TINYINT NOT NULL DEFAULT 0,
  has_doc_issue        TINYINT NOT NULL DEFAULT 0,
  has_failed_check     TINYINT NOT NULL DEFAULT 0,
  skipped_check        TINYINT NOT NULL DEFAULT 0,
  paid_despite_issues  TINYINT NOT NULL DEFAULT 0
);
INSERT INTO sim_truth_claim (claim_id) SELECT claim_id FROM claims;

UPDATE sim_truth_claim t
JOIN claims c ON c.claim_id = t.claim_id
SET t.is_serial_burst      = (c.claim_id BETWEEN 36001 AND 36300),
    t.is_split_below_limit = (c.claim_id BETWEEN 36301 AND 36420),
    t.is_ring_claim        = (c.claim_id BETWEEN 36421 AND 36620),
    t.is_family_claim      = (c.claim_id BETWEEN 36621 AND 36820),
    t.is_threshold_gamer   = (c.claim_id <= 36000 AND c.assessor_id IN (7,18,29) AND c.claim_id MOD 4 = 0),
    t.is_inflated          = (c.claim_id <= 36000
                              AND NOT (c.assessor_id IN (7,18,29) AND c.claim_id MOD 4 = 0)
                              AND (c.claim_id MOD 200 = 77
                                   OR (c.claim_type = 'PERS_ACCIDENT' AND c.claim_id MOD 50 = 4)));

-- Inflated amounts (4-6x), capped at the sum insured
UPDATE claims c
JOIN sim_truth_claim t ON t.claim_id = c.claim_id
JOIN policies p ON p.policy_id = c.policy_id
JOIN sim_rand r ON r.n = c.claim_id
SET c.claim_amount_kes = LEAST(p.sum_insured_kes, ROUND(c.claim_amount_kes * (4 + 2 * r.u10), -2))
WHERE t.is_inflated = 1;

-- Threshold gaming: three assessors push a quarter of their claims to 94-99.5% of their own limit --
UPDATE claims c
JOIN sim_truth_claim t ON t.claim_id = c.claim_id
JOIN approval_threshold_policy ta ON ta.claim_type = c.claim_type AND ta.authority_level = 'ASSESSOR'
JOIN sim_rand r ON r.n = c.claim_id
SET c.claim_amount_kes = ROUND(ta.amount_limit_kes * (0.94 + 0.055 * r.u10), -2)
WHERE t.is_threshold_gamer = 1;

-- 6f. Duplicate submissions 36821..36920 (copies of earlier claims, filed 3 days later) --
INSERT INTO claims (claim_id, claim_ref, policy_id, customer_id, claim_type, loss_date, reported_date,
                    claim_amount_kes, branch_id, assessor_id, status)
SELECT nm.n, CONCAT('CLM', LPAD(nm.n,7,'0')), c.policy_id, c.customer_id, c.claim_type, c.loss_date,
       LEAST(DATE '2025-12-31', DATE_ADD(c.reported_date, INTERVAL 3 DAY)),
       c.claim_amount_kes, c.branch_id, c.assessor_id, 'PENDING'
FROM numbers nm
JOIN claims c ON c.claim_id = (nm.n - 36820) * 300
WHERE nm.n BETWEEN 36821 AND 36920;

INSERT INTO sim_truth_claim (claim_id, is_duplicate_of)
SELECT claim_id, (claim_id - 36820) * 300 FROM claims WHERE claim_id > 36820;

-- DECISIONS --
-- (a) status: claims reported in the last month are still pending; two assessors reject far less --
UPDATE claims c
JOIN sim_rand r ON r.n = c.claim_id
SET c.status = CASE
      WHEN c.reported_date > '2025-11-30' THEN 'PENDING'
      WHEN r.u9 < CASE WHEN c.assessor_id IN (13,26) THEN 0.03 ELSE 0.12 END THEN 'REJECTED'
      ELSE 'APPROVED' END;

-- (b) decision date and approved amount (the same two assessors approve nearly the full amount) --
UPDATE claims c
JOIN sim_rand r ON r.n = c.claim_id
SET c.decision_date = CASE WHEN c.status = 'PENDING' THEN NULL
        ELSE LEAST(DATE '2025-12-31',
                   DATE_ADD(c.reported_date, INTERVAL (1 + CAST(FLOOR(r.u11 * 20) AS SIGNED)) DAY)) END,
    c.approved_amount_kes = CASE WHEN c.status = 'APPROVED'
        THEN ROUND(c.claim_amount_kes * CASE WHEN c.assessor_id IN (13,26) THEN 0.97 + 0.03 * r.u12
                                             ELSE 0.80 + 0.17 * r.u12 END, -2)
        ELSE NULL END;

-- (c) who signed off: above the assessor limit a manager/executive should sign;
--     assessors 13 and 26 sometimes sign anyway, and ~1% of others do too (noise)
UPDATE claims c
JOIN approval_threshold_policy ta ON ta.claim_type = c.claim_type AND ta.authority_level = 'ASSESSOR'
JOIN approval_threshold_policy tm ON tm.claim_type = c.claim_type AND tm.authority_level = 'MANAGER'
JOIN sim_rand r ON r.n = c.claim_id
SET c.approval_level = CASE
      WHEN c.status <> 'APPROVED' THEN NULL
      WHEN c.approved_amount_kes <= ta.amount_limit_kes THEN 'ASSESSOR'
      WHEN (c.assessor_id IN (13,26) AND r.u17 < 0.40) OR r.u17 > 0.99 THEN 'ASSESSOR'
      WHEN c.approved_amount_kes <= tm.amount_limit_kes THEN 'MANAGER'
      ELSE 'EXECUTIVE' END;

-- (d) documentation / verification problems 
UPDATE sim_truth_claim t
JOIN claims c ON c.claim_id = t.claim_id
JOIN sim_rand r ON r.n = t.claim_id
SET t.is_lenient_assessor = (c.assessor_id IN (13,26)),
    t.has_doc_issue = CASE c.status
        WHEN 'REJECTED' THEN r.u15 < 0.30
        WHEN 'PENDING'  THEN r.u15 < 0.35
        ELSE r.u15 < CASE WHEN c.assessor_id IN (13,26) THEN 0.15
                          WHEN c.decision_date BETWEEN '2024-10-01' AND '2024-12-31' THEN 0.06
                          ELSE 0.01 END END,
    t.has_failed_check = CASE c.status
        WHEN 'REJECTED' THEN r.u16 < 0.35
        WHEN 'PENDING'  THEN r.u16 < 0.05
        ELSE r.u16 < CASE WHEN c.assessor_id IN (13,26) THEN 0.08 ELSE 0.005 END END,
    t.skipped_check = (r.u15 > 0.97)
        OR ((t.is_threshold_gamer = 1 OR t.is_split_below_limit = 1) AND r.u16 > 0.40);

-- DOCUMENTS, VERIFICATION CHECKS, PAYMENTS --
-- A required document with NO row here = "not recorded" (data gap) --
CREATE TABLE claim_documents (
  doc_id        INT AUTO_INCREMENT PRIMARY KEY,
  claim_id      INT NOT NULL,
  doc_type      VARCHAR(30) NOT NULL,
  doc_status    VARCHAR(12) NOT NULL,
  received_date DATE NULL,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);
INSERT INTO claim_documents (claim_id, doc_type, doc_status, received_date)
SELECT c.claim_id, d.doc_type,
       CASE WHEN t.has_doc_issue = 1 AND d.doc_seq = 2 THEN 'OUTSTANDING' ELSE 'RECEIVED' END,
       CASE WHEN t.has_doc_issue = 1 AND d.doc_seq = 2 THEN NULL
            ELSE DATE_ADD(c.reported_date, INTERVAL (d.doc_seq + CAST(FLOOR(r.u10 * 5) AS SIGNED)) DAY) END
FROM claims c
JOIN sim_truth_claim t ON t.claim_id = c.claim_id
JOIN required_documents d ON d.claim_type = c.claim_type
JOIN sim_rand r ON r.n = c.claim_id
WHERE NOT (t.has_doc_issue = 0 AND MOD(c.claim_id * 7 + d.doc_seq, 61) = 0);

-- check_result: PASSED / FAILED (confirmed failure) / NOT_PERFORMED (information missing, not a failure)
CREATE TABLE verification_checks (
  check_id     INT AUTO_INCREMENT PRIMARY KEY,
  claim_id     INT NOT NULL,
  check_type   VARCHAR(20) NOT NULL,
  check_result VARCHAR(15) NOT NULL,
  check_date   DATE NULL,
  UNIQUE KEY uq_claim_check (claim_id, check_type),
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);
INSERT INTO verification_checks (claim_id, check_type, check_result, check_date)
SELECT c.claim_id, k.check_type,
       CASE WHEN t.has_failed_check = 1 AND k.seq = (c.claim_id MOD 3) + 1 THEN 'FAILED'
            WHEN t.skipped_check = 1 AND k.seq = 3 THEN 'NOT_PERFORMED'
            ELSE 'PASSED' END,
       CASE WHEN NOT (t.has_failed_check = 1 AND k.seq = (c.claim_id MOD 3) + 1)
                 AND t.skipped_check = 1 AND k.seq = 3 THEN NULL
            ELSE DATE_ADD(c.reported_date, INTERVAL k.seq DAY) END
FROM claims c
JOIN sim_truth_claim t ON t.claim_id = c.claim_id
CROSS JOIN (SELECT 1 AS seq, 'IDENTITY' AS check_type
            UNION ALL SELECT 2, 'POLICY_COVERAGE'
            UNION ALL SELECT 3, 'LOSS_VERIFICATION') k;

-- Payments: not every approved claim is paid yet; ~8% are paid in two instalments;
-- a few are overpaid by 8% (reconciliation trap)
CREATE TABLE payments (
  payment_id      INT AUTO_INCREMENT PRIMARY KEY,
  claim_id        INT NOT NULL,
  payment_date    DATE NOT NULL,
  paid_amount_kes DECIMAL(14,2) NOT NULL,
  payment_method  VARCHAR(15) NOT NULL,
  FOREIGN KEY (claim_id) REFERENCES claims(claim_id)
);
INSERT INTO payments (claim_id, payment_date, paid_amount_kes, payment_method)
SELECT c.claim_id,
       DATE_ADD(c.decision_date, INTERVAL (s.seq * 7 + 2 + CAST(FLOOR(r.u11 * 10) AS SIGNED)) DAY),
       ROUND(c.approved_amount_kes
             * CASE WHEN r.u14 < 0.08 THEN (CASE s.seq WHEN 1 THEN 0.6 ELSE 0.4 END) ELSE 1 END
             * CASE WHEN c.claim_id MOD 301 = 9 THEN 1.08 ELSE 1 END, 2),
       CASE WHEN c.approved_amount_kes > 150000 THEN ELT(MOD(c.claim_id,2) + 1, 'BANK_TRANSFER', 'CHEQUE')
            ELSE ELT(MOD(c.claim_id,3) + 1, 'MPESA', 'BANK_TRANSFER', 'MPESA') END
FROM claims c
JOIN sim_rand r ON r.n = c.claim_id
JOIN (SELECT 1 AS seq UNION ALL SELECT 2) s
WHERE c.status = 'APPROVED'
  AND r.u13 >= 0.03
  AND c.decision_date <= '2025-12-10'
  AND (s.seq = 1 OR r.u14 < 0.08);

UPDATE sim_truth_claim t
SET t.paid_despite_issues = 1
WHERE (t.has_doc_issue = 1 OR t.has_failed_check = 1)
  AND EXISTS (SELECT 1 FROM payments p WHERE p.claim_id = t.claim_id);

-- DATA-QUALITY DIRT --
UPDATE claims SET reported_date = DATE_SUB(loss_date, INTERVAL 3 DAY)
WHERE claim_id <= 36000 AND claim_id MOD 1200 = 5;                -- reported before loss
UPDATE claims SET status = 'Approved'
WHERE status = 'APPROVED' AND claim_id MOD 700 = 3;               -- inconsistent label casing
UPDATE claims SET assessor_id = NULL
WHERE claim_id <= 36000 AND claim_id MOD 900 = 7;                 -- missing assessor

--  BUILD VALIDATION --
SELECT 'branches' AS tbl, COUNT(*) AS n FROM branches
UNION ALL SELECT 'assessors', COUNT(*) FROM assessors
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'customer_identifiers', COUNT(*) FROM customer_identifiers
UNION ALL SELECT 'policies', COUNT(*) FROM policies
UNION ALL SELECT 'claims', COUNT(*) FROM claims
UNION ALL SELECT 'claim_documents', COUNT(*) FROM claim_documents
UNION ALL SELECT 'verification_checks', COUNT(*) FROM verification_checks
UNION ALL SELECT 'payments', COUNT(*) FROM payments;

SELECT status, COUNT(*) AS claims, ROUND(SUM(claim_amount_kes)) AS claimed_kes
FROM claims GROUP BY status ORDER BY claims DESC;

SELECT (SELECT SUM(claim_amount_kes)    FROM claims)   AS total_claimed_kes,
       (SELECT SUM(approved_amount_kes) FROM claims)   AS total_approved_kes,
       (SELECT SUM(paid_amount_kes)     FROM payments) AS total_paid_kes;

SELECT MIN(loss_date) AS min_loss, MAX(loss_date) AS max_loss,
       MIN(reported_date) AS min_reported, MAX(reported_date) AS max_reported,
       SUM(reported_date < loss_date) AS reported_before_loss,
       SUM(assessor_id IS NULL) AS missing_assessor
FROM claims;

SELECT COUNT(*) AS loss_before_inception
FROM claims c JOIN policies p ON p.policy_id = c.policy_id
WHERE c.loss_date < p.inception_date;

-- Build check on the generator only (do not use to tune detection rules)
SELECT SUM(is_serial_burst) AS serial, SUM(is_split_below_limit) AS split_claims,
       SUM(is_ring_claim) AS ring, SUM(is_family_claim) AS family,
       SUM(is_duplicate_of IS NOT NULL) AS duplicates
FROM sim_truth_claim;