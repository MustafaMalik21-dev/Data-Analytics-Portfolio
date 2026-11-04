-- ============================================================
-- KS4 SCHOOL PERFORMANCE PROJECT: SETUP SCRIPT
-- Database: school_performance (MySQL 8)
-- Sources:
--   * DfE KS4 performance tables 2024/25 (final), school level
--   * DfE Get Information About Schools (GIAS), all establishments
--   * DfE LA and region codes (la_and_region_codes_meta.csv)
-- Before running:
--   1. Put the three CSV files in C:/schools/ and rename them to
--      england_ks4final.csv, edubasealldata.csv and la_regions.csv
--   2. Make sure local_infile is ON (as in the Price Paid project)
-- Only the columns needed for the analysis are loaded. Each source
-- column is read into @c<position> and the unused ones are ignored.
-- Suppression codes (NA, NP, NE, SUPP, LOWCOV, SP, RE) become NULL
-- and % signs are stripped, so all measures load as numbers.
-- ============================================================

DROP DATABASE IF EXISTS school_performance;
CREATE DATABASE school_performance CHARACTER SET utf8mb4;
USE school_performance;

-- ------------------------------------------------------------
-- 1. GIAS school register (one row per establishment)
-- ------------------------------------------------------------
CREATE TABLE schools (
    urn                 INT,
    la_code             SMALLINT,
    la_name             VARCHAR(60),
    school_name         VARCHAR(120),
    establishment_type  VARCHAR(80),
    type_group          VARCHAR(60),
    status              VARCHAR(40),
    open_date           DATE,
    phase               VARCHAR(40),
    low_age             TINYINT,
    high_age            TINYINT,
    sixth_form          VARCHAR(40),
    gender              VARCHAR(20),
    religious_character VARCHAR(60),
    admissions_policy   VARCHAR(40),
    capacity            INT,
    pupils              INT,
    pct_fsm             DECIMAL(5,1),
    trust_flag          VARCHAR(60),
    trust_name          VARCHAR(150),
    town                VARCHAR(60),
    postcode            VARCHAR(10),
    region              VARCHAR(40),
    district            VARCHAR(60),
    constituency        VARCHAR(80),
    urban_rural         VARCHAR(60),
    PRIMARY KEY (urn)
);

LOAD DATA LOCAL INFILE 'C:/schools/edubasealldata.csv'
INTO TABLE schools
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
    (@c1, @c2, @c3, @c4, @c5, @c6, @c7, @c8, @c9, @c10, @c11, @c12,
     @c13, @c14, @c15, @c16, @c17, @c18, @c19, @c20, @c21, @c22, @c23,
     @c24, @c25, @c26, @c27, @c28, @c29, @c30, @c31, @c32, @c33, @c34,
     @c35, @c36, @c37, @c38, @c39, @c40, @c41, @c42, @c43, @c44, @c45,
     @c46, @c47, @c48, @c49, @c50, @c51, @c52, @c53, @c54, @c55, @c56,
     @c57, @c58, @c59, @c60, @c61, @c62, @c63, @c64, @c65, @c66, @c67,
     @c68, @c69, @c70, @c71, @c72, @c73, @c74, @c75, @c76, @c77, @c78,
     @c79, @c80, @c81, @c82, @c83, @c84, @c85, @c86, @c87, @c88, @c89,
     @c90, @c91, @c92, @c93, @c94, @c95, @c96, @c97, @c98, @c99, @c100,
     @c101, @c102, @c103, @c104, @c105, @c106, @c107, @c108, @c109)
SET
    urn                 = IF(@c1 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c1, '%', ''), NULL),
    la_code             = IF(@c2 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c2, '%', ''), NULL),
    la_name             = NULLIF(TRIM(@c3), ''),
    school_name         = NULLIF(TRIM(@c5), ''),
    establishment_type  = NULLIF(TRIM(@c7), ''),
    type_group          = NULLIF(TRIM(@c9), ''),
    status              = NULLIF(TRIM(@c11), ''),
    open_date           = STR_TO_DATE(NULLIF(TRIM(@c14), ''), '%d/%m/%Y'),
    phase               = NULLIF(TRIM(@c19), ''),
    low_age             = IF(@c20 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c20, '%', ''), NULL),
    high_age            = IF(@c21 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c21, '%', ''), NULL),
    sixth_form          = NULLIF(TRIM(@c26), ''),
    gender              = NULLIF(TRIM(@c28), ''),
    religious_character = NULLIF(TRIM(@c30), ''),
    admissions_policy   = NULLIF(TRIM(@c35), ''),
    capacity            = IF(@c36 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c36, '%', ''), NULL),
    pupils              = IF(@c40 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c40, '%', ''), NULL),
    pct_fsm             = IF(@c43 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c43, '%', ''), NULL),
    trust_flag          = NULLIF(TRIM(@c45), ''),
    trust_name          = NULLIF(TRIM(@c47), ''),
    town                = NULLIF(TRIM(@c60), ''),
    postcode            = NULLIF(TRIM(@c62), ''),
    region              = NULLIF(TRIM(@c101), ''),
    district            = NULLIF(TRIM(@c103), ''),
    constituency        = NULLIF(TRIM(@c107), ''),
    urban_rural         = NULLIF(TRIM(@c109), '');

-- ------------------------------------------------------------
-- 2. KS4 results (schools, plus LA and national summary rows)
--    rectype: 1 = mainstream, 2 = special, 4 = LA,
--             5 = national (all schools), 7 = national (maintained)
-- ------------------------------------------------------------
CREATE TABLE ks4_results (
    result_id INT AUTO_INCREMENT,
    rectype                 TINYINT,
    la_code                 SMALLINT,
    urn                     INT,
    school_name             VARCHAR(120),
    nftype                  VARCHAR(10),
    rel_denom               VARCHAR(60),
    admissions              VARCHAR(40),
    gender_entry            VARCHAR(10),
    pupils_on_roll          INT,
    ks4_pupils              INT,
    disadv_pupils           INT,
    pct_disadv              DECIMAL(5,1),
    pct_eal                 DECIMAL(5,1),
    pct_sen_ehcp            DECIMAL(5,1),
    pct_sen_all             DECIMAL(5,1),
    att8                    DECIMAL(4,1),
    att8_eng                DECIMAL(4,1),
    att8_mat                DECIMAL(4,1),
    pct_em_4plus            DECIMAL(5,1),
    pct_em_5plus            DECIMAL(5,1),
    ebacc_aps               DECIMAL(4,2),
    pct_ebacc_entry         DECIMAL(5,1),
    att8_disadv             DECIMAL(4,1),
    att8_non_disadv         DECIMAL(4,1),
    att8_girls              DECIMAL(4,1),
    att8_boys               DECIMAL(4,1),
    pct_em_5plus_disadv     DECIMAL(5,1),
    pct_em_5plus_non_disadv DECIMAL(5,1),
    pct_triple_sci          DECIMAL(5,1),
    att8_2024               DECIMAL(4,1),
    att8_2023               DECIMAL(4,1),
    PRIMARY KEY (result_id)
);

LOAD DATA LOCAL INFILE 'C:/schools/england_ks4final.csv'
INTO TABLE ks4_results
CHARACTER SET latin1
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
    (@c1, @c2, @c3, @c4, @c5, @c6, @c7, @c8, @c9, @c10, @c11, @c12,
     @c13, @c14, @c15, @c16, @c17, @c18, @c19, @c20, @c21, @c22, @c23,
     @c24, @c25, @c26, @c27, @c28, @c29, @c30, @c31, @c32, @c33, @c34,
     @c35, @c36, @c37, @c38, @c39, @c40, @c41, @c42, @c43, @c44, @c45,
     @c46, @c47, @c48, @c49, @c50, @c51, @c52, @c53, @c54, @c55, @c56,
     @c57, @c58, @c59, @c60, @c61, @c62, @c63, @c64, @c65, @c66, @c67,
     @c68, @c69, @c70, @c71, @c72, @c73, @c74, @c75, @c76, @c77, @c78,
     @c79, @c80, @c81, @c82, @c83, @c84, @c85, @c86, @c87, @c88, @c89,
     @c90, @c91, @c92, @c93, @c94, @c95, @c96, @c97, @c98, @c99, @c100,
     @c101, @c102, @c103, @c104, @c105, @c106, @c107, @c108, @c109,
     @c110, @c111, @c112, @c113, @c114, @c115, @c116, @c117, @c118,
     @c119, @c120, @c121, @c122, @c123, @c124, @c125, @c126, @c127,
     @c128, @c129, @c130, @c131, @c132, @c133, @c134, @c135, @c136,
     @c137, @c138, @c139, @c140, @c141, @c142, @c143, @c144, @c145,
     @c146, @c147, @c148, @c149, @c150, @c151, @c152, @c153, @c154,
     @c155, @c156, @c157, @c158, @c159, @c160, @c161, @c162, @c163,
     @c164, @c165, @c166, @c167, @c168, @c169, @c170, @c171, @c172,
     @c173, @c174, @c175, @c176, @c177, @c178, @c179, @c180, @c181,
     @c182, @c183, @c184, @c185, @c186, @c187, @c188, @c189, @c190,
     @c191, @c192, @c193, @c194, @c195, @c196, @c197, @c198, @c199,
     @c200, @c201, @c202, @c203, @c204, @c205, @c206, @c207, @c208,
     @c209, @c210, @c211, @c212, @c213, @c214, @c215, @c216, @c217,
     @c218, @c219, @c220, @c221, @c222, @c223, @c224, @c225, @c226,
     @c227, @c228, @c229, @c230, @c231, @c232, @c233, @c234, @c235,
     @c236, @c237, @c238, @c239, @c240, @c241, @c242, @c243, @c244,
     @c245, @c246, @c247, @c248, @c249, @c250, @c251, @c252, @c253,
     @c254, @c255, @c256, @c257, @c258, @c259, @c260, @c261, @c262,
     @c263, @c264, @c265, @c266, @c267, @c268, @c269, @c270, @c271,
     @c272, @c273, @c274, @c275, @c276, @c277, @c278, @c279, @c280,
     @c281, @c282, @c283, @c284, @c285, @c286, @c287, @c288, @c289,
     @c290, @c291, @c292, @c293, @c294, @c295, @c296, @c297, @c298,
     @c299, @c300, @c301, @c302, @c303, @c304, @c305, @c306, @c307,
     @c308, @c309, @c310, @c311, @c312, @c313, @c314, @c315, @c316,
     @c317, @c318, @c319, @c320, @c321, @c322, @c323, @c324, @c325,
     @c326, @c327, @c328, @c329, @c330, @c331, @c332, @c333, @c334,
     @c335, @c336, @c337, @c338, @c339, @c340, @c341, @c342, @c343,
     @c344, @c345, @c346, @c347, @c348, @c349, @c350, @c351, @c352,
     @c353, @c354, @c355, @c356, @c357, @c358, @c359, @c360, @c361,
     @c362, @c363, @c364, @c365, @c366, @c367, @c368, @c369, @c370,
     @c371, @c372, @c373, @c374, @c375, @c376, @c377, @c378, @c379,
     @c380, @c381, @c382, @c383, @c384, @c385, @c386, @c387, @c388,
     @c389, @c390, @c391, @c392, @c393, @c394, @c395, @c396, @c397,
     @c398, @c399, @c400, @c401, @c402, @c403, @c404, @c405, @c406,
     @c407, @c408, @c409, @c410, @c411, @c412, @c413, @c414, @c415,
     @c416, @c417, @c418, @c419, @c420, @c421, @c422, @c423, @c424,
     @c425, @c426, @c427, @c428, @c429, @c430, @c431, @c432, @c433,
     @c434, @c435, @c436, @c437)
SET
    rectype                 = IF(@c1 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c1, '%', ''), NULL),
    la_code                 = IF(@c2 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c2, '%', ''), NULL),
    urn                     = IF(@c4 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c4, '%', ''), NULL),
    school_name             = NULLIF(TRIM(@c5), ''),
    nftype                  = NULLIF(TRIM(@c17), ''),
    rel_denom               = NULLIF(TRIM(@c18), ''),
    admissions              = NULLIF(TRIM(@c20), ''),
    gender_entry            = NULLIF(TRIM(@c21), ''),
    pupils_on_roll          = IF(@c24 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c24, '%', ''), NULL),
    ks4_pupils              = IF(@c27 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c27, '%', ''), NULL),
    disadv_pupils           = IF(@c39 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c39, '%', ''), NULL),
    pct_disadv              = IF(@c40 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c40, '%', ''), NULL),
    pct_eal                 = IF(@c44 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c44, '%', ''), NULL),
    pct_sen_ehcp            = IF(@c52 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c52, '%', ''), NULL),
    pct_sen_all             = IF(@c54 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c54, '%', ''), NULL),
    att8                    = IF(@c58 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c58, '%', ''), NULL),
    att8_eng                = IF(@c60 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c60, '%', ''), NULL),
    att8_mat                = IF(@c62 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c62, '%', ''), NULL),
    pct_em_4plus            = IF(@c94 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c94, '%', ''), NULL),
    pct_em_5plus            = IF(@c95 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c95, '%', ''), NULL),
    ebacc_aps               = IF(@c97 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c97, '%', ''), NULL),
    pct_ebacc_entry         = IF(@c108 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c108, '%', ''), NULL),
    att8_disadv             = IF(@c168 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c168, '%', ''), NULL),
    att8_non_disadv         = IF(@c177 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c177, '%', ''), NULL),
    att8_girls              = IF(@c266 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c266, '%', ''), NULL),
    att8_boys               = IF(@c281 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c281, '%', ''), NULL),
    pct_em_5plus_disadv     = IF(@c400 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c400, '%', ''), NULL),
    pct_em_5plus_non_disadv = IF(@c401 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c401, '%', ''), NULL),
    pct_triple_sci          = IF(@c413 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c413, '%', ''), NULL),
    att8_2024               = IF(@c436 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c436, '%', ''), NULL),
    att8_2023               = IF(@c437 REGEXP '^-?[0-9]+(\\.[0-9]+)?%?$', REPLACE(@c437, '%', ''), NULL);

-- ------------------------------------------------------------
-- 3. Local authorities and DfE regions
-- ------------------------------------------------------------
CREATE TABLE la_regions (
    la_code     SMALLINT,
    la_name     VARCHAR(60),
    region_code TINYINT,
    region_name VARCHAR(60),
    PRIMARY KEY (la_code)
);

LOAD DATA LOCAL INFILE 'C:/schools/la_regions.csv'
INTO TABLE la_regions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@la, @name, @reg, @regname)
SET la_code     = @la,
    la_name     = TRIM(@name),
    region_code = @reg,
    region_name = TRIM(TRAILING '\r' FROM TRIM(@regname));

-- ------------------------------------------------------------
-- 4. School type lookup (NFTYPE codes from the DfE abbreviations)
-- ------------------------------------------------------------
CREATE TABLE school_types (
    nftype      VARCHAR(10),
    type_name   VARCHAR(60),
    type_group  VARCHAR(30),
    PRIMARY KEY (nftype)
);

INSERT INTO school_types VALUES
('AC',    'Academy (sponsor led)',          'Academy'),
('ACC',   'Academy (converter)',            'Academy'),
('F',     'Free school',                    'Free school'),
('UTC',   'University technical college',   'Free school'),
('SS',    'Studio school',                  'Free school'),
('CTC',   'City technology college',        'Academy'),
('CY',    'Community school',               'LA maintained'),
('VA',    'Voluntary aided school',         'LA maintained'),
('VC',    'Voluntary controlled school',    'LA maintained'),
('FD',    'Foundation school',              'LA maintained'),
('IND',   'Independent school',             'Independent'),
('INDSS', 'Independent special school',     'Independent'),
('CYS',   'Community special school',       'Special'),
('FDS',   'Foundation special school',      'Special'),
('ACS',   'Academy special (sponsor led)',  'Special'),
('ACCS',  'Academy special (converter)',    'Special'),
('FS',    'Special free school',            'Special'),
('NMSS',  'Non-maintained special school',  'Special'),
('PRU',   'Pupil referral unit',            'Alternative provision'),
('AP',    'Alternative provision',          'Alternative provision'),
('FAP',   'Free school AP',                 'Alternative provision'),
('ACAP',  'Academy AP (sponsor led)',       'Alternative provision'),
('ACCAP', 'Academy AP (converter)',         'Alternative provision'),
('CHS',   'Community hospital school',      'Alternative provision'),
('FHS',   'Foundation hospital school',     'Alternative provision'),
('FESI',  'Further education institution',  'Other'),
('MODFC', 'Other government department',    'Other');

-- ------------------------------------------------------------
-- 5. Indexes for the joins
-- ------------------------------------------------------------
CREATE INDEX idx_ks4_urn     ON ks4_results (urn);
CREATE INDEX idx_ks4_la      ON ks4_results (la_code);
CREATE INDEX idx_ks4_rectype ON ks4_results (rectype);
CREATE INDEX idx_schools_la  ON schools (la_code);

-- ------------------------------------------------------------
-- 6. Checks - send these results back
-- ------------------------------------------------------------
SELECT COUNT(*) AS gias_rows, SUM(status = 'Open') AS open_schools FROM schools;

SELECT rectype, COUNT(*) AS rows_loaded, ROUND(AVG(att8), 1) AS avg_att8
FROM   ks4_results GROUP BY rectype ORDER BY rectype;

SELECT COUNT(*) AS la_rows FROM la_regions;

-- KS4 schools with no GIAS match (should be 0 or very few)
SELECT COUNT(*) AS unmatched
FROM   ks4_results k
LEFT JOIN schools s ON s.urn = k.urn
WHERE  k.rectype IN (1, 2) AND s.urn IS NULL;

-- KS4 school types missing from the lookup (should return no rows)
SELECT DISTINCT k.nftype
FROM   ks4_results k
LEFT JOIN school_types t ON t.nftype = k.nftype
WHERE  k.rectype IN (1, 2) AND t.nftype IS NULL;

-- Spot check against the row you sent (City of London School)
SELECT urn, school_name, nftype, ks4_pupils, att8, pct_em_5plus, ebacc_aps, att8_2024
FROM   ks4_results WHERE urn = 100003;
