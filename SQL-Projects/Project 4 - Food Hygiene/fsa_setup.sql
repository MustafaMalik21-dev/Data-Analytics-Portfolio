-- ============================================================
-- FOOD HYGIENE RATINGS PROJECT: SETUP SCRIPT
-- Database: food_hygiene (MySQL 8)
-- Source:   Food Standards Agency, Food Hygiene Rating Scheme
--           open data, all local authorities (English CSV)
-- Before running:
--   1. Put the CSV in C:/fsa/ and rename it fhrs.csv
--   2. Make sure local_infile is ON (as in the earlier projects)
-- Notes:
--   * RatingValue holds 0-5 for the FHRS scheme (England, Wales,
--     Northern Ireland) and text values for Scotland's FHIS
--     scheme and for unrated businesses (Exempt, Awaiting
--     Inspection, etc.). rating_num keeps the 0-5 scores as a
--     number and is NULL otherwise.
--   * Hygiene, Structural and ConfidenceInManagement are the
--     inspection sub-scores. They are penalty points, so LOWER
--     IS BETTER. They are blank for FHIS and for unrated
--     businesses.
--   * Dates are dd/mm/yyyy in the file.
--   * The file quotes every field and ends lines with Windows
--     line endings (\r\n), so the load uses LINES TERMINATED BY
--     '\r\n'. Using '\n' alone joins pairs of lines together.
--   * "Awaiting Inspection" and "AwaitingInspection" both appear
--     in the file and are standardised to "AwaitingInspection".
-- ============================================================

DROP DATABASE IF EXISTS food_hygiene;
CREATE DATABASE food_hygiene CHARACTER SET utf8mb4;
USE food_hygiene;

-- ------------------------------------------------------------
-- 1. Establishments (one row per business)
-- ------------------------------------------------------------
CREATE TABLE establishments (
    fhrsid              INT,
    business_name       VARCHAR(255),
    business_type_id    INT,
    business_type       VARCHAR(100),
    address1            VARCHAR(255),
    address2            VARCHAR(255),
    address3            VARCHAR(255),
    address4            VARCHAR(255),
    postcode            VARCHAR(10),
    la_code             INT,
    la_name             VARCHAR(100),
    scheme_type         VARCHAR(10),
    rating_value        VARCHAR(40),
    rating_num          TINYINT,
    rating_date         DATE,
    hygiene             TINYINT,
    structural          TINYINT,
    confidence          TINYINT,
    latitude            DECIMAL(10,7),
    longitude           DECIMAL(10,7),
    new_rating_pending  BOOLEAN,
    has_right_to_reply  BOOLEAN,
    PRIMARY KEY (fhrsid)
);

-- Column order in the file:
--  1 AddressLine1  2 AddressLine2  3 AddressLine3  4 AddressLine4
--  5 BusinessTypeID  6 FHRSID  7 BusinessName  8 BusinessType
--  9 ConfidenceInManagement 10 Hygiene 11 Latitude
-- 12 LocalAuthorityBusinessID 13 LocalAuthorityCode
-- 14 LocalAuthorityName 15 Longitude 16 NewRatingPending
-- 17 PostCode 18 RatingDate 19 RatingKey 20 RatingValue
-- 21 RightToReply 22 SchemeType 23 Structural
LOAD DATA LOCAL INFILE 'C:/fsa/fhrs.csv'
INTO TABLE establishments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@a1, @a2, @a3, @a4, @btid, @fhrsid, @name, @btype, @conf, @hyg,
 @lat, @labid, @lacode, @laname, @lon, @pending, @pc, @rdate,
 @rkey, @rval, @rtr, @scheme, @struct)
SET
    fhrsid             = @fhrsid,
    business_name      = NULLIF(TRIM(@name), ''),
    business_type_id   = NULLIF(TRIM(@btid), ''),
    business_type      = NULLIF(TRIM(@btype), ''),
    address1           = NULLIF(TRIM(@a1), ''),
    address2           = NULLIF(TRIM(@a2), ''),
    address3           = NULLIF(TRIM(@a3), ''),
    address4           = NULLIF(TRIM(@a4), ''),
    postcode           = NULLIF(UPPER(TRIM(@pc)), ''),
    la_code            = NULLIF(TRIM(@lacode), ''),
    la_name            = NULLIF(TRIM(@laname), ''),
    scheme_type        = NULLIF(TRIM(@scheme), ''),
    rating_value       = CASE TRIM(@rval)
                           WHEN ''                    THEN NULL
                           WHEN 'Awaiting Inspection' THEN 'AwaitingInspection'
                           ELSE TRIM(@rval)
                         END,
    rating_num         = IF(TRIM(@rval) REGEXP '^[0-5]$', TRIM(@rval), NULL),
    rating_date        = CASE
                           WHEN TRIM(@rdate) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}'
                             THEN STR_TO_DATE(LEFT(TRIM(@rdate), 10), '%d/%m/%Y')
                           WHEN TRIM(@rdate) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
                             THEN STR_TO_DATE(LEFT(TRIM(@rdate), 10), '%Y-%m-%d')
                         END,
    hygiene            = IF(TRIM(@hyg)  REGEXP '^[0-9]+$', TRIM(@hyg),  NULL),
    structural         = IF(TRIM(TRAILING '\r' FROM @struct) REGEXP '^[0-9]+$',
                            TRIM(TRAILING '\r' FROM @struct), NULL),
    confidence         = IF(TRIM(@conf) REGEXP '^[0-9]+$', TRIM(@conf), NULL),
    latitude           = IF(TRIM(@lat)  REGEXP '^-?[0-9]+(\\.[0-9]+)?$', TRIM(@lat), NULL),
    longitude          = IF(TRIM(@lon)  REGEXP '^-?[0-9]+(\\.[0-9]+)?$', TRIM(@lon), NULL),
    new_rating_pending = (UPPER(TRIM(@pending)) = 'TRUE'),
    has_right_to_reply = (TRIM(@rtr) <> '');

-- A tiny number of rows in the file are malformed (a stray quote
-- inside a field shifts the columns), leaving a scheme type that
-- is not FHRS or FHIS. Remove them.
DELETE FROM establishments
WHERE  scheme_type IS NULL
   OR  scheme_type NOT IN ('FHRS', 'FHIS');

-- ------------------------------------------------------------
-- 2. Business types, with a broader sector grouping
-- ------------------------------------------------------------
CREATE TABLE business_types (
    business_type_id INT,
    business_type    VARCHAR(100),
    sector           VARCHAR(40),
    PRIMARY KEY (business_type_id)
);

INSERT INTO business_types (business_type_id, business_type)
SELECT business_type_id, MAX(business_type)
FROM   establishments
WHERE  business_type_id IS NOT NULL
GROUP  BY business_type_id;

UPDATE business_types
SET sector = CASE
    WHEN business_type LIKE 'Restaurant%'
      OR business_type LIKE 'Takeaway%'
      OR business_type LIKE 'Pub%'
      OR business_type LIKE 'Hotel%'
      OR business_type LIKE 'Mobile%'              THEN 'Hospitality'
    WHEN business_type LIKE 'Retailers%'           THEN 'Retail'
    WHEN business_type LIKE 'Hospitals%'
      OR business_type LIKE 'School%'              THEN 'Public sector and care'
    WHEN business_type LIKE 'Manufacturers%'
      OR business_type LIKE 'Importers%'
      OR business_type LIKE 'Distributors%'
      OR business_type LIKE 'Farmers%'             THEN 'Production and supply'
    ELSE 'Other'
END;

-- ------------------------------------------------------------
-- 3. Local authorities
-- ------------------------------------------------------------
CREATE TABLE local_authorities (
    la_code      INT,
    la_name      VARCHAR(100),
    scheme_type  VARCHAR(10),
    PRIMARY KEY (la_code)
);

INSERT INTO local_authorities (la_code, la_name, scheme_type)
SELECT la_code, MAX(la_name), MAX(scheme_type)
FROM   establishments
WHERE  la_code IS NOT NULL
GROUP  BY la_code;

-- Nation: Scotland runs FHIS; Northern Ireland LAs use BT
-- postcodes; Wales is identified by its 22 council names;
-- everything else is England.
ALTER TABLE local_authorities ADD COLUMN nation VARCHAR(20);

UPDATE local_authorities la
JOIN  (SELECT la_code, AVG(postcode LIKE 'BT%') AS bt_share
       FROM   establishments
       GROUP  BY la_code) p ON p.la_code = la.la_code
SET la.nation = CASE
    WHEN la.scheme_type = 'FHIS'                     THEN 'Scotland'
    WHEN p.bt_share > 0.5                            THEN 'Northern Ireland'
    WHEN la.la_name REGEXP 'Anglesey|Blaenau Gwent|Bridgend|Caerphilly|Cardiff|Carmarthenshire|Ceredigion|Conwy|Denbighshire|Flintshire|Gwynedd|Merthyr Tydfil|Monmouthshire|Neath Port Talbot|Newport|Pembrokeshire|Powys|Rhondda Cynon|Swansea|Torfaen|Vale of Glamorgan|Wrexham'
                                                     THEN 'Wales'
    ELSE 'England'
END;

-- The names now live in the lookup tables, so remove the copies
-- from establishments. Queries join to get them back.
ALTER TABLE establishments
    DROP COLUMN business_type,
    DROP COLUMN la_name;

-- ------------------------------------------------------------
-- 4. Rating descriptions (FSA wording)
-- ------------------------------------------------------------
CREATE TABLE rating_descriptions (
    rating_num  TINYINT,
    description VARCHAR(40),
    PRIMARY KEY (rating_num)
);

INSERT INTO rating_descriptions VALUES
(5, 'Very good'),
(4, 'Good'),
(3, 'Generally satisfactory'),
(2, 'Improvement necessary'),
(1, 'Major improvement necessary'),
(0, 'Urgent improvement necessary');

-- ------------------------------------------------------------
-- 5. Indexes
-- ------------------------------------------------------------
CREATE INDEX idx_est_la     ON establishments (la_code);
CREATE INDEX idx_est_type   ON establishments (business_type_id);
CREATE INDEX idx_est_rating ON establishments (rating_num);
CREATE INDEX idx_est_date   ON establishments (rating_date);

-- ------------------------------------------------------------
-- 6. Checks - send these results back
-- ------------------------------------------------------------
SELECT COUNT(*) AS establishments FROM establishments;

SELECT scheme_type, COUNT(*) AS establishments
FROM   establishments GROUP BY scheme_type;

SELECT rating_value, COUNT(*) AS establishments
FROM   establishments GROUP BY rating_value ORDER BY establishments DESC;

SELECT COUNT(*) AS business_types FROM business_types;
SELECT sector, COUNT(*) AS types FROM business_types GROUP BY sector;
SELECT nation, COUNT(*) AS local_authorities
FROM   local_authorities GROUP BY nation ORDER BY nation;

-- Check the Welsh match (should list 22 councils, and no English
-- 'Newport' style false matches - e.g. Newport in Shropshire is
-- under Telford and Wrekin, so it will not appear)
SELECT la_name FROM local_authorities WHERE nation = 'Wales' ORDER BY la_name;

SELECT MIN(rating_date) AS earliest, MAX(rating_date) AS latest,
       SUM(rating_date IS NULL) AS no_date
FROM   establishments;

-- Spot check against the row you sent (@72.China, Cambridge)
SELECT * FROM establishments WHERE fhrsid = 1472964;
