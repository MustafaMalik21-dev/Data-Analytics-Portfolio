-- ============================================================
-- AIR QUALITY PROJECT: ANALYSIS QUERIES
-- Project type: Type 3 (15 questions, each built around a
--               different family of SQL functions)
-- Perspective:  Air pollution exposure and health guidelines
-- End consumer: Local authority air quality / public health officer
-- Data:         Defra AURN hourly measurements, 2025
--               (201 sites, 4.52 million readings: NO2, O3,
--               PM10, PM2.5)
-- ============================================================
--   Q1   Aggregate functions        COUNT, AVG, MIN, MAX, SUM
--   Q2   Grouping functions         WITH ROLLUP, GROUPING()
--   Q3   String: extraction         SUBSTRING_INDEX, GROUP_CONCAT
--   Q4   String: formatting         CONCAT, UPPER, LOWER, FORMAT
--   Q5   Pattern matching           REGEXP, LIKE
--   Q6   Numeric functions          ROUND, FLOOR, CEIL, GREATEST
--   Q7   Conditional functions      CASE, IF, NULLIF
--   Q8   Date functions             DAYOFWEEK, DAYNAME, HOUR
--   Q9   Ranking window functions   ROW_NUMBER, RANK
--   Q10  Distribution window        NTILE, PERCENT_RANK, CUME_DIST
--   Q11  Window aggregates          AVG() OVER (8-hour running mean)
--   Q12  Navigation window          LAG, LEAD
--   Q13  Subqueries                 correlated subquery, EXISTS
--   Q14  Set operations             UNION ALL
--   Q15  Statistical aggregates     STDDEV_POP, VAR_POP, correlation
-- ============================================================
-- Conventions
--   * All concentrations are in micrograms per cubic metre (ug/m3).
--   * Timestamps are GMT. measured_at is the start of each hour.
--   * Annual means use sites with at least 75% data capture
--     (6,570 of 8,760 hours), the usual Defra threshold.
--   * Daily means use days with at least 18 hours of data (75%).
--   * Benchmarks used:
--       UK annual objective: NO2 40, PM10 40, PM2.5 20
--       England PM2.5 target: 10 by 2040
--       WHO 2021 annual guidelines: NO2 10, PM10 15, PM2.5 5
--       UK O3 objective: daily maximum 8-hour mean above 100
--       on no more than 10 days a year
--   * Small negative readings are instrument noise around zero.
-- Run air_setup.sql first.
-- ============================================================

USE air_quality;


-- ============================================================
-- SETUP VIEW (run once): annual mean and data capture for each
-- site and pollutant. Used by Q2-Q4, Q9, Q10, Q13 and Q14.
-- ============================================================
CREATE OR REPLACE VIEW v_site_annual AS
SELECT site_code,
       pollutant,
       COUNT(*)                          AS hours,
       ROUND(COUNT(*) / 8760 * 100, 1)   AS capture_pct,
       AVG(concentration)                AS annual_mean
FROM   measurements
GROUP  BY site_code, pollutant;


-- ============================================================
-- Q1 | AGGREGATE FUNCTIONS
-- Question: For each pollutant, how many hourly readings and sites
--           are there, what are the mean, lowest and highest
--           readings, and what is the average data capture?
-- Concept:  COUNT, COUNT(DISTINCT), AVG, MIN, MAX, SUM
-- ============================================================
SELECT pollutant,
       COUNT(*)                                   AS readings,
       COUNT(DISTINCT site_code)                  AS sites,
       ROUND(AVG(concentration), 2)               AS mean_ugm3,
       ROUND(MIN(concentration), 1)               AS min_ugm3,
       ROUND(MAX(concentration), 1)               AS max_ugm3,
       SUM(concentration < 0)                     AS negative_readings,
       ROUND(COUNT(*) / (COUNT(DISTINCT site_code) * 8760) * 100, 1)
                                                  AS avg_capture_pct
FROM   measurements
GROUP  BY pollutant
ORDER  BY pollutant;


-- ============================================================
-- Q2 | GROUPING FUNCTIONS
-- Question: What is the average annual NO2 concentration by nation
--           and site type, with a subtotal for each nation and a
--           UK total?
-- Concept:  GROUP BY ... WITH ROLLUP + GROUPING() to label the
--           subtotal and total rows
-- ============================================================
SELECT IF(GROUPING(s.nation), 'ALL NATIONS', s.nation)      AS nation,
       IF(GROUPING(s.environment_type),
          IF(GROUPING(s.nation), '(UK total)', '(nation total)'),
          s.environment_type)                               AS site_type,
       COUNT(*)                                             AS sites,
       ROUND(AVG(a.annual_mean), 1)                         AS mean_no2_ugm3,
       ROUND(MAX(a.annual_mean), 1)                         AS highest_site_ugm3,
       SUM(a.annual_mean > 40)                              AS sites_above_uk_40,
       SUM(a.annual_mean > 10)                              AS sites_above_who_10
FROM   v_site_annual a
JOIN   sites s ON s.site_code = a.site_code
WHERE  a.pollutant = 'NO2'
  AND  a.capture_pct >= 75
GROUP  BY s.nation, s.environment_type WITH ROLLUP;


-- ============================================================
-- Q3 | STRING FUNCTIONS: EXTRACTION
-- Question: Site names start with the town or city and end with a
--           descriptor ("London Marylebone Road", "Belfast
--           Centre"). Which towns have three or more sites, what
--           descriptors do they use, and what is their average
--           annual NO2?
-- Concept:  CTE + SUBSTRING_INDEX (first and last word) +
--           GROUP_CONCAT(DISTINCT ...)
-- ============================================================
WITH named AS (
    SELECT site_code,
           SUBSTRING_INDEX(site_name, ' ', 1)    AS town,
           SUBSTRING_INDEX(site_name, ' ', -1)   AS descriptor
    FROM   sites
)
SELECT n.town,
       COUNT(*)                                                   AS sites,
       GROUP_CONCAT(DISTINCT n.descriptor ORDER BY n.descriptor
                    SEPARATOR ', ')                               AS descriptors,
       COUNT(a.site_code)                                         AS sites_with_no2,
       ROUND(AVG(a.annual_mean), 1)                               AS mean_no2_ugm3
FROM   named n
LEFT   JOIN v_site_annual a
       ON  a.site_code = n.site_code
       AND a.pollutant = 'NO2'
       AND a.capture_pct >= 75
GROUP  BY n.town
HAVING COUNT(*) >= 3
ORDER  BY sites DESC, n.town;


-- ============================================================
-- Q4 | STRING FUNCTIONS: FORMATTING
-- Question: Which 15 sites had the highest annual mean NO2? Show
--           each as a readable label with its site type in
--           sentence case, its coordinates as "51.523N, 0.155W"
--           and its concentration with units.
-- Concept:  CONCAT, CONCAT_WS, UPPER, LOWER, LEFT, SUBSTRING,
--           FORMAT, ABS
-- ============================================================
SELECT CONCAT(s.site_code, ' - ', s.site_name)                      AS site_label,
       CONCAT(UPPER(LEFT(s.environment_type, 1)),
              LOWER(SUBSTRING(s.environment_type, 2)))              AS site_type,
       CONCAT_WS(' / ', s.nation, s.region)                         AS location,
       CONCAT(FORMAT(ABS(s.latitude), 3),  IF(s.latitude  >= 0, 'N', 'S'), ', ',
              FORMAT(ABS(s.longitude), 3), IF(s.longitude <  0, 'W', 'E'))
                                                                    AS coordinates,
       CONCAT(FORMAT(a.annual_mean, 1), ' ug/m3')                   AS no2_annual_mean,
       CONCAT(FORMAT(a.capture_pct, 1), '%')                        AS data_capture
FROM   v_site_annual a
JOIN   sites s ON s.site_code = a.site_code
WHERE  a.pollutant = 'NO2'
  AND  a.capture_pct >= 75
ORDER  BY a.annual_mean DESC
LIMIT  15;


-- ============================================================
-- Q5 | PATTERN MATCHING
-- Question: Do site names that mention a road (Road, Street,
--           Roadside, Kerbside, Lane, Way or an A/M road number)
--           match Defra's official site type, and how does their
--           NO2 compare?
-- Concept:  REGEXP with word boundaries + LIKE
-- ============================================================
WITH tagged AS (
    SELECT site_code,
           environment_type,
           CASE
               WHEN site_name REGEXP '\\b(Roadside|Kerbside|Road|Street|Lane|Way|A[0-9]{1,4}|M[0-9]{1,2})\\b'
                    THEN '1. Road in name'
               WHEN site_name LIKE '%Centre%' OR site_name LIKE '%Town%'
                    THEN '2. Centre or Town in name'
               ELSE '3. Other name'
           END AS name_pattern
    FROM   sites
)
SELECT t.name_pattern,
       t.environment_type,
       COUNT(*)                       AS sites,
       COUNT(a.site_code)             AS sites_with_no2,
       ROUND(AVG(a.annual_mean), 1)   AS mean_no2_ugm3
FROM   tagged t
LEFT   JOIN v_site_annual a
       ON  a.site_code = t.site_code
       AND a.pollutant = 'NO2'
       AND a.capture_pct >= 75
GROUP  BY t.name_pattern, t.environment_type
ORDER  BY t.name_pattern, sites DESC;


-- ============================================================
-- Q6 | NUMERIC FUNCTIONS
-- Question: By region, what is the average annual PM2.5, how many
--           times the WHO guideline (5) is it, and how far is each
--           region from England's 2040 target of 10?
-- Concept:  GREATEST (negatives treated as 0), ROUND, FLOOR, CEIL
-- ============================================================
WITH site_pm AS (
    SELECT s.region,
           m.site_code,
           AVG(GREATEST(m.concentration, 0)) AS mean_pm25
    FROM   measurements m
    JOIN   sites s ON s.site_code = m.site_code
    WHERE  m.pollutant = 'PM25'
    GROUP  BY s.region, m.site_code
    HAVING COUNT(*) >= 6570
)
SELECT region,
       COUNT(*)                         AS sites,
       ROUND(AVG(mean_pm25), 2)         AS mean_pm25_ugm3,
       FLOOR(MIN(mean_pm25))            AS lowest_site_floor,
       CEIL(MAX(mean_pm25))             AS highest_site_ceil,
       ROUND(AVG(mean_pm25) / 5, 1)     AS times_who_guideline,
       ROUND(AVG(mean_pm25) - 10, 2)    AS gap_to_2040_target,
       SUM(mean_pm25 > 10)              AS sites_above_10
FROM   site_pm
GROUP  BY region
ORDER  BY mean_pm25_ugm3 DESC;


-- ============================================================
-- Q7 | CONDITIONAL FUNCTIONS
-- Question: Band every site-day of PM2.5 using the UK Daily Air
--           Quality Index (Low 0-35, Moderate 36-53, High 54-70,
--           Very High 71+). How many site-days fall in each band,
--           and how many were at roadside or background sites?
-- Concept:  CASE, IF, NULLIF (safe division)
-- ============================================================
WITH daily AS (
    SELECT site_code,
           obs_date,
           AVG(concentration) AS daily_mean
    FROM   measurements
    WHERE  pollutant = 'PM25'
    GROUP  BY site_code, obs_date
    HAVING COUNT(*) >= 18
),
banded AS (
    SELECT d.site_code,
           d.daily_mean,
           s.environment_type,
           CASE
               WHEN ROUND(d.daily_mean) <= 35 THEN '1. Low (DAQI 1-3)'
               WHEN ROUND(d.daily_mean) <= 53 THEN '2. Moderate (DAQI 4-6)'
               WHEN ROUND(d.daily_mean) <= 70 THEN '3. High (DAQI 7-9)'
               ELSE                                '4. Very High (DAQI 10)'
           END AS daqi_band
    FROM   daily d
    JOIN   sites s ON s.site_code = d.site_code
)
SELECT daqi_band,
       COUNT(*)                                                     AS site_days,
       ROUND(COUNT(*) * 100 /
             NULLIF((SELECT COUNT(*) FROM banded), 0), 2)           AS pct_of_site_days,
       SUM(IF(environment_type = 'Urban Traffic', 1, 0))            AS roadside_days,
       SUM(IF(environment_type LIKE '%Background', 1, 0))           AS background_days,
       COUNT(DISTINCT site_code)                                    AS sites_affected,
       ROUND(MAX(daily_mean), 1)                                    AS highest_daily_mean
FROM   banded
GROUP  BY daqi_band
ORDER  BY daqi_band;


-- ============================================================
-- Q8 | DATE FUNCTIONS
-- Question: At roadside (Urban Traffic) sites, how does NO2 change
--           by day of the week, and how do the morning and
--           evening rush hours compare with the middle of the
--           night?
-- Concept:  DAYOFWEEK, DAYNAME, HOUR
-- ============================================================
WITH roadside AS (
    SELECT DAYOFWEEK(m.measured_at)  AS day_no,
           DAYNAME(m.measured_at)    AS day_name,
           HOUR(m.measured_at)       AS hr,
           m.concentration
    FROM   measurements m
    JOIN   sites s ON s.site_code = m.site_code
    WHERE  m.pollutant = 'NO2'
      AND  s.environment_type = 'Urban Traffic'
)
SELECT day_no,
       day_name,
       COUNT(*)                                                     AS readings,
       ROUND(AVG(concentration), 1)                                 AS all_hours,
       ROUND(AVG(CASE WHEN hr BETWEEN 7  AND 9  THEN concentration END), 1) AS morning_7_10,
       ROUND(AVG(CASE WHEN hr BETWEEN 16 AND 18 THEN concentration END), 1) AS evening_16_19,
       ROUND(AVG(CASE WHEN hr BETWEEN 1  AND 4  THEN concentration END), 1) AS night_1_5,
       ROUND(AVG(CASE WHEN hr BETWEEN 7  AND 9  THEN concentration END) /
             AVG(CASE WHEN hr BETWEEN 1  AND 4  THEN concentration END), 2) AS morning_to_night_ratio
FROM   roadside
GROUP  BY day_no, day_name
ORDER  BY day_no;


-- ============================================================
-- Q9 | RANKING WINDOW FUNCTIONS
-- Question: What are the three sites with the highest annual NO2
--           in each nation, and where does each rank across the UK?
-- Concept:  ROW_NUMBER partitioned by nation + RANK across the UK
-- ============================================================
WITH ranked AS (
    SELECT s.nation,
           s.site_name,
           s.environment_type,
           a.annual_mean,
           ROW_NUMBER() OVER (PARTITION BY s.nation ORDER BY a.annual_mean DESC) AS nation_rank,
           RANK()       OVER (ORDER BY a.annual_mean DESC)                       AS uk_rank
    FROM   v_site_annual a
    JOIN   sites s ON s.site_code = a.site_code
    WHERE  a.pollutant = 'NO2'
      AND  a.capture_pct >= 75
)
SELECT nation,
       nation_rank,
       site_name,
       environment_type,
       ROUND(annual_mean, 1) AS no2_ugm3,
       uk_rank
FROM   ranked
WHERE  nation_rank <= 3
ORDER  BY nation, nation_rank;


-- ============================================================
-- Q10 | DISTRIBUTION WINDOW FUNCTIONS
-- Question: Split PM2.5 sites into four equal groups by annual
--           mean. What range does each quartile cover, what
--           percentile does it start at, and what mix of site
--           types is in each?
-- Concept:  NTILE, PERCENT_RANK, CUME_DIST
-- ============================================================
WITH dist AS (
    SELECT s.environment_type,
           a.annual_mean,
           NTILE(4)       OVER (ORDER BY a.annual_mean) AS quartile,
           PERCENT_RANK() OVER (ORDER BY a.annual_mean) AS pct_rank,
           CUME_DIST()    OVER (ORDER BY a.annual_mean) AS cume_share
    FROM   v_site_annual a
    JOIN   sites s ON s.site_code = a.site_code
    WHERE  a.pollutant = 'PM25'
      AND  a.capture_pct >= 75
)
SELECT quartile,
       COUNT(*)                                       AS sites,
       ROUND(MIN(annual_mean), 2)                     AS min_pm25,
       ROUND(MAX(annual_mean), 2)                     AS max_pm25,
       ROUND(AVG(annual_mean), 2)                     AS avg_pm25,
       ROUND(MIN(pct_rank) * 100, 1)                  AS starts_at_percentile,
       ROUND(MAX(cume_share) * 100, 1)                 AS cumulative_pct,
       SUM(environment_type = 'Urban Traffic')        AS roadside,
       SUM(environment_type = 'Urban Background')     AS urban_background,
       SUM(environment_type = 'Rural Background')     AS rural_background,
       SUM(environment_type NOT IN ('Urban Traffic', 'Urban Background',
                                    'Rural Background')) AS other
FROM   dist
GROUP  BY quartile
ORDER  BY quartile;


-- ============================================================
-- Q11 | WINDOW AGGREGATE FUNCTIONS
-- Question: Using the 8-hour running mean of ozone, which 15 sites
--           had the most days with a daily maximum above 100, and
--           which met the UK objective (no more than 10 such days)?
-- Concept:  AVG() and COUNT() OVER a time-based RANGE window
--           (the current hour and the 7 before it)
-- ============================================================
WITH running AS (
    SELECT site_code,
           obs_date,
           AVG(concentration) OVER (PARTITION BY site_code ORDER BY measured_at
               RANGE BETWEEN INTERVAL 7 HOUR PRECEDING AND CURRENT ROW) AS mean_8h,
           COUNT(*)           OVER (PARTITION BY site_code ORDER BY measured_at
               RANGE BETWEEN INTERVAL 7 HOUR PRECEDING AND CURRENT ROW) AS hours_in_window
    FROM   measurements
    WHERE  pollutant = 'O3'
),
daily_max AS (
    SELECT site_code,
           obs_date,
           MAX(mean_8h) AS max_8h
    FROM   running
    WHERE  hours_in_window >= 6
    GROUP  BY site_code, obs_date
)
SELECT s.site_name,
       s.environment_type,
       s.nation,
       COUNT(*)                                      AS days_with_data,
       SUM(d.max_8h > 100)                           AS days_above_100,
       ROUND(MAX(d.max_8h), 1)                       AS highest_8h_mean,
       IF(SUM(d.max_8h > 100) > 10, 'Not met', 'Met') AS uk_objective
FROM   daily_max d
JOIN   sites s ON s.site_code = d.site_code
GROUP  BY s.site_code, s.site_name, s.environment_type, s.nation
ORDER  BY days_above_100 DESC, highest_8h_mean DESC
LIMIT  15;


-- ============================================================
-- Q12 | NAVIGATION WINDOW FUNCTIONS
-- Question: Which 15 days saw the biggest day-on-day rise in the
--           network-wide average PM2.5, and what happened the day
--           before and the day after?
-- Concept:  LAG and LEAD over a daily series
-- ============================================================
WITH daily AS (
    SELECT obs_date,
           AVG(concentration)        AS network_mean,
           COUNT(DISTINCT site_code) AS sites
    FROM   measurements
    WHERE  pollutant = 'PM25'
    GROUP  BY obs_date
),
nav AS (
    SELECT obs_date,
           sites,
           network_mean,
           LAG(network_mean)  OVER (ORDER BY obs_date) AS prev_day,
           LEAD(network_mean) OVER (ORDER BY obs_date) AS next_day
    FROM   daily
)
SELECT obs_date,
       DAYNAME(obs_date)                    AS day_name,
       sites,
       ROUND(prev_day, 1)                   AS prev_day_pm25,
       ROUND(network_mean, 1)               AS pm25,
       ROUND(next_day, 1)                   AS next_day_pm25,
       ROUND(network_mean - prev_day, 1)    AS rise_from_prev_day
FROM   nav
WHERE  prev_day IS NOT NULL
ORDER  BY rise_from_prev_day DESC
LIMIT  15;


-- ============================================================
-- Q13 | SUBQUERIES
-- Question: Which roadside sites have an annual mean NO2 above the
--           roadside average for their own nation, and does the
--           same site also record PM2.5 above England's 2040
--           target of 10?
-- Concept:  Correlated subquery (nation average per row) + EXISTS
--           against the PM2.5 results for the same site
-- ============================================================
WITH roadside AS (
    SELECT s.site_code,
           s.site_name,
           s.nation,
           a.annual_mean
    FROM   v_site_annual a
    JOIN   sites s ON s.site_code = a.site_code
    WHERE  a.pollutant = 'NO2'
      AND  a.capture_pct >= 75
      AND  s.environment_type = 'Urban Traffic'
)
SELECT r.site_name,
       r.nation,
       ROUND(r.annual_mean, 1)                                  AS no2_ugm3,
       ROUND((SELECT AVG(x.annual_mean)
              FROM   roadside x
              WHERE  x.nation = r.nation), 1)                   AS nation_roadside_avg,
       CASE
           WHEN EXISTS (SELECT 1 FROM v_site_annual p
                        WHERE  p.site_code = r.site_code
                          AND  p.pollutant = 'PM25'
                          AND  p.capture_pct >= 75
                          AND  p.annual_mean > 10) THEN 'Yes'
           WHEN EXISTS (SELECT 1 FROM v_site_annual p
                        WHERE  p.site_code = r.site_code
                          AND  p.pollutant = 'PM25'
                          AND  p.capture_pct >= 75) THEN 'No'
           ELSE 'Not measured'
       END                                                      AS pm25_above_10
FROM   roadside r
WHERE  r.annual_mean > (SELECT AVG(x.annual_mean)
                        FROM   roadside x
                        WHERE  x.nation = r.nation)
ORDER  BY r.annual_mean DESC
LIMIT  20;


-- ============================================================
-- Q14 | SET OPERATIONS
-- Question: Compare the 20 sites with the highest annual NO2 with
--           the 20 with the highest annual PM2.5. Which sites are
--           in both lists, and which in only one?
-- Concept:  UNION ALL of two ranked lists + GROUP BY to classify
-- ============================================================
WITH top_no2 AS (
    SELECT site_code FROM (
        SELECT site_code, ROW_NUMBER() OVER (ORDER BY annual_mean DESC) AS rn
        FROM   v_site_annual
        WHERE  pollutant = 'NO2' AND capture_pct >= 75
    ) x WHERE rn <= 20
),
top_pm25 AS (
    SELECT site_code FROM (
        SELECT site_code, ROW_NUMBER() OVER (ORDER BY annual_mean DESC) AS rn
        FROM   v_site_annual
        WHERE  pollutant = 'PM25' AND capture_pct >= 75
    ) x WHERE rn <= 20
),
combined AS (
    SELECT site_code, 'NO2'  AS list FROM top_no2
    UNION ALL
    SELECT site_code, 'PM25' AS list FROM top_pm25
),
classified AS (
    SELECT site_code,
           CASE
               WHEN COUNT(*) = 2     THEN '1. Both lists'
               WHEN MAX(list) = 'NO2' THEN '2. High NO2 only'
               ELSE                       '3. High PM2.5 only'
           END AS appears_in
    FROM   combined
    GROUP  BY site_code
)
SELECT c.appears_in,
       s.site_name,
       s.environment_type,
       ROUND(n.annual_mean, 1) AS no2_ugm3,
       ROUND(p.annual_mean, 1) AS pm25_ugm3
FROM   classified c
JOIN   sites s ON s.site_code = c.site_code
LEFT   JOIN v_site_annual n ON n.site_code = c.site_code AND n.pollutant = 'NO2'
LEFT   JOIN v_site_annual p ON p.site_code = c.site_code AND p.pollutant = 'PM25'
ORDER  BY c.appears_in, n.annual_mean DESC, p.annual_mean DESC;


-- ============================================================
-- Q15 | STATISTICAL AGGREGATE FUNCTIONS
-- Question: At sites measuring both NO2 and ozone, how variable is
--           each pollutant hour to hour, and how strongly are the
--           two correlated, by site type?
-- Concept:  AVG, STDDEV_POP, VAR_POP + Pearson correlation
--           (covariance / product of standard deviations)
-- ============================================================
WITH paired AS (
    SELECT site_code,
           measured_at,
           MAX(CASE WHEN pollutant = 'NO2' THEN concentration END) AS no2,
           MAX(CASE WHEN pollutant = 'O3'  THEN concentration END) AS o3
    FROM   measurements
    WHERE  pollutant IN ('NO2', 'O3')
    GROUP  BY site_code, measured_at
),
matched AS (
    SELECT p.site_code, p.no2, p.o3, s.environment_type
    FROM   paired p
    JOIN   sites s ON s.site_code = p.site_code
    WHERE  p.no2 IS NOT NULL
      AND  p.o3  IS NOT NULL
)
SELECT environment_type,
       COUNT(DISTINCT site_code)          AS sites,
       COUNT(*)                           AS paired_hours,
       ROUND(AVG(no2), 1)                 AS mean_no2,
       ROUND(STDDEV_POP(no2), 1)          AS sd_no2,
       ROUND(VAR_POP(no2), 1)             AS var_no2,
       ROUND(AVG(o3), 1)                  AS mean_o3,
       ROUND(STDDEV_POP(o3), 1)           AS sd_o3,
       ROUND(VAR_POP(o3), 1)              AS var_o3,
       ROUND((AVG(no2 * o3) - AVG(no2) * AVG(o3))
             / (STDDEV_POP(no2) * STDDEV_POP(o3)), 3) AS correlation_r
FROM   matched
GROUP  BY environment_type
ORDER  BY sites DESC;
