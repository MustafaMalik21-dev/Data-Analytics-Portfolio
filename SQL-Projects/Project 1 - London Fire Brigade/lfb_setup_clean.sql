-- ============================================================
-- LFB PROJECT - SETUP SCRIPT 2 (clean, typed tables)
-- Builds analysis tables from the untouched raw tables.
--
-- Decisions (document these in the report's data profile):
--   * Period: 1 Jan 2025 to 30 Jun 2026 (18 complete months).
--     2024 dropped: no mobilisation data exists for it.
--     July 2026 dropped: incomplete in the mobilisations file.
--   * Incidents with no mobilisation are KEPT (real incidents,
--     mostly no pumping appliance recorded).
--   * Mobilisations with no matching incident are EXCLUDED.
--   * Blank text is converted to NULL; numbers and dates get
--     proper types.
-- ============================================================

USE lfb_project;

DROP TABLE IF EXISTS mobilisations;
DROP TABLE IF EXISTS incidents;

-- ------------------------------------------------------------
-- CLEAN INCIDENTS
-- ------------------------------------------------------------
CREATE TABLE incidents AS
SELECT
    incident_number,
    STR_TO_DATE(date_of_call, '%d-%b-%y')                          AS date_of_call,
    CAST(NULLIF(cal_year, '') AS UNSIGNED)                         AS cal_year,
    STR_TO_DATE(NULLIF(time_of_call, ''), '%H:%i:%s')              AS time_of_call,
    CAST(NULLIF(hour_of_call, '') AS UNSIGNED)                     AS hour_of_call,
    NULLIF(incident_group, '')                                     AS incident_group,
    NULLIF(stop_code_description, '')                              AS stop_code_description,
    NULLIF(special_service_type, '')                               AS special_service_type,
    NULLIF(property_category, '')                                  AS property_category,
    NULLIF(property_type, '')                                      AS property_type,
    NULLIF(address_qualifier, '')                                  AS address_qualifier,
    NULLIF(postcode_full, '')                                      AS postcode_full,
    NULLIF(postcode_district, '')                                  AS postcode_district,
    NULLIF(uprn, '')                                               AS uprn,
    NULLIF(usrn, '')                                               AS usrn,
    NULLIF(borough_code, '')                                       AS borough_code,
    NULLIF(borough_name, '')                                       AS borough_name,
    NULLIF(proper_case, '')                                        AS proper_case,
    NULLIF(ward_code, '')                                          AS ward_code,
    NULLIF(ward_name, '')                                          AS ward_name,
    NULLIF(ward_name_new, '')                                      AS ward_name_new,
    CAST(NULLIF(easting_m, '') AS DECIMAL(10,2))                   AS easting_m,
    CAST(NULLIF(northing_m, '') AS DECIMAL(10,2))                  AS northing_m,
    CAST(NULLIF(easting_rounded, '') AS UNSIGNED)                  AS easting_rounded,
    CAST(NULLIF(northing_rounded, '') AS UNSIGNED)                 AS northing_rounded,
    CAST(NULLIF(latitude, '') AS DECIMAL(9,6))                     AS latitude,
    CAST(NULLIF(longitude, '') AS DECIMAL(9,6))                    AS longitude,
    NULLIF(frs, '')                                                AS frs,
    NULLIF(incident_station_ground, '')                            AS incident_station_ground,
    CAST(NULLIF(first_pump_attendance_time, '') AS UNSIGNED)       AS first_pump_attendance_time,
    NULLIF(first_pump_deployed_from_station, '')                   AS first_pump_deployed_from_station,
    CAST(NULLIF(second_pump_attendance_time, '') AS UNSIGNED)      AS second_pump_attendance_time,
    NULLIF(second_pump_deployed_from_station, '')                  AS second_pump_deployed_from_station,
    CAST(NULLIF(num_stations_with_pumps_attending, '') AS UNSIGNED) AS num_stations_with_pumps_attending,
    CAST(NULLIF(num_pumps_attending, '') AS UNSIGNED)              AS num_pumps_attending,
    CAST(NULLIF(pump_count, '') AS UNSIGNED)                       AS pump_count,
    CAST(NULLIF(pump_minutes_rounded, '') AS UNSIGNED)             AS pump_minutes_rounded,
    CAST(NULLIF(notional_cost_gbp, '') AS DECIMAL(12,2))           AS notional_cost_gbp,
    CAST(NULLIF(num_calls, '') AS UNSIGNED)                        AS num_calls
FROM raw_incidents
WHERE STR_TO_DATE(date_of_call, '%d-%b-%y') BETWEEN '2025-01-01' AND '2026-06-30';

-- One row per incident: this fails if any incident number repeats.
ALTER TABLE incidents ADD PRIMARY KEY (incident_number);

-- ------------------------------------------------------------
-- CLEAN MOBILISATIONS
-- Only mobilisations whose incident is in the clean incidents
-- table. This drops orphans and aligns the period in one step.
-- Some resource_mobilisation_id values appear more than once in the
-- raw file. dup_rank numbers the copies of each ID (1, 2, ...) so the
-- extra copies can be deleted below, keeping one row per mobilisation.
-- ------------------------------------------------------------
CREATE TABLE mobilisations AS
SELECT
    m.incident_number,
    CAST(NULLIF(m.cal_year, '') AS UNSIGNED)                       AS cal_year,
    NULLIF(m.borough_name, '')                                     AS borough_name,
    NULLIF(m.ward_name, '')                                        AS ward_name,
    CAST(NULLIF(m.hour_of_call, '') AS UNSIGNED)                   AS hour_of_call,
    m.resource_mobilisation_id,
    NULLIF(m.resource_code, '')                                    AS resource_code,
    NULLIF(m.performance_reporting, '')                            AS performance_reporting,
    STR_TO_DATE(NULLIF(m.date_time_mobilised, ''), '%d/%m/%Y %H:%i') AS date_time_mobilised,
    STR_TO_DATE(NULLIF(m.date_time_mobile, ''), '%d/%m/%Y %H:%i')    AS date_time_mobile,
    STR_TO_DATE(NULLIF(m.date_time_arrived, ''), '%d/%m/%Y %H:%i')   AS date_time_arrived,
    CAST(NULLIF(m.turnout_time_seconds, '') AS UNSIGNED)           AS turnout_time_seconds,
    CAST(NULLIF(m.travel_time_seconds, '') AS UNSIGNED)            AS travel_time_seconds,
    CAST(NULLIF(m.attendance_time_seconds, '') AS UNSIGNED)        AS attendance_time_seconds,
    STR_TO_DATE(NULLIF(m.date_time_left, ''), '%d/%m/%Y %H:%i')      AS date_time_left,
    STR_TO_DATE(NULLIF(m.date_time_returned, ''), '%d/%m/%Y %H:%i')  AS date_time_returned,
    NULLIF(m.deployed_from_station_code, '')                       AS deployed_from_station_code,
    NULLIF(m.deployed_from_station_name, '')                       AS deployed_from_station_name,
    NULLIF(m.deployed_from_location, '')                           AS deployed_from_location,
    CAST(NULLIF(m.pump_order, '') AS UNSIGNED)                     AS pump_order,
    NULLIF(m.plus_code_code, '')                                   AS plus_code_code,
    NULLIF(m.plus_code_description, '')                            AS plus_code_description,
    CAST(NULLIF(m.delay_code_id, '') AS UNSIGNED)                  AS delay_code_id,
    NULLIF(m.delay_code_description, '')                           AS delay_code_description,
    ROW_NUMBER() OVER (
        PARTITION BY m.resource_mobilisation_id
        ORDER BY m.incident_number
    )                                                              AS dup_rank
FROM raw_mobilisations AS m
INNER JOIN incidents AS i
        ON i.incident_number = m.incident_number;

-- Delete the extra copies, keep the first, then drop the helper column.
SET SQL_SAFE_UPDATES = 0;
DELETE FROM mobilisations WHERE dup_rank > 1;
SET SQL_SAFE_UPDATES = 1;
ALTER TABLE mobilisations DROP COLUMN dup_rank;

-- One row per mobilisation, plus an index for joins back to incidents.
ALTER TABLE mobilisations ADD PRIMARY KEY (resource_mobilisation_id);
CREATE INDEX idx_mobilisations_incident ON mobilisations (incident_number);

-- ------------------------------------------------------------
-- CHECKS
-- ------------------------------------------------------------
SELECT 'incidents' AS table_name,
       COUNT(*)            AS row_count,
       MIN(date_of_call)   AS first_date,
       MAX(date_of_call)   AS last_date
FROM incidents
UNION ALL
SELECT 'mobilisations',
       COUNT(*),
       DATE(MIN(date_time_mobilised)),
       DATE(MAX(date_time_mobilised))
FROM mobilisations;