-- ============================================================
-- PRICE PAID PROJECT - SETUP SCRIPT
-- HM Land Registry Price Paid Data, 2025 and 2026
-- Loads both yearly files into ONE table, typed and cleaned
-- on the way in, plus two small lookup tables for the codes.
--
-- Before running:
--   1) local_infile must be on (same settings as the LFB project).
--   2) Change the two file paths in the LOAD DATA steps.
--   3) The files have NO header row, so nothing is skipped.
-- ============================================================

CREATE DATABASE IF NOT EXISTS price_paid;
USE price_paid;

-- ------------------------------------------------------------
-- MAIN TABLE: one row per residential sale
-- ------------------------------------------------------------
DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    transaction_id     VARCHAR(40)  NOT NULL,   -- unique sale reference
    price              INT UNSIGNED NOT NULL,   -- sale price in GBP
    date_of_transfer   DATE         NOT NULL,   -- completion date
    postcode           VARCHAR(10),
    property_type      CHAR(1),                 -- D, S, T, F, O (see lookup)
    old_new            CHAR(1),                 -- Y = new build, N = existing
    duration           CHAR(1),                 -- F = freehold, L = leasehold, U = unknown
    paon               VARCHAR(100),            -- house number or name
    saon               VARCHAR(100),            -- flat number etc.
    street             VARCHAR(100),
    locality           VARCHAR(100),
    town_city          VARCHAR(100),
    district           VARCHAR(100),            -- local authority district
    county             VARCHAR(100),
    ppd_category       CHAR(1),                 -- A = standard sale, B = additional (repossession, buy-to-let etc.)
    record_status      CHAR(1),                 -- A = added, C = changed, D = deleted
    PRIMARY KEY (transaction_id)
);

-- ------------------------------------------------------------
-- LOAD BOTH YEARS
-- Every field is read into a variable first, then cleaned:
--   * dates arrive as "2025-01-15 00:00" (or "15/01/2025 00:00" if
--     the file was re-saved in Excel); either way only the date is kept
--   * if the file is tab-separated, change ',' to '\t' on FIELDS
--   * blank text becomes NULL
--   * a stray Windows carriage return on the last column is removed
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/pricepaid/pp-2025.csv'
INTO TABLE sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(@id, @price, @date, @postcode, @ptype, @oldnew, @duration,
 @paon, @saon, @street, @locality, @town, @district, @county,
 @category, @status)
SET transaction_id   = @id,
    price            = @price,
    date_of_transfer = CASE WHEN @date LIKE '__/__/____%'
                            THEN STR_TO_DATE(LEFT(@date, 10), '%d/%m/%Y')
                            ELSE STR_TO_DATE(LEFT(@date, 10), '%Y-%m-%d') END,
    postcode         = NULLIF(@postcode, ''),
    property_type    = @ptype,
    old_new          = @oldnew,
    duration         = @duration,
    paon             = NULLIF(@paon, ''),
    saon             = NULLIF(@saon, ''),
    street           = NULLIF(@street, ''),
    locality         = NULLIF(@locality, ''),
    town_city        = NULLIF(@town, ''),
    district         = NULLIF(@district, ''),
    county           = NULLIF(@county, ''),
    ppd_category     = @category,
    record_status    = TRIM(TRAILING '\r' FROM @status);

SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/pricepaid/pp-2026.csv'
INTO TABLE sales
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
(@id, @price, @date, @postcode, @ptype, @oldnew, @duration,
 @paon, @saon, @street, @locality, @town, @district, @county,
 @category, @status)
SET transaction_id   = @id,
    price            = @price,
    date_of_transfer = CASE WHEN @date LIKE '__/__/____%'
                            THEN STR_TO_DATE(LEFT(@date, 10), '%d/%m/%Y')
                            ELSE STR_TO_DATE(LEFT(@date, 10), '%Y-%m-%d') END,
    postcode         = NULLIF(@postcode, ''),
    property_type    = @ptype,
    old_new          = @oldnew,
    duration         = @duration,
    paon             = NULLIF(@paon, ''),
    saon             = NULLIF(@saon, ''),
    street           = NULLIF(@street, ''),
    locality         = NULLIF(@locality, ''),
    town_city        = NULLIF(@town, ''),
    district         = NULLIF(@district, ''),
    county           = NULLIF(@county, ''),
    ppd_category     = @category,
    record_status    = TRIM(TRAILING '\r' FROM @status);

SHOW WARNINGS;

-- Indexes for the columns most queries will filter or group on
CREATE INDEX idx_sales_date     ON sales (date_of_transfer);
CREATE INDEX idx_sales_district ON sales (district);
CREATE INDEX idx_sales_type     ON sales (property_type);
CREATE INDEX idx_sales_county   ON sales (county);

-- ------------------------------------------------------------
-- LOOKUP TABLES (turn the one-letter codes into readable labels)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS property_types;
CREATE TABLE property_types (
    property_type CHAR(1) PRIMARY KEY,
    type_name     VARCHAR(30) NOT NULL
);
INSERT INTO property_types VALUES
    ('D', 'Detached'),
    ('S', 'Semi-detached'),
    ('T', 'Terraced'),
    ('F', 'Flat/Maisonette'),
    ('O', 'Other');

DROP TABLE IF EXISTS tenures;
CREATE TABLE tenures (
    duration    CHAR(1) PRIMARY KEY,
    tenure_name VARCHAR(20) NOT NULL
);
INSERT INTO tenures VALUES
    ('F', 'Freehold'),
    ('L', 'Leasehold'),
    ('U', 'Unknown');

-- ------------------------------------------------------------
-- CHECKS
-- ------------------------------------------------------------
-- Rows and date range per year
SELECT YEAR(date_of_transfer) AS sale_year,
       COUNT(*)               AS sales,
       MIN(date_of_transfer)  AS first_sale,
       MAX(date_of_transfer)  AS last_sale
FROM sales
GROUP BY YEAR(date_of_transfer)
ORDER BY sale_year;

-- Code values: each should show only the expected letters
SELECT property_type, COUNT(*) FROM sales GROUP BY property_type;
SELECT ppd_category,  COUNT(*) FROM sales GROUP BY ppd_category;
SELECT record_status, COUNT(*) FROM sales GROUP BY record_status;

-- Any dates that failed to convert (should be 0)
SELECT COUNT(*) AS bad_dates FROM sales WHERE date_of_transfer IS NULL;
