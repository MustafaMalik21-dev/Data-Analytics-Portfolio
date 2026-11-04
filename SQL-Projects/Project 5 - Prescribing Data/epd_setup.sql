-- ============================================================
-- PRESCRIBING DATA PROJECT: SETUP SCRIPT
-- Database: prescribing (MySQL 8)
-- Source:   NHSBSA English Prescribing Dataset (EPD) with SNOMED
--           code, August 2026 (one month, about 17 million rows)
-- Before running:
--   1. The CSV path below points to your project folder. If you
--      move or rename the file, update the three LOAD DATA paths.
--      MySQL needs forward slashes (/) in the path; spaces are fine
--      because the path is inside quotes.
--   2. Make sure local_infile is ON (as in the earlier projects)
--   3. Check you have about 10 GB of free disk space
--   4. In Workbench, raise the query timeout first:
--      Edit > Preferences > SQL Editor > DBMS connection read
--      timeout = 3600 seconds. Or run the script from the command
--      line (no timeout), as for the query results.
-- How the load works:
--   The file is read three times, which is quicker and uses far
--   less disk space than loading every column in one go:
--     Pass 1 loads the codes and numbers for every row into the
--            prescriptions table (the large fact table).
--     Pass 2 loads practice details into practices. The practice
--            code is the primary key, so IGNORE keeps the first
--            row for each practice and discards the repeats.
--     Pass 3 does the same for drug presentations.
--   Each pass may take several minutes.
-- Line endings: the file uses Windows line endings (\r\n), so
-- each load uses LINES TERMINATED BY '\r\n'.
-- ============================================================

DROP DATABASE IF EXISTS prescribing;
CREATE DATABASE prescribing CHARACTER SET utf8mb4;
USE prescribing;

-- Column order in the file:
--  1 YEAR_MONTH  2 REGIONAL_OFFICE_NAME  3 REGIONAL_OFFICE_CODE
--  4 ICB_NAME  5 ICB_CODE  6 PCO_NAME  7 PCO_CODE
--  8 PRACTICE_NAME  9 PRACTICE_CODE  10-13 ADDRESS_1-4
-- 14 POSTCODE  15 BNF_CHEMICAL_SUBSTANCE_CODE
-- 16 BNF_CHEMICAL_SUBSTANCE  17 BNF_PRESENTATION_CODE
-- 18 BNF_PRESENTATION_NAME  19 BNF_CHAPTER_PLUS_CODE
-- 20 QUANTITY  21 ITEMS  22 TOTAL_QUANTITY  23 ADQ_USAGE
-- 24 NIC  25 ACTUAL_COST  26 UNIDENTIFIED  27 SNOMED_CODE

-- ------------------------------------------------------------
-- 1. Prescriptions (fact table: one row per practice per
--    presentation per pack size)
-- ------------------------------------------------------------
CREATE TABLE prescriptions (
    rx_id              INT AUTO_INCREMENT,
    rx_month           CHAR(7),
    practice_code      VARCHAR(10),
    presentation_code  VARCHAR(15),
    quantity           DECIMAL(14,3),
    items              INT,
    total_quantity     DECIMAL(16,3),
    adq_usage          DECIMAL(16,3),
    nic                DECIMAL(14,2),
    actual_cost        DECIMAL(14,5),
    unidentified       CHAR(1),
    snomed_code        VARCHAR(20),
    PRIMARY KEY (rx_id)
);

-- Pass 1
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 5 - Prescribing Data/EPD_SNOMED_202608.csv'
INTO TABLE prescriptions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@ym, @c2, @c3, @c4, @c5, @c6, @c7, @c8, @prac, @c10, @c11, @c12,
 @c13, @c14, @c15, @c16, @pres, @c18, @c19, @qty, @items, @tq,
 @adq, @nic, @cost, @unid, @snomed)
SET rx_month          = @ym,
    practice_code     = NULLIF(TRIM(@prac), ''),
    presentation_code = NULLIF(TRIM(@pres), ''),
    quantity          = NULLIF(TRIM(@qty), ''),
    items             = NULLIF(TRIM(@items), ''),
    total_quantity    = NULLIF(TRIM(@tq), ''),
    adq_usage         = NULLIF(TRIM(@adq), ''),
    nic               = NULLIF(TRIM(@nic), ''),
    actual_cost       = NULLIF(TRIM(@cost), ''),
    unidentified      = NULLIF(TRIM(@unid), ''),
    snomed_code       = NULLIF(TRIM(TRAILING '\r' FROM @snomed), '');

-- ------------------------------------------------------------
-- 2. Practices (one row per practice, with its sub-ICB, ICB and
--    NHS England region)
-- ------------------------------------------------------------
CREATE TABLE practices (
    practice_code   VARCHAR(10),
    practice_name   VARCHAR(150),
    postcode        VARCHAR(10),
    pco_code        VARCHAR(10),
    pco_name        VARCHAR(150),
    icb_code        VARCHAR(10),
    icb_name        VARCHAR(150),
    region_code     VARCHAR(10),
    region_name     VARCHAR(60),
    PRIMARY KEY (practice_code)
);

-- Pass 2
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 5 - Prescribing Data/EPD_SNOMED_202608.csv'
IGNORE INTO TABLE practices
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@ym, @region, @regcode, @icb, @icbcode, @pco, @pcocode, @pname,
 @prac, @c10, @c11, @c12, @c13, @pc)
SET practice_code = TRIM(@prac),
    practice_name = NULLIF(TRIM(@pname), ''),
    postcode      = NULLIF(TRIM(@pc), ''),
    pco_code      = NULLIF(TRIM(@pcocode), ''),
    pco_name      = NULLIF(TRIM(@pco), ''),
    icb_code      = NULLIF(TRIM(@icbcode), ''),
    icb_name      = NULLIF(TRIM(@icb), ''),
    region_code   = NULLIF(TRIM(@regcode), ''),
    region_name   = NULLIF(TRIM(@region), '');

-- ------------------------------------------------------------
-- 3. Presentations (one row per drug presentation, with its
--    chemical substance and BNF chapter)
-- ------------------------------------------------------------
CREATE TABLE presentations (
    presentation_code   VARCHAR(15),
    presentation_name   VARCHAR(255),
    chemical_code       VARCHAR(15),
    chemical_name       VARCHAR(150),
    bnf_chapter         VARCHAR(100),
    PRIMARY KEY (presentation_code)
);

-- Pass 3
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 5 - Prescribing Data/EPD_SNOMED_202608.csv'
IGNORE INTO TABLE presentations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@ym, @c2, @c3, @c4, @c5, @c6, @c7, @c8, @c9, @c10, @c11, @c12,
 @c13, @c14, @chemcode, @chem, @pres, @presname, @chapter)
SET presentation_code = TRIM(@pres),
    presentation_name = NULLIF(TRIM(@presname), ''),
    chemical_code     = NULLIF(TRIM(@chemcode), ''),
    chemical_name     = NULLIF(TRIM(@chem), ''),
    bnf_chapter       = NULLIF(TRIM(@chapter), '');

-- ------------------------------------------------------------
-- 4. Indexes for the joins (each takes a few minutes)
-- ------------------------------------------------------------
CREATE INDEX idx_rx_practice     ON prescriptions (practice_code);
CREATE INDEX idx_rx_presentation ON prescriptions (presentation_code);
CREATE INDEX idx_pres_chemical   ON presentations (chemical_code);
CREATE INDEX idx_prac_icb        ON practices (icb_code);

-- ------------------------------------------------------------
-- 5. Checks - send these results back
-- ------------------------------------------------------------
SELECT COUNT(*)                   AS prescription_rows,
       SUM(items)                 AS total_items,
       ROUND(SUM(actual_cost), 0) AS total_actual_cost,
       ROUND(SUM(nic), 0)         AS total_nic,
       MIN(rx_month)              AS first_month,
       MAX(rx_month)              AS last_month
FROM   prescriptions;

SELECT COUNT(*) AS practices, COUNT(DISTINCT icb_code) AS icbs,
       COUNT(DISTINCT region_code) AS regions
FROM   practices;

SELECT COUNT(*) AS presentations, COUNT(DISTINCT chemical_code) AS chemicals,
       COUNT(DISTINCT bnf_chapter) AS chapters
FROM   presentations;

SELECT region_name, COUNT(*) AS practices
FROM   practices GROUP BY region_name ORDER BY practices DESC;

-- Rows with no matching practice or presentation (should be 0)
SELECT SUM(p.practice_code IS NULL)     AS no_practice,
       SUM(pr.presentation_code IS NULL) AS no_presentation
FROM   prescriptions rx
LEFT JOIN practices     p  ON p.practice_code      = rx.practice_code
LEFT JOIN presentations pr ON pr.presentation_code = rx.presentation_code;

-- Spot check against the row you sent (K-Lite bandage, M81037)
SELECT rx.*, pr.presentation_name, p.practice_name
FROM   prescriptions rx
JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
JOIN   practices     p  ON p.practice_code      = rx.practice_code
WHERE  rx.practice_code = 'M81037'
  AND  rx.presentation_code = '20020200822';
