-- ============================================================
-- AIR QUALITY PROJECT: SETUP SCRIPT
-- Database: air_quality (MySQL 8)
-- Source:   Defra UK-AIR, Automatic Urban and Rural Network
--           (AURN), hourly data for 2025, 201 sites.
--           Reshaped from the per-site files by PowerShell into
--           measurements.csv (one row per site, hour, pollutant)
--           and site_info.csv (one row per site).
-- Pollutants kept: NO2, O3, PM10, PM2.5 (all in ug/m3)
-- Before running:
--   1. Paths point to your Project 6 folder. MySQL needs forward
--      slashes (/) in the path.
--   2. local_infile must be ON (as in the earlier projects).
--   3. Both files were written by PowerShell on Windows, so they
--      use \r\n line endings.
--   4. The measurements load may take a few minutes.
-- Time convention: Defra timestamps are GMT and "hour ending",
--   so 01:00 covers 00:00-01:00 and 24:00 is the last hour of the
--   day. obs_date + obs_hour keep that convention (hour 1-24);
--   measured_at is the START of the hour as a proper DATETIME.
-- ============================================================

DROP DATABASE IF EXISTS air_quality;
CREATE DATABASE air_quality CHARACTER SET utf8mb4;
USE air_quality;

-- ------------------------------------------------------------
-- 1. Sites (one row per monitoring site)
-- ------------------------------------------------------------
CREATE TABLE sites (
    site_code         VARCHAR(6) PRIMARY KEY,
    site_name         VARCHAR(80),
    environment_type  VARCHAR(30),
    region            VARCHAR(40),
    nation            VARCHAR(20),
    latitude          DECIMAL(9,6),
    longitude         DECIMAL(9,6)
);

-- site_info.csv column order:
--   site_code, site_name, environment_type, region, latitude, longitude
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 6 - Air Quality/site_info.csv'
INTO TABLE sites
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@code, @name, @env, @reg, @lat, @lon)
SET site_code        = TRIM(@code),
    site_name        = TRIM(@name),
    environment_type = NULLIF(TRIM(@env), ''),
    region           = NULLIF(REPLACE(TRIM(@reg), '&amp;', '&'), ''),
    latitude         = NULLIF(TRIM(@lat), ''),
    longitude        = NULLIF(TRIM(@lon), '');

-- Nation from region
UPDATE sites
SET nation = CASE
    WHEN region IN ('Central Scotland', 'Highland', 'North East Scotland',
                    'Scottish Borders') THEN 'Scotland'
    WHEN region IN ('South Wales', 'North Wales') THEN 'Wales'
    WHEN region IN ('Northern Ireland', 'West Ireland') THEN 'Northern Ireland'
    WHEN region IS NULL THEN NULL
    ELSE 'England'
END;

-- ------------------------------------------------------------
-- 2. Measurements (fact table: one row per site, hour, pollutant)
-- ------------------------------------------------------------
CREATE TABLE measurements (
    obs_id         INT AUTO_INCREMENT PRIMARY KEY,
    site_code      VARCHAR(6),
    obs_date       DATE,
    obs_hour       TINYINT,        -- 1-24, hour ending (GMT)
    measured_at    DATETIME,       -- start of the hour (GMT)
    pollutant      VARCHAR(4),     -- NO2, O3, PM10, PM25
    concentration  DECIMAL(10,4),  -- ug/m3
    status         VARCHAR(3)      -- R = ratified, P = provisional
);

-- measurements.csv column order:
--   site_code, obs_date (dd-mm-yyyy), obs_time (hh:00), pollutant,
--   value, status
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 6 - Air Quality/measurements.csv'
INTO TABLE measurements
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(@code, @d, @t, @pol, @v, @st)
SET site_code     = TRIM(@code),
    obs_date      = STR_TO_DATE(@d, '%d-%m-%Y'),
    obs_hour      = CAST(SUBSTRING_INDEX(@t, ':', 1) AS UNSIGNED),
    measured_at   = STR_TO_DATE(@d, '%d-%m-%Y')
                    + INTERVAL (CAST(SUBSTRING_INDEX(@t, ':', 1) AS UNSIGNED) - 1) HOUR,
    pollutant     = TRIM(@pol),
    concentration = NULLIF(TRIM(@v), ''),
    status        = NULLIF(TRIM(@st), '');

CREATE INDEX ix_meas_site_pol_date ON measurements (site_code, pollutant, obs_date);
CREATE INDEX ix_meas_pol_time      ON measurements (pollutant, measured_at);

-- ------------------------------------------------------------
-- 3. Checks (send me the results)
-- ------------------------------------------------------------
-- 3a. Row counts and date range
SELECT COUNT(*)                   AS measurement_rows,
       COUNT(DISTINCT site_code)  AS sites,
       MIN(measured_at)           AS first_hour,
       MAX(measured_at)           AS last_hour,
       SUM(concentration IS NULL) AS null_values,
       SUM(obs_date IS NULL)      AS bad_dates
FROM measurements;

-- 3b. Rows and sites per pollutant
SELECT pollutant,
       COUNT(*)                  AS readings,
       COUNT(DISTINCT site_code) AS sites,
       ROUND(AVG(concentration), 2) AS mean_ugm3,
       MIN(concentration)        AS min_ugm3,
       MAX(concentration)        AS max_ugm3
FROM measurements
GROUP BY pollutant
ORDER BY pollutant;

-- 3c. Status values (should be only R and P, possibly P*)
SELECT status, COUNT(*) AS readings
FROM measurements
GROUP BY status;

-- 3d. Sites table
SELECT COUNT(*) AS sites, COUNT(environment_type) AS with_env,
       COUNT(region) AS with_region, COUNT(latitude) AS with_latlon
FROM sites;

SELECT nation, COUNT(*) AS sites FROM sites GROUP BY nation;

-- 3e. Measurement sites with no match in sites (should be 0)
SELECT COUNT(DISTINCT m.site_code) AS unmatched_sites
FROM measurements m
LEFT JOIN sites s ON s.site_code = m.site_code
WHERE s.site_code IS NULL;

-- 3f. Spot check: Marylebone Road, first 3 hours of 2025
SELECT * FROM measurements
WHERE site_code = 'MY1' AND pollutant = 'NO2'
ORDER BY measured_at
LIMIT 3;
