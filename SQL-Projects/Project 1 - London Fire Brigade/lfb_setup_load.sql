-- ============================================================
-- LFB PROJECT - SETUP SCRIPT (raw data load)
-- Loads both LFB CSV files into raw tables, every column as VARCHAR.
-- Run this once. Your 75 queries go in a separate file.
-- ============================================================

CREATE DATABASE IF NOT EXISTS lfb_project;
USE lfb_project;

-- ------------------------------------------------------------
-- RAW INCIDENTS (39 columns, same order as the CSV header)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS raw_incidents;

CREATE TABLE raw_incidents (
    incident_number                        VARCHAR(50),
    date_of_call                           VARCHAR(50),
    cal_year                               VARCHAR(10),
    time_of_call                           VARCHAR(20),
    hour_of_call                           VARCHAR(10),
    incident_group                         VARCHAR(100),
    stop_code_description                  VARCHAR(255),
    special_service_type                   VARCHAR(255),
    property_category                      VARCHAR(255),
    property_type                          VARCHAR(255),
    address_qualifier                      VARCHAR(255),
    postcode_full                          VARCHAR(20),
    postcode_district                      VARCHAR(20),
    uprn                                   VARCHAR(50),
    usrn                                   VARCHAR(50),
    borough_code                           VARCHAR(20),
    borough_name                           VARCHAR(100),
    proper_case                            VARCHAR(100),
    ward_code                              VARCHAR(20),
    ward_name                              VARCHAR(100),
    ward_name_new                          VARCHAR(100),
    easting_m                              VARCHAR(20),
    northing_m                             VARCHAR(20),
    easting_rounded                        VARCHAR(20),
    northing_rounded                       VARCHAR(20),
    latitude                               VARCHAR(30),
    longitude                              VARCHAR(30),
    frs                                    VARCHAR(50),
    incident_station_ground                VARCHAR(100),
    first_pump_attendance_time             VARCHAR(20),
    first_pump_deployed_from_station       VARCHAR(100),
    second_pump_attendance_time            VARCHAR(20),
    second_pump_deployed_from_station      VARCHAR(100),
    num_stations_with_pumps_attending      VARCHAR(10),
    num_pumps_attending                    VARCHAR(10),
    pump_count                             VARCHAR(10),
    pump_minutes_rounded                   VARCHAR(20),
    notional_cost_gbp                      VARCHAR(20),
    num_calls                              VARCHAR(10)
);

-- ------------------------------------------------------------
-- RAW MOBILISATIONS (24 columns, same order as the CSV header)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS raw_mobilisations;

CREATE TABLE raw_mobilisations (
    incident_number                        VARCHAR(50),
    cal_year                               VARCHAR(10),
    borough_name                           VARCHAR(100),
    ward_name                              VARCHAR(100),
    hour_of_call                           VARCHAR(10),
    resource_mobilisation_id               VARCHAR(50),
    resource_code                          VARCHAR(50),
    performance_reporting                  VARCHAR(50),
    date_time_mobilised                    VARCHAR(50),
    date_time_mobile                       VARCHAR(50),
    date_time_arrived                      VARCHAR(50),
    turnout_time_seconds                   VARCHAR(20),
    travel_time_seconds                    VARCHAR(20),
    attendance_time_seconds                VARCHAR(20),
    date_time_left                         VARCHAR(50),
    date_time_returned                     VARCHAR(50),
    deployed_from_station_code             VARCHAR(20),
    deployed_from_station_name             VARCHAR(100),
    deployed_from_location                 VARCHAR(100),
    pump_order                             VARCHAR(10),
    plus_code_code                         VARCHAR(50),
    plus_code_description                  VARCHAR(255),
    delay_code_id                          VARCHAR(20),
    delay_code_description                 VARCHAR(255)
);

-- ------------------------------------------------------------
-- LOAD THE FILES
-- 1) Change the file paths to yours (use forward slashes).
-- 2) Delimiter: if your file uses commas, use ','.
--    If it uses tabs, change ',' to '\t' on the FIELDS line.
-- 3) If every row loads as one line, change '\r\n' to '\n'.
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 1 - LFB Dataset/LFB Incident data from 2024 onwards.csv'
INTO TABLE raw_incidents
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SHOW WARNINGS;

LOAD DATA LOCAL INFILE 'C:/Users/musta/Documents/Skill Versed - data analytics/SQL/Projects/Project 1 - LFB Dataset/LFB Mobilisation data from 2025.csv'
INTO TABLE raw_mobilisations
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

SHOW WARNINGS;

-- ------------------------------------------------------------
-- CHECK THE LOAD
-- ------------------------------------------------------------
SELECT 'raw_incidents' AS table_name, COUNT(*) AS row_count FROM raw_incidents
UNION ALL
SELECT 'raw_mobilisations', COUNT(*) FROM raw_mobilisations;