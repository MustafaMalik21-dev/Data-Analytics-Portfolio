-- ============================================================
-- KS4 SCHOOL PERFORMANCE PROJECT: ANALYSIS QUERIES
-- Project type: Type 1 (40 questions)
--   Q1-Q10   KPI           headline figures and benchmarks
--   Q11-Q20  Univariate    one variable: its distribution
--   Q21-Q30  Bivariate     two variables: how one varies with
--                          the other
--   Q31-Q40  Multivariate  three or more variables together
-- Perspective:  School performance and disadvantage
-- End consumer: Local authority education officer
-- Data:         DfE KS4 performance tables 2024/25 (final),
--               Get Information About Schools (GIAS),
--               DfE LA and region codes
-- ============================================================
-- Conventions
--   * "School" = a mainstream school record in the KS4 tables
--     (rectype 1) with a published Attainment 8 score.
--   * "State-funded" = academies, free schools and LA maintained
--     schools. Most questions use state-funded schools only,
--     because disadvantage measures are not published for
--     independent schools and many independents enter IGCSEs
--     that do not count towards the measures.
--   * National benchmark = the KS4 national (state-funded)
--     record, rectype 7. LA benchmarks = rectype 4.
--   * "Pupil-weighted" figures weight each school by its KS4
--     cohort, so they describe pupils rather than schools.
--   * Progress 8 is not published for 2024/25 (no KS2 baseline
--     after the 2020 and 2021 SATs were cancelled), so the
--     project uses Attainment 8, English and maths passes and
--     EBacc measures instead.
--   * Rankings exclude schools with a KS4 cohort under 10.
-- Views
--   v_schools         created Q1, reused throughout
--   v_la_benchmarks   created Q10, reused Q37
-- Run ks4_setup.sql first. This file then runs top to bottom.
-- ============================================================

USE school_performance;


-- ############################################################
-- SECTION 1: KPI QUESTIONS
-- ############################################################

-- ============================================================
-- Q1 | KPI
-- Question: Create a reusable view joining KS4 results to school
--           details, type and region. Using it, how many schools
--           and KS4 pupils are covered, in total and in
--           state-funded schools?
-- Concept:  VIEW over a 4-table join + COUNT / SUM KPIs
-- Creates view: v_schools (reused throughout)
-- ============================================================
CREATE OR REPLACE VIEW v_schools AS
SELECT k.urn,
       k.school_name,
       k.la_code,
       lr.la_name,
       lr.region_name                              AS dfe_region,
       s.region,
       t.type_name,
       t.type_group,
       t.type_group IN ('Academy', 'Free school', 'LA maintained') AS state_funded,
       k.admissions,
       s.gender,
       s.religious_character,
       SUBSTRING_INDEX(s.urban_rural, ':', 1)      AS urban_rural,
       s.trust_name,
       k.ks4_pupils,
       k.pct_disadv,
       k.pct_eal,
       k.att8,
       k.att8_eng,
       k.att8_mat,
       k.att8_disadv,
       k.att8_non_disadv,
       k.att8_girls,
       k.att8_boys,
       k.pct_em_4plus,
       k.pct_em_5plus,
       k.pct_em_5plus_disadv,
       k.pct_em_5plus_non_disadv,
       k.ebacc_aps,
       k.pct_ebacc_entry,
       k.pct_triple_sci,
       k.att8_2024,
       k.att8_2023
FROM   ks4_results  k
JOIN   schools      s  ON s.urn      = k.urn
JOIN   school_types t  ON t.nftype   = k.nftype
JOIN   la_regions   lr ON lr.la_code = k.la_code
WHERE  k.rectype = 1
  AND  k.att8 IS NOT NULL;

SELECT COUNT(*)                                          AS all_schools,
       SUM(ks4_pupils)                                   AS all_ks4_pupils,
       SUM(state_funded = 1)                             AS state_schools,
       SUM(CASE WHEN state_funded = 1 THEN ks4_pupils END) AS state_ks4_pupils,
       ROUND(100 * SUM(CASE WHEN state_funded = 1 THEN ks4_pupils END)
             / SUM(ks4_pupils), 1)                       AS pct_pupils_state
FROM   v_schools;


-- ============================================================
-- Q2 | KPI
-- Question: What are the headline national figures for 2025:
--           Attainment 8, grade 4+ and 5+ in English and maths,
--           EBacc entry and EBacc average point score, for
--           state-funded schools and for all schools?
-- Concept:  Filtering the national summary rows + CASE labels
-- ============================================================
SELECT CASE rectype WHEN 7 THEN 'State-funded schools'
                    WHEN 5 THEN 'All schools' END  AS benchmark,
       att8,
       pct_em_4plus,
       pct_em_5plus,
       pct_ebacc_entry,
       ebacc_aps
FROM   ks4_results
WHERE  rectype IN (5, 7)
ORDER  BY rectype DESC;


-- ============================================================
-- Q3 | KPI
-- Question: How does the national state-funded Attainment 8
--           compare with the simple average of school scores
--           and the pupil-weighted average?
-- Concept:  Benchmark subquery + simple vs weighted average
-- ============================================================
SELECT (SELECT att8 FROM ks4_results WHERE rectype = 7)  AS national_att8,
       ROUND(AVG(att8), 1)                                AS avg_of_schools,
       ROUND(SUM(att8 * ks4_pupils) / SUM(ks4_pupils), 1) AS pupil_weighted_att8
FROM   v_schools
WHERE  state_funded = 1;


-- ============================================================
-- Q4 | KPI
-- Question: What is the national Attainment 8 gap between
--           disadvantaged and other pupils, and the gap in the
--           share achieving grade 5+ in English and maths?
-- Concept:  Derived KPIs from the national summary row
-- ============================================================
SELECT pct_disadv                                        AS pct_pupils_disadv,
       att8_disadv,
       att8_non_disadv,
       ROUND(att8_non_disadv - att8_disadv, 1)           AS att8_gap,
       pct_em_5plus_disadv,
       pct_em_5plus_non_disadv,
       ROUND(pct_em_5plus_non_disadv - pct_em_5plus_disadv, 1) AS em_5plus_gap_pts
FROM   ks4_results
WHERE  rectype = 7;


-- ============================================================
-- Q5 | KPI
-- Question: How has national state-funded Attainment 8 moved
--           over the last three years?
-- Concept:  Year columns in one record + derived change
-- ============================================================
SELECT att8_2023,
       att8_2024,
       att8                              AS att8_2025,
       ROUND(att8 - att8_2024, 1)        AS change_1yr,
       ROUND(att8 - att8_2023, 1)        AS change_2yr
FROM   ks4_results
WHERE  rectype = 7;


-- ============================================================
-- Q6 | KPI
-- Question: What share of state-funded schools, and of their
--           pupils, are above the national Attainment 8?
-- Concept:  Conditional aggregation against a benchmark
-- ============================================================
SELECT COUNT(*)                                             AS state_schools,
       SUM(v.att8 > nat.att8)                               AS schools_above_national,
       ROUND(100 * SUM(v.att8 > nat.att8) / COUNT(*), 1)    AS pct_schools_above,
       ROUND(100 * SUM(CASE WHEN v.att8 > nat.att8 THEN v.ks4_pupils END)
             / SUM(v.ks4_pupils), 1)                        AS pct_pupils_above
FROM   v_schools v
CROSS  JOIN (SELECT att8 FROM ks4_results WHERE rectype = 7) nat
WHERE  v.state_funded = 1;


-- ============================================================
-- Q7 | KPI
-- Question: What share of state-funded KS4 pupils are taught in
--           academies and free schools rather than LA maintained
--           schools?
-- Concept:  GROUP BY + share of total (window SUM OVER ())
-- ============================================================
SELECT type_group,
       COUNT(*)                                                  AS schools,
       SUM(ks4_pupils)                                           AS ks4_pupils,
       ROUND(100 * SUM(ks4_pupils) / SUM(SUM(ks4_pupils)) OVER (), 1) AS pct_of_pupils
FROM   v_schools
WHERE  state_funded = 1
GROUP  BY type_group
ORDER  BY ks4_pupils DESC;


-- ============================================================
-- Q8 | KPI
-- Question: What are the pupil-weighted rates of EBacc entry and
--           triple science entry across state-funded schools?
-- Concept:  Pupil-weighted averages
-- ============================================================
SELECT ROUND(SUM(pct_ebacc_entry * ks4_pupils) / SUM(ks4_pupils), 1) AS pct_ebacc_entry,
       ROUND(SUM(pct_triple_sci  * ks4_pupils) / SUM(ks4_pupils), 1) AS pct_triple_sci,
       ROUND(SUM(pct_eal         * ks4_pupils) / SUM(ks4_pupils), 1) AS pct_eal
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_ebacc_entry IS NOT NULL
  AND  pct_triple_sci  IS NOT NULL
  AND  pct_eal         IS NOT NULL;


-- ============================================================
-- Q9 | KPI
-- Question: How many state-funded schools have fewer than a third
--           of pupils achieving grade 5+ in English and maths, and
--           how many pupils attend them?
-- Concept:  Threshold KPI with COUNT / SUM and share of total
-- ============================================================
SELECT SUM(pct_em_5plus < 33.3)                                   AS schools_below_third,
       ROUND(100 * SUM(pct_em_5plus < 33.3) / COUNT(*), 1)        AS pct_of_schools,
       SUM(CASE WHEN pct_em_5plus < 33.3 THEN ks4_pupils END)     AS pupils_affected,
       ROUND(100 * SUM(CASE WHEN pct_em_5plus < 33.3 THEN ks4_pupils END)
             / SUM(ks4_pupils), 1)                                AS pct_of_pupils
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_em_5plus IS NOT NULL;


-- ============================================================
-- Q10 | KPI
-- Question: Create a reusable view of local authority benchmarks.
--           Using it, how many LAs are above the national
--           Attainment 8, and what share of pupils do they cover?
-- Concept:  VIEW (LA rows joined to regions) + conditional KPIs
-- Creates view: v_la_benchmarks (reused Q37)
-- ============================================================
CREATE OR REPLACE VIEW v_la_benchmarks AS
SELECT k.la_code,
       lr.la_name,
       lr.region_name      AS dfe_region,
       k.ks4_pupils,
       k.pct_disadv,
       k.att8,
       k.att8_disadv,
       k.att8_non_disadv,
       k.pct_em_5plus
FROM   ks4_results k
JOIN   la_regions  lr ON lr.la_code = k.la_code
WHERE  k.rectype = 4;

SELECT COUNT(*)                                              AS local_authorities,
       SUM(la.att8 > nat.att8)                               AS las_above_national,
       ROUND(100 * SUM(la.att8 > nat.att8) / COUNT(*), 1)    AS pct_las_above,
       ROUND(100 * SUM(CASE WHEN la.att8 > nat.att8 THEN la.ks4_pupils END)
             / SUM(la.ks4_pupils), 1)                        AS pct_pupils_in_those_las
FROM   v_la_benchmarks la
CROSS  JOIN (SELECT att8 FROM ks4_results WHERE rectype = 7) nat;


-- ############################################################
-- SECTION 2: UNIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q11 | UNIVARIATE
-- Question: What does the distribution of Attainment 8 look like
--           across state-funded schools: count, mean, standard
--           deviation, minimum and maximum?
-- Concept:  Summary statistics (AVG, STDDEV, MIN, MAX)
-- ============================================================
SELECT COUNT(*)                    AS schools,
       ROUND(AVG(att8), 1)         AS mean_att8,
       ROUND(STDDEV_POP(att8), 1)  AS sd_att8,
       MIN(att8)                   AS min_att8,
       MAX(att8)                   AS max_att8
FROM   v_schools
WHERE  state_funded = 1;


-- ============================================================
-- Q12 | UNIVARIATE
-- Question: What are the lower quartile, median and upper quartile
--           of Attainment 8 across state-funded schools?
-- Concept:  CTE + window functions (ROW_NUMBER, COUNT OVER) for
--           percentiles
-- ============================================================
WITH ordered AS (
    SELECT att8,
           ROW_NUMBER() OVER (ORDER BY att8) AS rn,
           COUNT(*)     OVER ()              AS n
    FROM   v_schools
    WHERE  state_funded = 1
)
SELECT MAX(CASE WHEN rn = CEIL(0.25 * n) THEN att8 END) AS lower_quartile,
       MAX(CASE WHEN rn = CEIL(0.50 * n) THEN att8 END) AS median,
       MAX(CASE WHEN rn = CEIL(0.75 * n) THEN att8 END) AS upper_quartile,
       MAX(CASE WHEN rn = CEIL(0.75 * n) THEN att8 END)
     - MAX(CASE WHEN rn = CEIL(0.25 * n) THEN att8 END) AS interquartile_range
FROM   ordered;


-- ============================================================
-- Q13 | UNIVARIATE
-- Question: How many state-funded schools fall into each 5-point
--           Attainment 8 band?
-- Concept:  CTE + FLOOR banding (histogram) + share
-- ============================================================
WITH banded AS (
    SELECT FLOOR(att8 / 5) * 5 AS band_start
    FROM   v_schools
    WHERE  state_funded = 1
)
SELECT CONCAT(band_start, '-', band_start + 4.9)          AS att8_band,
       COUNT(*)                                           AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)   AS pct_of_schools
FROM   banded
GROUP  BY band_start
ORDER  BY band_start;


-- ============================================================
-- Q14 | UNIVARIATE
-- Question: How is the share of disadvantaged pupils distributed
--           across state-funded schools, in 10-point bands?
-- Concept:  Histogram with CASE banding + share of total
-- ============================================================
SELECT CASE WHEN pct_disadv < 10 THEN '1. Under 10%'
            WHEN pct_disadv < 20 THEN '2. 10-19%'
            WHEN pct_disadv < 30 THEN '3. 20-29%'
            WHEN pct_disadv < 40 THEN '4. 30-39%'
            WHEN pct_disadv < 50 THEN '5. 40-49%'
            ELSE '6. 50%+' END                             AS disadv_band,
       COUNT(*)                                            AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_schools
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_disadv IS NOT NULL
GROUP  BY disadv_band
ORDER  BY disadv_band;


-- ============================================================
-- Q15 | UNIVARIATE
-- Question: How are schools with KS4 results split by school
--           type?
-- Concept:  Frequency table + share of total
-- ============================================================
SELECT type_name,
       type_group,
       COUNT(*)                                            AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_schools
FROM   v_schools
GROUP  BY type_name, type_group
ORDER  BY schools DESC;


-- ============================================================
-- Q16 | UNIVARIATE
-- Question: How are state-funded schools and KS4 pupils spread
--           across the regions of England?
-- Concept:  Frequency table (count and sum) + share of total
-- ============================================================
SELECT region,
       COUNT(*)                                                       AS schools,
       SUM(ks4_pupils)                                                AS ks4_pupils,
       ROUND(100 * SUM(ks4_pupils) / SUM(SUM(ks4_pupils)) OVER (), 1) AS pct_of_pupils
FROM   v_schools
WHERE  state_funded = 1
GROUP  BY region
ORDER  BY ks4_pupils DESC;


-- ============================================================
-- Q17 | UNIVARIATE
-- Question: How large are KS4 cohorts in state-funded schools?
--           Show the summary statistics and the share of schools
--           in each size band.
-- Concept:  CASE banding + aggregate statistics in one result
--           (window functions over the grouped rows)
-- ============================================================
SELECT CASE WHEN ks4_pupils < 100 THEN '1. Under 100'
            WHEN ks4_pupils < 150 THEN '2. 100-149'
            WHEN ks4_pupils < 200 THEN '3. 150-199'
            WHEN ks4_pupils < 250 THEN '4. 200-249'
            ELSE '5. 250+' END                                 AS cohort_band,
       COUNT(*)                                                AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_of_schools,
       MIN(ks4_pupils)                                         AS smallest,
       MAX(ks4_pupils)                                         AS largest
FROM   v_schools
WHERE  state_funded = 1
GROUP  BY cohort_band
ORDER  BY cohort_band;


-- ============================================================
-- Q18 | UNIVARIATE
-- Question: Which are the 10 highest and 10 lowest scoring
--           state-funded schools on Attainment 8 (cohorts of 10+)?
-- Concept:  CTE + window functions (RANK both ways)
-- ============================================================
WITH ranked AS (
    SELECT school_name,
           la_name,
           ks4_pupils,
           att8,
           RANK() OVER (ORDER BY att8 DESC) AS top_rank,
           RANK() OVER (ORDER BY att8 ASC)  AS bottom_rank
    FROM   v_schools
    WHERE  state_funded = 1
      AND  ks4_pupils >= 10
)
SELECT CASE WHEN top_rank <= 10 THEN 'Top 10' ELSE 'Bottom 10' END AS grp,
       school_name,
       la_name,
       ks4_pupils,
       att8
FROM   ranked
WHERE  top_rank <= 10
   OR  bottom_rank <= 10
ORDER  BY att8 DESC;


-- ============================================================
-- Q19 | UNIVARIATE
-- Question: How does EBacc entry vary across state-funded
--           schools? Group schools by the share of pupils entered.
-- Concept:  Histogram with CASE banding, including a zero band
-- ============================================================
SELECT CASE WHEN pct_ebacc_entry = 0  THEN '1. None entered'
            WHEN pct_ebacc_entry < 25 THEN '2. Under 25%'
            WHEN pct_ebacc_entry < 50 THEN '3. 25-49%'
            WHEN pct_ebacc_entry < 75 THEN '4. 50-74%'
            ELSE '5. 75%+' END                             AS ebacc_entry_band,
       COUNT(*)                                            AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_schools
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_ebacc_entry IS NOT NULL
GROUP  BY ebacc_entry_band
ORDER  BY ebacc_entry_band;


-- ============================================================
-- Q20 | UNIVARIATE
-- Question: Which state-funded schools are statistical outliers on
--           Attainment 8, more than 2.5 standard deviations from
--           the mean (cohorts of 10+)?
-- Concept:  CTE + window functions (AVG and STDDEV OVER) for
--           z-scores
-- ============================================================
WITH z AS (
    SELECT school_name,
           la_name,
           ks4_pupils,
           att8,
           ROUND((att8 - AVG(att8) OVER ()) / STDDEV_POP(att8) OVER (), 2) AS z_score
    FROM   v_schools
    WHERE  state_funded = 1
      AND  ks4_pupils >= 10
)
SELECT *
FROM   z
WHERE  ABS(z_score) > 2.5
ORDER  BY z_score DESC;


-- ############################################################
-- SECTION 3: BIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q21 | BIVARIATE
-- Question: How does Attainment 8 vary by school type group?
-- Concept:  Numeric by category: GROUP BY with AVG, MIN, MAX
-- ============================================================
SELECT type_group,
       COUNT(*)                  AS schools,
       ROUND(AVG(att8), 1)       AS avg_att8,
       MIN(att8)                 AS min_att8,
       MAX(att8)                 AS max_att8
FROM   v_schools
GROUP  BY type_group
ORDER  BY avg_att8 DESC;


-- ============================================================
-- Q22 | BIVARIATE
-- Question: How does Attainment 8 vary by region for state-funded
--           schools?
-- Concept:  Numeric by category + difference from national
-- ============================================================
SELECT v.region,
       COUNT(*)                            AS schools,
       ROUND(AVG(v.att8), 1)               AS avg_att8,
       ROUND(AVG(v.att8) - nat.att8, 1)    AS vs_national
FROM   v_schools v
CROSS  JOIN (SELECT att8 FROM ks4_results WHERE rectype = 7) nat
WHERE  v.state_funded = 1
GROUP  BY v.region, nat.att8
ORDER  BY avg_att8 DESC;


-- ============================================================
-- Q23 | BIVARIATE
-- Question: How strongly is a school's share of disadvantaged
--           pupils linked to its Attainment 8? Calculate the
--           correlation across all state-funded schools.
-- Concept:  Aggregate formula for Pearson correlation (SUM, POW,
--           SQRT)
-- ============================================================
SELECT COUNT(*) AS schools,
       ROUND(
         (COUNT(*) * SUM(pct_disadv * att8) - SUM(pct_disadv) * SUM(att8))
         / SQRT( (COUNT(*) * SUM(POW(pct_disadv, 2)) - POW(SUM(pct_disadv), 2))
               * (COUNT(*) * SUM(POW(att8, 2))       - POW(SUM(att8), 2)) )
       , 2)     AS correlation_disadv_att8
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_disadv IS NOT NULL;


-- ============================================================
-- Q24 | BIVARIATE
-- Question: How does Attainment 8 differ between selective,
--           non-selective and "non-selective in a highly selective
--           area" state schools?
-- Concept:  Numeric by category
-- ============================================================
SELECT admissions,
       COUNT(*)                AS schools,
       ROUND(AVG(att8), 1)     AS avg_att8
FROM   v_schools
WHERE  state_funded = 1
  AND  admissions IS NOT NULL
  AND  admissions <> 'NA'
GROUP  BY admissions
ORDER  BY avg_att8 DESC;


-- ============================================================
-- Q25 | BIVARIATE
-- Question: Do girls', boys' and mixed state schools differ in
--           the share of pupils achieving grade 5+ in English and
--           maths?
-- Concept:  Numeric by category
-- ============================================================
SELECT gender                         AS school_gender,
       COUNT(*)                       AS schools,
       ROUND(AVG(pct_em_5plus), 1)    AS avg_pct_em_5plus
FROM   v_schools
WHERE  state_funded = 1
GROUP  BY gender
ORDER  BY avg_pct_em_5plus DESC;


-- ============================================================
-- Q26 | BIVARIATE
-- Question: Within the same schools, how much lower is Attainment
--           8 for disadvantaged pupils than for other pupils, and
--           in how many schools do disadvantaged pupils do better?
-- Concept:  Paired comparison of two columns + conditional COUNT
-- ============================================================
SELECT COUNT(*)                                          AS schools,
       ROUND(AVG(att8_disadv), 1)                        AS avg_att8_disadv,
       ROUND(AVG(att8_non_disadv), 1)                    AS avg_att8_non_disadv,
       ROUND(AVG(att8_non_disadv - att8_disadv), 1)      AS avg_gap,
       SUM(att8_disadv >= att8_non_disadv)               AS schools_no_gap
FROM   v_schools
WHERE  state_funded = 1
  AND  att8_disadv     IS NOT NULL
  AND  att8_non_disadv IS NOT NULL;


-- ============================================================
-- Q27 | BIVARIATE
-- Question: In mixed state schools, how do girls' and boys'
--           Attainment 8 compare, and in what share of schools do
--           girls outperform boys?
-- Concept:  Paired comparison of two columns + share
-- ============================================================
SELECT COUNT(*)                                             AS mixed_schools,
       ROUND(AVG(att8_girls), 1)                            AS avg_att8_girls,
       ROUND(AVG(att8_boys), 1)                             AS avg_att8_boys,
       ROUND(AVG(att8_girls - att8_boys), 1)                AS avg_gap,
       ROUND(100 * SUM(att8_girls > att8_boys) / COUNT(*), 1) AS pct_girls_ahead
FROM   v_schools
WHERE  state_funded = 1
  AND  gender = 'Mixed'
  AND  att8_girls IS NOT NULL
  AND  att8_boys  IS NOT NULL;


-- ============================================================
-- Q28 | BIVARIATE
-- Question: Is higher EBacc entry associated with higher
--           Attainment 8? Compare average Attainment 8 across
--           EBacc entry bands.
-- Concept:  CASE banding of one variable + AVG of another
-- ============================================================
SELECT CASE WHEN pct_ebacc_entry < 25 THEN '1. Under 25%'
            WHEN pct_ebacc_entry < 50 THEN '2. 25-49%'
            WHEN pct_ebacc_entry < 75 THEN '3. 50-74%'
            ELSE '4. 75%+' END              AS ebacc_entry_band,
       COUNT(*)                             AS schools,
       ROUND(AVG(att8), 1)                  AS avg_att8
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_ebacc_entry IS NOT NULL
GROUP  BY ebacc_entry_band
ORDER  BY ebacc_entry_band;


-- ============================================================
-- Q29 | BIVARIATE
-- Question: How did state schools' Attainment 8 in 2025 compare
--           with their own 2024 score? How many improved, held
--           steady (within 1 point) or declined?
-- Concept:  Paired comparison of two years + CASE grouping
-- ============================================================
SELECT CASE WHEN att8 - att8_2024 >  1 THEN '1. Improved (1+ point)'
            WHEN att8 - att8_2024 < -1 THEN '3. Declined (1+ point)'
            ELSE '2. Stable (within 1 point)' END    AS direction,
       COUNT(*)                                      AS schools,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_schools,
       ROUND(AVG(att8 - att8_2024), 1)               AS avg_change
FROM   v_schools
WHERE  state_funded = 1
  AND  att8_2024 IS NOT NULL
GROUP  BY direction
ORDER  BY direction;


-- ============================================================
-- Q30 | BIVARIATE
-- Question: How does Attainment 8 differ between urban, larger
--           rural and smaller rural state schools?
-- Concept:  Numeric by a derived (string function) category
-- ============================================================
SELECT urban_rural,
       COUNT(*)               AS schools,
       ROUND(AVG(att8), 1)    AS avg_att8
FROM   v_schools
WHERE  state_funded = 1
  AND  urban_rural IS NOT NULL
GROUP  BY urban_rural
ORDER  BY avg_att8 DESC;


-- ############################################################
-- SECTION 4: MULTIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q31 | MULTIVARIATE
-- Question: Split state schools into five equal groups by their
--           share of disadvantaged pupils. How do Attainment 8,
--           strong English and maths passes and EBacc entry change
--           from the least to the most disadvantaged fifth?
-- Concept:  CTE + window function (NTILE) + GROUP BY
-- ============================================================
WITH quintiles AS (
    SELECT v.*,
           NTILE(5) OVER (ORDER BY pct_disadv) AS disadv_quintile
    FROM   v_schools v
    WHERE  state_funded = 1
      AND  pct_disadv IS NOT NULL
)
SELECT disadv_quintile,
       COUNT(*)                        AS schools,
       MIN(pct_disadv)                 AS min_pct_disadv,
       MAX(pct_disadv)                 AS max_pct_disadv,
       ROUND(AVG(att8), 1)             AS avg_att8,
       ROUND(AVG(pct_em_5plus), 1)     AS avg_pct_em_5plus,
       ROUND(AVG(pct_ebacc_entry), 1)  AS avg_pct_ebacc_entry
FROM   quintiles
GROUP  BY disadv_quintile
ORDER  BY disadv_quintile;


-- ============================================================
-- Q32 | MULTIVARIATE
-- Question: Do state schools with a religious character perform
--           differently once their level of disadvantage is taken
--           into account? Compare faith and non-faith schools
--           within low, medium and high disadvantage bands.
-- Concept:  CASE banding + two-way GROUP BY
-- ============================================================
SELECT CASE WHEN religious_character IN ('None', 'Does not apply')
                 OR religious_character IS NULL
            THEN 'No religious character'
            ELSE 'Faith school' END                  AS faith_status,
       CASE WHEN pct_disadv < 20 THEN '1. Low (<20%)'
            WHEN pct_disadv < 40 THEN '2. Medium (20-40%)'
            ELSE '3. High (40%+)' END                AS disadv_band,
       COUNT(*)                                      AS schools,
       ROUND(AVG(att8), 1)                           AS avg_att8,
       ROUND(AVG(att8_disadv), 1)                    AS avg_att8_disadv
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_disadv IS NOT NULL
GROUP  BY faith_status, disadv_band
ORDER  BY disadv_band, faith_status;


-- ============================================================
-- Q33 | MULTIVARIATE
-- Question: In each region, how large is the gap in Attainment 8
--           between disadvantaged and other pupils, and in the
--           share achieving grade 5+ in English and maths?
-- Concept:  GROUP BY + two derived gap measures
-- ============================================================
SELECT region,
       COUNT(*)                                                   AS schools,
       ROUND(AVG(pct_disadv), 1)                                  AS avg_pct_disadv,
       ROUND(AVG(att8_disadv), 1)                                 AS att8_disadv,
       ROUND(AVG(att8_non_disadv), 1)                             AS att8_non_disadv,
       ROUND(AVG(att8_non_disadv) - AVG(att8_disadv), 1)          AS att8_gap,
       ROUND(AVG(pct_em_5plus_non_disadv)
             - AVG(pct_em_5plus_disadv), 1)                       AS em_5plus_gap_pts
FROM   v_schools
WHERE  state_funded = 1
  AND  att8_disadv IS NOT NULL
  AND  att8_non_disadv IS NOT NULL
GROUP  BY region
ORDER  BY att8_gap;


-- ============================================================
-- Q34 | MULTIVARIATE
-- Question: Which state schools are "beating the odds": in the top
--           quarter for disadvantage, yet with Attainment 8 above
--           the national state-funded average? Show the 20 highest
--           scoring.
-- Concept:  CTE + window function (PERCENT_RANK) + benchmark
--           subquery
-- ============================================================
WITH ranked AS (
    SELECT v.*,
           PERCENT_RANK() OVER (ORDER BY pct_disadv) AS disadv_pr
    FROM   v_schools v
    WHERE  state_funded = 1
      AND  pct_disadv IS NOT NULL
      AND  ks4_pupils >= 10
)
SELECT school_name,
       la_name,
       type_name,
       ks4_pupils,
       pct_disadv,
       att8,
       (SELECT att8 FROM ks4_results WHERE rectype = 7) AS national_att8
FROM   ranked
WHERE  disadv_pr >= 0.75
  AND  att8 > (SELECT att8 FROM ks4_results WHERE rectype = 7)
ORDER  BY att8 DESC
LIMIT  20;


-- ============================================================
-- Q35 | MULTIVARIATE
-- Question: How do the share of pupils with English as an
--           additional language and disadvantage combine? Compare
--           Attainment 8 for schools grouped by both.
-- Concept:  Two CASE bandings + cross-tab with conditional
--           aggregation
-- ============================================================
SELECT CASE WHEN pct_eal < 10 THEN '1. Low EAL (<10%)'
            WHEN pct_eal < 30 THEN '2. Medium EAL (10-30%)'
            ELSE '3. High EAL (30%+)' END                       AS eal_band,
       COUNT(*)                                                 AS schools,
       ROUND(AVG(CASE WHEN pct_disadv <  20 THEN att8 END), 1)  AS att8_low_disadv,
       ROUND(AVG(CASE WHEN pct_disadv >= 20 AND pct_disadv < 40
                      THEN att8 END), 1)                        AS att8_mid_disadv,
       ROUND(AVG(CASE WHEN pct_disadv >= 40 THEN att8 END), 1)  AS att8_high_disadv
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_eal IS NOT NULL
  AND  pct_disadv IS NOT NULL
GROUP  BY eal_band
ORDER  BY eal_band;


-- ============================================================
-- Q36 | MULTIVARIATE
-- Question: Is the link between disadvantage and attainment
--           stronger in some regions than others? Calculate the
--           correlation within each region alongside its average
--           disadvantage and Attainment 8.
-- Concept:  Pearson correlation formula + GROUP BY
-- ============================================================
SELECT region,
       COUNT(*)                                            AS schools,
       ROUND(AVG(pct_disadv), 1)                           AS avg_pct_disadv,
       ROUND(AVG(att8), 1)                                 AS avg_att8,
       ROUND(
         (COUNT(*) * SUM(pct_disadv * att8) - SUM(pct_disadv) * SUM(att8))
         / SQRT( (COUNT(*) * SUM(POW(pct_disadv, 2)) - POW(SUM(pct_disadv), 2))
               * (COUNT(*) * SUM(POW(att8, 2))       - POW(SUM(att8), 2)) )
       , 2)                                                AS correlation
FROM   v_schools
WHERE  state_funded = 1
  AND  pct_disadv IS NOT NULL
GROUP  BY region
ORDER  BY correlation;


-- ============================================================
-- Q37 | MULTIVARIATE
-- Question: Using the LA benchmarks, which local authorities have
--           above-average disadvantage but still beat the national
--           Attainment 8, and how do their disadvantaged pupils
--           do?
-- Concept:  Uses v_la_benchmarks + CROSS JOIN to the national row
-- ============================================================
SELECT la.la_name,
       la.dfe_region,
       la.pct_disadv,
       nat.pct_disadv                    AS national_pct_disadv,
       la.att8,
       nat.att8                          AS national_att8,
       ROUND(la.att8 - nat.att8, 1)      AS att8_vs_national,
       la.att8_disadv
FROM   v_la_benchmarks la
CROSS  JOIN (SELECT pct_disadv, att8
             FROM   ks4_results
             WHERE  rectype = 7) nat
WHERE  la.pct_disadv > nat.pct_disadv
  AND  la.att8       > nat.att8
ORDER  BY att8_vs_national DESC;


-- ============================================================
-- Q38 | MULTIVARIATE
-- Question: Within each region, how do academies and LA
--           maintained schools compare on disadvantage and
--           Attainment 8?
-- Concept:  Two-way GROUP BY (region x type group) + HAVING
-- ============================================================
SELECT region,
       type_group,
       COUNT(*)                     AS schools,
       ROUND(AVG(pct_disadv), 1)    AS avg_pct_disadv,
       ROUND(AVG(att8), 1)          AS avg_att8
FROM   v_schools
WHERE  type_group IN ('Academy', 'LA maintained')
GROUP  BY region, type_group
HAVING COUNT(*) >= 10
ORDER  BY region, type_group;


-- ============================================================
-- Q39 | MULTIVARIATE
-- Question: Among multi-academy trusts running five or more
--           secondary schools in the KS4 tables, which have the
--           highest and lowest average Attainment 8, and how
--           disadvantaged are their intakes?
-- Concept:  CTE + GROUP BY/HAVING + window functions (RANK both
--           ways)
-- ============================================================
WITH trusts AS (
    SELECT trust_name,
           COUNT(*)                         AS schools,
           SUM(ks4_pupils)                  AS ks4_pupils,
           ROUND(AVG(pct_disadv), 1)        AS avg_pct_disadv,
           ROUND(AVG(att8), 1)              AS avg_att8,
           ROUND(AVG(att8_disadv), 1)       AS avg_att8_disadv
    FROM   v_schools
    WHERE  type_group IN ('Academy', 'Free school')
      AND  trust_name IS NOT NULL
    GROUP  BY trust_name
    HAVING COUNT(*) >= 5
),
ranked AS (
    SELECT t.*,
           RANK() OVER (ORDER BY avg_att8 DESC) AS top_rank,
           RANK() OVER (ORDER BY avg_att8 ASC)  AS bottom_rank
    FROM   trusts t
)
SELECT CASE WHEN top_rank <= 10 THEN 'Top 10' ELSE 'Bottom 10' END AS grp,
       trust_name,
       schools,
       ks4_pupils,
       avg_pct_disadv,
       avg_att8,
       avg_att8_disadv
FROM   ranked
WHERE  top_rank <= 10
   OR  bottom_rank <= 10
ORDER  BY avg_att8 DESC;


-- ============================================================
-- Q40 | MULTIVARIATE
-- Question: In each local authority, which state school has the
--           highest Attainment 8, and how do its disadvantage
--           rate and English and maths results compare with the
--           LA's lowest scoring school?
-- Concept:  CTE + window functions (ROW_NUMBER both ways, COUNT
--           OVER) + self-join of the top and bottom rows
-- ============================================================
WITH ranked AS (
    SELECT la_name,
           region,
           school_name,
           pct_disadv,
           att8,
           pct_em_5plus,
           ROW_NUMBER() OVER (PARTITION BY la_name ORDER BY att8 DESC) AS top_rn,
           ROW_NUMBER() OVER (PARTITION BY la_name ORDER BY att8 ASC)  AS bottom_rn,
           COUNT(*)     OVER (PARTITION BY la_name)                   AS la_schools
    FROM   v_schools
    WHERE  state_funded = 1
      AND  ks4_pupils >= 10
)
SELECT t.la_name,
       t.region,
       t.la_schools,
       t.school_name                     AS top_school,
       t.pct_disadv                      AS top_pct_disadv,
       t.att8                            AS top_att8,
       t.pct_em_5plus                    AS top_pct_em_5plus,
       b.school_name                     AS bottom_school,
       b.pct_disadv                      AS bottom_pct_disadv,
       b.att8                            AS bottom_att8,
       b.pct_em_5plus                    AS bottom_pct_em_5plus
FROM   ranked t
JOIN   ranked b ON b.la_name = t.la_name AND b.bottom_rn = 1
WHERE  t.top_rn = 1
  AND  t.la_schools >= 5
ORDER  BY t.region, t.la_name;
