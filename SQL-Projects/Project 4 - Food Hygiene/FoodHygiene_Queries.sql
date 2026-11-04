-- ============================================================
-- FOOD HYGIENE RATINGS PROJECT: ANALYSIS QUERIES
-- Project type: Type 1 (40 questions)
--   Q1-Q10   KPI           headline figures and benchmarks
--   Q11-Q20  Univariate    one variable: its distribution
--   Q21-Q30  Bivariate     two variables: how one varies with
--                          the other
--   Q31-Q40  Multivariate  three or more variables together
-- Perspective:  Food safety compliance
-- End consumer: Local authority environmental health manager
-- Data:         FSA Food Hygiene Rating Scheme open data,
--               all UK local authorities
-- ============================================================
-- Conventions
--   * "Rated" = a business with an FHRS rating of 0-5
--     (England, Wales and Northern Ireland). Scotland's FHIS
--     scheme (Pass / Improvement Required) is covered
--     separately where noted.
--   * "Broadly compliant" = rated 3 or above; "below 3" = rated
--     0, 1 or 2 (improvement necessary or worse).
--   * Sub-scores (hygiene, structural, confidence in
--     management) are penalty points: LOWER IS BETTER. Hygiene
--     and structural run 0-25, confidence 0-30.
--   * Rating age is measured to the latest rating date in the
--     file (the reference date), so results do not change
--     depending on the day the queries are run.
--   * A "chain" is a business name that appears 50 or more
--     times in the file (after trimming and upper-casing).
-- Views
--   v_establishments  created Q1, reused throughout
--   v_la_summary      created Q10, reused Q33, Q34
-- Run fsa_setup.sql first. This file then runs top to bottom.
-- ============================================================

USE food_hygiene;


-- ############################################################
-- SECTION 1: KPI QUESTIONS
-- ############################################################

-- ============================================================
-- Q1 | KPI
-- Question: Create a reusable view joining establishments to their
--           business type, sector, local authority and nation.
--           Using it, how many food businesses are listed, and how
--           many are rated, unrated or exempt under each scheme?
-- Concept:  VIEW over a 4-table join + conditional COUNT KPIs
-- Creates view: v_establishments (reused throughout)
-- ============================================================
CREATE OR REPLACE VIEW v_establishments AS
SELECT e.fhrsid,
       e.business_name,
       UPPER(TRIM(e.business_name))                   AS name_key,
       bt.business_type,
       bt.sector,
       e.la_code,
       la.la_name,
       la.nation,
       e.scheme_type,
       e.rating_value,
       e.rating_num,
       rd.description                                 AS rating_description,
       e.rating_date,
       DATEDIFF(ref.ref_date, e.rating_date) / 365.25 AS years_since_rating,
       e.hygiene,
       e.structural,
       e.confidence,
       e.hygiene + e.structural + e.confidence        AS total_score,
       e.postcode,
       REGEXP_SUBSTR(e.postcode, '^[A-Z]+')           AS postcode_area,
       e.latitude,
       e.new_rating_pending,
       e.has_right_to_reply
FROM   establishments e
JOIN   business_types      bt ON bt.business_type_id = e.business_type_id
JOIN   local_authorities   la ON la.la_code          = e.la_code
LEFT   JOIN rating_descriptions rd ON rd.rating_num  = e.rating_num
CROSS  JOIN (SELECT MAX(rating_date) AS ref_date FROM establishments) ref;

SELECT scheme_type,
       COUNT(*)                                               AS establishments,
       SUM(rating_num IS NOT NULL
           OR rating_value IN ('Pass', 'Pass and Eat Safe',
                               'Improvement Required'))       AS rated,
       SUM(rating_value = 'AwaitingInspection')               AS awaiting_inspection,
       SUM(rating_value = 'Exempt')                           AS exempt,
       SUM(rating_value = 'AwaitingPublication')              AS awaiting_publication
FROM   v_establishments
GROUP  BY scheme_type
ORDER  BY establishments DESC;


-- ============================================================
-- Q2 | KPI
-- Question: Across all FHRS-rated businesses, what is the average
--           rating, and what share hold the top rating of 5?
-- Concept:  AVG + conditional share
-- ============================================================
SELECT COUNT(*)                                     AS rated_businesses,
       ROUND(AVG(rating_num), 2)                    AS avg_rating,
       SUM(rating_num = 5)                          AS rated_5,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1) AS pct_rated_5
FROM   v_establishments
WHERE  rating_num IS NOT NULL;


-- ============================================================
-- Q3 | KPI
-- Question: What share of rated businesses are broadly compliant
--           (rated 3 or above), and how many are below 3?
-- Concept:  Conditional aggregation KPIs
-- ============================================================
SELECT SUM(rating_num >= 3)                              AS broadly_compliant,
       ROUND(100 * SUM(rating_num >= 3) / COUNT(*), 1)   AS pct_broadly_compliant,
       SUM(rating_num < 3)                               AS below_3,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)    AS pct_below_3
FROM   v_establishments
WHERE  rating_num IS NOT NULL;


-- ============================================================
-- Q4 | KPI
-- Question: How many businesses are rated 0 ("urgent improvement
--           necessary"), and which business types account for
--           most of them?
-- Concept:  Filter + GROUP BY + share of total (window SUM OVER)
-- ============================================================
SELECT business_type,
       COUNT(*)                                            AS rated_0,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_all_0s
FROM   v_establishments
WHERE  rating_num = 0
GROUP  BY business_type
ORDER  BY rated_0 DESC;


-- ============================================================
-- Q5 | KPI
-- Question: How large is the inspection backlog: how many FHRS
--           businesses are awaiting their first inspection, as a
--           share of all FHRS businesses?
-- Concept:  Conditional COUNT + share KPI
-- ============================================================
SELECT COUNT(*)                                                     AS fhrs_businesses,
       SUM(rating_value = 'AwaitingInspection')                     AS awaiting_inspection,
       ROUND(100 * SUM(rating_value = 'AwaitingInspection') / COUNT(*), 1) AS pct_awaiting
FROM   v_establishments
WHERE  scheme_type = 'FHRS';


-- ============================================================
-- Q6 | KPI
-- Question: Under Scotland's FHIS scheme, what share of inspected
--           businesses pass, and how many need improvement?
-- Concept:  Conditional aggregation on text categories
-- ============================================================
SELECT SUM(rating_value IN ('Pass', 'Pass and Eat Safe'))           AS pass,
       SUM(rating_value = 'Pass and Eat Safe')                      AS of_which_eat_safe,
       SUM(rating_value = 'Improvement Required')                   AS improvement_required,
       ROUND(100 * SUM(rating_value IN ('Pass', 'Pass and Eat Safe'))
             / SUM(rating_value IN ('Pass', 'Pass and Eat Safe',
                                    'Improvement Required')), 1)    AS pct_pass
FROM   v_establishments
WHERE  scheme_type = 'FHIS';


-- ============================================================
-- Q7 | KPI
-- Question: How up to date are ratings? What is the average age of
--           an FHRS rating, and what share are more than two and
--           more than five years old?
-- Concept:  Date arithmetic (DATEDIFF) + conditional shares
-- ============================================================
SELECT ROUND(AVG(years_since_rating), 1)                            AS avg_age_years,
       ROUND(100 * SUM(years_since_rating > 2) / COUNT(*), 1)       AS pct_over_2_years,
       ROUND(100 * SUM(years_since_rating > 5) / COUNT(*), 1)       AS pct_over_5_years
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  rating_date IS NOT NULL;


-- ============================================================
-- Q8 | KPI
-- Question: What are the average hygiene, structural and
--           confidence-in-management penalty scores, and what
--           share of rated businesses scored a perfect 0 on all
--           three?
-- Concept:  Several AVG KPIs + compound condition
-- ============================================================
SELECT ROUND(AVG(hygiene), 2)       AS avg_hygiene,
       ROUND(AVG(structural), 2)    AS avg_structural,
       ROUND(AVG(confidence), 2)    AS avg_confidence,
       ROUND(AVG(total_score), 2)   AS avg_total,
       ROUND(100 * SUM(hygiene = 0 AND structural = 0 AND confidence = 0)
             / COUNT(*), 1)         AS pct_perfect
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  hygiene IS NOT NULL;


-- ============================================================
-- Q9 | KPI
-- Question: How many ratings were issued in the 12 months before
--           the reference date, and what share of those were
--           rated 5 and below 3?
-- Concept:  Date window filter + KPIs
-- ============================================================
SELECT COUNT(*)                                          AS ratings_last_12m,
       ROUND(COUNT(*) / 12, 0)                           AS avg_per_month,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)    AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)    AS pct_below_3
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  years_since_rating <= 1;


-- ============================================================
-- Q10 | KPI
-- Question: Create a reusable view summarising each local
--           authority. Using it, how many FHRS authorities have
--           at least 95% of rated businesses broadly compliant,
--           and how many have more than 5% below 3?
-- Concept:  VIEW (LA-level aggregation) + conditional KPIs
-- Creates view: v_la_summary (reused Q33, Q34)
-- ============================================================
CREATE OR REPLACE VIEW v_la_summary AS
SELECT la_code,
       la_name,
       nation,
       COUNT(*)                                                    AS establishments,
       SUM(rating_num IS NOT NULL)                                 AS rated,
       ROUND(AVG(rating_num), 2)                                   AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / SUM(rating_num IS NOT NULL), 1) AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / SUM(rating_num IS NOT NULL), 1) AS pct_below_3,
       ROUND(100 * SUM(rating_value = 'AwaitingInspection') / COUNT(*), 1) AS pct_awaiting,
       ROUND(AVG(CASE WHEN rating_num IS NOT NULL
                      THEN years_since_rating END), 1)             AS avg_rating_age
FROM   v_establishments
WHERE  scheme_type = 'FHRS'
GROUP  BY la_code, la_name, nation;

SELECT COUNT(*)                                       AS fhrs_authorities,
       SUM(pct_below_3 <= 5)                          AS las_95pct_compliant,
       ROUND(100 * SUM(pct_below_3 <= 5) / COUNT(*), 1) AS pct_las_95pct_compliant,
       SUM(pct_below_3 > 5)                           AS las_over_5pct_below_3
FROM   v_la_summary
WHERE  rated >= 100;


-- ############################################################
-- SECTION 2: UNIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q11 | UNIVARIATE
-- Question: How are FHRS ratings distributed from 0 to 5, with the
--           FSA's description of each?
-- Concept:  Frequency table with a join to a lookup + share
-- ============================================================
SELECT rd.rating_num,
       rd.description,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_rated
FROM   establishments e
JOIN   rating_descriptions rd ON rd.rating_num = e.rating_num
GROUP  BY rd.rating_num, rd.description
ORDER  BY rd.rating_num DESC;


-- ============================================================
-- Q12 | UNIVARIATE
-- Question: What does the full list of rating values look like,
--           including the non-numeric statuses, across both
--           schemes?
-- Concept:  Frequency table over a text column + share
-- ============================================================
SELECT scheme_type,
       rating_value,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_all
FROM   establishments
GROUP  BY scheme_type, rating_value
ORDER  BY businesses DESC;


-- ============================================================
-- Q13 | UNIVARIATE
-- Question: How are hygiene penalty scores distributed among rated
--           businesses?
-- Concept:  Frequency of a discrete numeric variable
-- ============================================================
SELECT hygiene,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct
FROM   establishments
WHERE  rating_num IS NOT NULL
  AND  hygiene IS NOT NULL
GROUP  BY hygiene
ORDER  BY hygiene;


-- ============================================================
-- Q14 | UNIVARIATE
-- Question: How are structural penalty scores distributed among
--           rated businesses?
-- Concept:  Frequency of a discrete numeric variable
-- ============================================================
SELECT structural,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct
FROM   establishments
WHERE  rating_num IS NOT NULL
  AND  structural IS NOT NULL
GROUP  BY structural
ORDER  BY structural;


-- ============================================================
-- Q15 | UNIVARIATE
-- Question: How are confidence-in-management penalty scores
--           distributed among rated businesses?
-- Concept:  Frequency of a discrete numeric variable + running
--           (cumulative) share
-- ============================================================
SELECT confidence,
       COUNT(*)                                                   AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct,
       ROUND(100 * SUM(COUNT(*)) OVER (ORDER BY confidence)
             / SUM(COUNT(*)) OVER (), 1)                          AS cumulative_pct
FROM   establishments
WHERE  rating_num IS NOT NULL
  AND  confidence IS NOT NULL
GROUP  BY confidence
ORDER  BY confidence;


-- ============================================================
-- Q16 | UNIVARIATE
-- Question: Which types of food business are most common?
-- Concept:  Frequency table (join to lookup) + share
-- ============================================================
SELECT bt.business_type,
       bt.sector,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct
FROM   establishments e
JOIN   business_types bt ON bt.business_type_id = e.business_type_id
GROUP  BY bt.business_type, bt.sector
ORDER  BY businesses DESC;


-- ============================================================
-- Q17 | UNIVARIATE
-- Question: In which year was each current FHRS rating issued?
-- Concept:  CTE + YEAR() + share and running total (window SUM)
-- ============================================================
WITH dated AS (
    SELECT YEAR(rating_date) AS rating_year
    FROM   establishments
    WHERE  rating_num IS NOT NULL
      AND  rating_date IS NOT NULL
)
SELECT rating_year,
       COUNT(*)                                                   AS ratings,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS pct,
       ROUND(100 * SUM(COUNT(*)) OVER (ORDER BY rating_year DESC)
             / SUM(COUNT(*)) OVER (), 1)                          AS pct_this_year_or_newer
FROM   dated
GROUP  BY rating_year
ORDER  BY rating_year DESC;


-- ============================================================
-- Q18 | UNIVARIATE
-- Question: How many food businesses does each local authority
--           cover? Show the summary statistics and quartiles.
-- Concept:  CTE + window functions (ROW_NUMBER, COUNT OVER) for
--           percentiles + summary statistics
-- ============================================================
WITH la_counts AS (
    SELECT la_code, COUNT(*) AS businesses
    FROM   establishments
    GROUP  BY la_code
),
ordered AS (
    SELECT businesses,
           ROW_NUMBER() OVER (ORDER BY businesses) AS rn,
           COUNT(*)     OVER ()                    AS n
    FROM   la_counts
)
SELECT MAX(n)                                                AS local_authorities,
       MIN(businesses)                                       AS smallest,
       MAX(CASE WHEN rn = CEIL(0.25 * n) THEN businesses END) AS lower_quartile,
       MAX(CASE WHEN rn = CEIL(0.50 * n) THEN businesses END) AS median,
       MAX(CASE WHEN rn = CEIL(0.75 * n) THEN businesses END) AS upper_quartile,
       MAX(businesses)                                       AS largest,
       ROUND(AVG(businesses), 0)                             AS mean
FROM   ordered;


-- ============================================================
-- Q19 | UNIVARIATE
-- Question: How is the total penalty score (hygiene + structural +
--           confidence) distributed? Group rated businesses into
--           score bands.
-- Concept:  CTE + CASE banding + share
-- ============================================================
WITH scored AS (
    SELECT CASE WHEN total_score = 0  THEN '1. 0 (perfect)'
                WHEN total_score <= 15 THEN '2. 1-15'
                WHEN total_score <= 30 THEN '3. 16-30'
                WHEN total_score <= 45 THEN '4. 31-45'
                ELSE '5. Over 45' END AS score_band
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
      AND  total_score IS NOT NULL
)
SELECT score_band,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct
FROM   scored
GROUP  BY score_band
ORDER  BY score_band;


-- ============================================================
-- Q20 | UNIVARIATE
-- Question: Which 15 postcode areas have the most food businesses?
-- Concept:  Derived column (REGEXP_SUBSTR) + GROUP BY + LIMIT
-- ============================================================
SELECT postcode_area,
       COUNT(*)                                            AS businesses,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS pct_of_uk
FROM   v_establishments
WHERE  postcode_area IS NOT NULL
GROUP  BY postcode_area
ORDER  BY businesses DESC
LIMIT  15;


-- ############################################################
-- SECTION 3: BIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q21 | BIVARIATE
-- Question: How do average ratings and the share below 3 vary by
--           business type?
-- Concept:  Numeric by category: GROUP BY with AVG + share
-- ============================================================
SELECT business_type,
       COUNT(*)                                            AS rated,
       ROUND(AVG(rating_num), 2)                           AS avg_rating,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)      AS pct_below_3
FROM   v_establishments
WHERE  rating_num IS NOT NULL
GROUP  BY business_type
ORDER  BY avg_rating;


-- ============================================================
-- Q22 | BIVARIATE
-- Question: How does the share of businesses rated 5 compare across
--           the broader sectors?
-- Concept:  Numeric by category
-- ============================================================
SELECT sector,
       COUNT(*)                                            AS rated,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)      AS pct_rated_5,
       ROUND(AVG(rating_num), 2)                           AS avg_rating
FROM   v_establishments
WHERE  rating_num IS NOT NULL
GROUP  BY sector
ORDER  BY pct_rated_5 DESC;


-- ============================================================
-- Q23 | BIVARIATE
-- Question: How do ratings compare between England, Wales and
--           Northern Ireland?
-- Concept:  Numeric by category (nation)
-- ============================================================
SELECT nation,
       COUNT(*)                                            AS rated,
       ROUND(AVG(rating_num), 2)                           AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)      AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)      AS pct_below_3
FROM   v_establishments
WHERE  rating_num IS NOT NULL
GROUP  BY nation
ORDER  BY avg_rating DESC;


-- ============================================================
-- Q24 | BIVARIATE
-- Question: Are older ratings lower or higher? Compare the average
--           rating across bands of rating age.
-- Concept:  CTE + CASE banding of one variable + AVG of another
-- ============================================================
WITH aged AS (
    SELECT rating_num,
           CASE WHEN years_since_rating <= 1 THEN '1. Under 1 year'
                WHEN years_since_rating <= 2 THEN '2. 1-2 years'
                WHEN years_since_rating <= 3 THEN '3. 2-3 years'
                WHEN years_since_rating <= 5 THEN '4. 3-5 years'
                ELSE '5. Over 5 years' END AS age_band
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
      AND  rating_date IS NOT NULL
)
SELECT age_band,
       COUNT(*)                                            AS rated,
       ROUND(AVG(rating_num), 2)                           AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)      AS pct_rated_5
FROM   aged
GROUP  BY age_band
ORDER  BY age_band;


-- ============================================================
-- Q25 | BIVARIATE
-- Question: How closely are a business's hygiene and structural
--           scores linked? Calculate the correlation.
-- Concept:  Aggregate formula for Pearson correlation
-- ============================================================
SELECT COUNT(*) AS businesses,
       ROUND(
         (COUNT(*) * SUM(hygiene * structural) - SUM(hygiene) * SUM(structural))
         / SQRT( (COUNT(*) * SUM(POW(hygiene, 2))    - POW(SUM(hygiene), 2))
               * (COUNT(*) * SUM(POW(structural, 2)) - POW(SUM(structural), 2)) )
       , 2)     AS correlation_hygiene_structural
FROM   establishments
WHERE  rating_num IS NOT NULL
  AND  hygiene    IS NOT NULL
  AND  structural IS NOT NULL;


-- ============================================================
-- Q26 | BIVARIATE
-- Question: For each rating from 0 to 5, what is the typical
--           confidence-in-management score?
-- Concept:  GROUP BY one variable + AVG, MIN, MAX of another
-- ============================================================
SELECT rating_num,
       COUNT(*)                     AS rated,
       ROUND(AVG(confidence), 1)    AS avg_confidence,
       MIN(confidence)              AS min_confidence,
       MAX(confidence)              AS max_confidence
FROM   establishments
WHERE  rating_num IS NOT NULL
  AND  confidence IS NOT NULL
GROUP  BY rating_num
ORDER  BY rating_num DESC;


-- ============================================================
-- Q27 | BIVARIATE
-- Question: Do businesses that have published a right to reply
--           have lower ratings than those that have not?
-- Concept:  Numeric by a flag (two groups)
-- ============================================================
SELECT CASE WHEN has_right_to_reply = 1 THEN 'Right to reply published'
            ELSE 'No right to reply' END            AS right_to_reply,
       COUNT(*)                                     AS rated,
       ROUND(AVG(rating_num), 2)                    AS avg_rating,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1) AS pct_below_3
FROM   establishments
WHERE  rating_num IS NOT NULL
GROUP  BY right_to_reply
ORDER  BY avg_rating;


-- ============================================================
-- Q28 | BIVARIATE
-- Question: Does the month of inspection make a difference? Show
--           the share rated 5 by calendar month for ratings issued
--           in the last three years.
-- Concept:  GROUP BY on MONTH() / MONTHNAME() + share
-- ============================================================
SELECT MONTH(rating_date)                               AS month_no,
       MONTHNAME(rating_date)                           AS month_name,
       COUNT(*)                                         AS rated,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)   AS pct_rated_5
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  years_since_rating <= 3
GROUP  BY MONTH(rating_date), MONTHNAME(rating_date)
ORDER  BY month_no;


-- ============================================================
-- Q29 | BIVARIATE
-- Question: Is there a north-south pattern? Compare average
--           ratings across bands of latitude.
-- Concept:  CTE + FLOOR banding of a numeric variable + AVG
-- ============================================================
WITH banded AS (
    SELECT FLOOR(latitude) AS lat_band, rating_num
    FROM   establishments
    WHERE  rating_num IS NOT NULL
      AND  latitude   IS NOT NULL
)
SELECT CONCAT(lat_band, '-', lat_band + 1, ' N')        AS latitude_band,
       COUNT(*)                                         AS rated,
       ROUND(AVG(rating_num), 2)                        AS avg_rating,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)   AS pct_below_3
FROM   banded
GROUP  BY lat_band
ORDER  BY lat_band DESC;


-- ============================================================
-- Q30 | BIVARIATE
-- Question: Do chain businesses (names appearing 50+ times) score
--           better than independents?
-- Concept:  CTE + window COUNT OVER (PARTITION BY name) + group
--           comparison
-- ============================================================
WITH named AS (
    SELECT rating_num,
           COUNT(*) OVER (PARTITION BY name_key) AS name_count
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
)
SELECT CASE WHEN name_count >= 50 THEN 'Chain (50+ outlets)'
            ELSE 'Independent' END                     AS ownership,
       COUNT(*)                                        AS rated,
       ROUND(AVG(rating_num), 2)                       AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)  AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)  AS pct_below_3
FROM   named
GROUP  BY ownership
ORDER  BY avg_rating DESC;


-- ############################################################
-- SECTION 4: MULTIVARIATE QUESTIONS
-- ############################################################

-- ============================================================
-- Q31 | MULTIVARIATE
-- Question: How do ratings vary by sector within each nation?
-- Concept:  Two-way GROUP BY (nation x sector) + several measures
-- ============================================================
SELECT nation,
       sector,
       COUNT(*)                                         AS rated,
       ROUND(AVG(rating_num), 2)                        AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)   AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)   AS pct_below_3
FROM   v_establishments
WHERE  rating_num IS NOT NULL
GROUP  BY nation, sector
ORDER  BY nation, avg_rating DESC;


-- ============================================================
-- Q32 | MULTIVARIATE
-- Question: For the main hospitality business types, how does the
--           share rated 5 change as ratings get older?
-- Concept:  CASE banding + cross-tab with conditional aggregation
-- ============================================================
SELECT business_type,
       COUNT(*)                                                        AS rated,
       ROUND(100 * SUM(CASE WHEN years_since_rating <= 1 THEN rating_num = 5 END)
             / SUM(years_since_rating <= 1), 1)                        AS pct5_under_1yr,
       ROUND(100 * SUM(CASE WHEN years_since_rating > 1
                             AND years_since_rating <= 3 THEN rating_num = 5 END)
             / SUM(years_since_rating > 1 AND years_since_rating <= 3), 1) AS pct5_1_to_3yrs,
       ROUND(100 * SUM(CASE WHEN years_since_rating > 3 THEN rating_num = 5 END)
             / SUM(years_since_rating > 3), 1)                         AS pct5_over_3yrs
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  rating_date IS NOT NULL
  AND  sector = 'Hospitality'
GROUP  BY business_type
ORDER  BY pct5_under_1yr;


-- ============================================================
-- Q33 | MULTIVARIATE
-- Question: Using the LA summary, which are the five best and five
--           worst local authorities in each nation by share of
--           businesses below 3 (200+ rated businesses)?
-- Concept:  Uses v_la_summary + CTE + window functions (RANK
--           partitioned by nation, both ways)
-- ============================================================
WITH ranked AS (
    SELECT s.*,
           RANK() OVER (PARTITION BY nation ORDER BY pct_below_3 ASC)  AS best_rank,
           RANK() OVER (PARTITION BY nation ORDER BY pct_below_3 DESC) AS worst_rank
    FROM   v_la_summary s
    WHERE  rated >= 200
)
SELECT nation,
       CASE WHEN best_rank <= 5 THEN 'Best 5' ELSE 'Worst 5' END AS grp,
       la_name,
       rated,
       pct_below_3,
       pct_rated_5,
       avg_rating
FROM   ranked
WHERE  best_rank <= 5
   OR  worst_rank <= 5
ORDER  BY nation, pct_below_3;


-- ============================================================
-- Q34 | MULTIVARIATE
-- Question: Using the LA summary, which authorities combine a high
--           share of businesses below 3, a large inspection backlog
--           and old ratings? Show those above the national figure
--           on all three (200+ rated).
-- Concept:  Uses v_la_summary + CROSS JOIN to national averages +
--           multi-condition filter
-- ============================================================
SELECT s.la_name,
       s.nation,
       s.rated,
       s.pct_below_3,
       nat.pct_below_3       AS national_pct_below_3,
       s.pct_awaiting,
       nat.pct_awaiting      AS national_pct_awaiting,
       s.avg_rating_age,
       nat.avg_rating_age    AS national_avg_age
FROM   v_la_summary s
CROSS  JOIN (SELECT ROUND(100 * SUM(rating_num < 3) / SUM(rating_num IS NOT NULL), 1) AS pct_below_3,
                    ROUND(100 * SUM(rating_value = 'AwaitingInspection') / COUNT(*), 1) AS pct_awaiting,
                    ROUND(AVG(CASE WHEN rating_num IS NOT NULL
                                   THEN years_since_rating END), 1) AS avg_rating_age
             FROM   v_establishments
             WHERE  scheme_type = 'FHRS') nat
WHERE  s.rated >= 200
  AND  s.pct_below_3    > nat.pct_below_3
  AND  s.pct_awaiting   > nat.pct_awaiting
  AND  s.avg_rating_age > nat.avg_rating_age
ORDER  BY s.pct_below_3 DESC;


-- ============================================================
-- Q35 | MULTIVARIATE
-- Question: For each business type, which of the three sub-scores
--           is the weakest on average, and by how much?
-- Concept:  GROUP BY + three AVGs + GREATEST / CASE to pick the
--           weakest area
-- ============================================================
WITH scores AS (
    SELECT business_type,
           COUNT(*)              AS rated,
           AVG(hygiene)          AS avg_hygiene,
           AVG(structural)       AS avg_structural,
           AVG(confidence)       AS avg_confidence
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
      AND  hygiene IS NOT NULL
    GROUP  BY business_type
)
SELECT business_type,
       rated,
       ROUND(avg_hygiene, 2)      AS avg_hygiene,
       ROUND(avg_structural, 2)   AS avg_structural,
       ROUND(avg_confidence, 2)   AS avg_confidence,
       CASE GREATEST(avg_hygiene, avg_structural, avg_confidence)
            WHEN avg_hygiene    THEN 'Hygiene'
            WHEN avg_structural THEN 'Structural'
            ELSE 'Confidence in management' END AS weakest_area
FROM   scores
ORDER  BY avg_hygiene + avg_structural + avg_confidence DESC;


-- ============================================================
-- Q36 | MULTIVARIATE
-- Question: Which 20 postcode areas have the highest share of
--           businesses below 3 (1,000+ rated), and how does that
--           relate to their share of takeaways and their average
--           rating?
-- Concept:  Derived column + GROUP BY with several conditional
--           aggregates + HAVING
-- ============================================================
SELECT postcode_area,
       COUNT(*)                                                       AS rated,
       ROUND(AVG(rating_num), 2)                                      AS avg_rating,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)                 AS pct_below_3,
       ROUND(100 * SUM(business_type LIKE 'Takeaway%') / COUNT(*), 1) AS pct_takeaways
FROM   v_establishments
WHERE  rating_num IS NOT NULL
  AND  postcode_area IS NOT NULL
GROUP  BY postcode_area
HAVING COUNT(*) >= 1000
ORDER  BY pct_below_3 DESC
LIMIT  20;


-- ============================================================
-- Q37 | MULTIVARIATE
-- Question: Among takeaways, how do chain and independent outlets
--           compare in each nation?
-- Concept:  CTE + window COUNT OVER + two-way GROUP BY
-- ============================================================
WITH named AS (
    SELECT nation,
           business_type,
           rating_num,
           COUNT(*) OVER (PARTITION BY name_key) AS name_count
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
)
SELECT nation,
       CASE WHEN name_count >= 50 THEN 'Chain' ELSE 'Independent' END AS ownership,
       COUNT(*)                                        AS takeaways,
       ROUND(AVG(rating_num), 2)                       AS avg_rating,
       ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)  AS pct_rated_5,
       ROUND(100 * SUM(rating_num < 3) / COUNT(*), 1)  AS pct_below_3
FROM   named
WHERE  business_type LIKE 'Takeaway%'
GROUP  BY nation, ownership
ORDER  BY nation, ownership;


-- ============================================================
-- Q38 | MULTIVARIATE
-- Question: Among businesses rated 0 or 1, which sub-score is the
--           main problem, and does that differ by sector?
-- Concept:  CTE + CASE comparing three columns + cross-tab by
--           sector
-- ============================================================
WITH failing AS (
    SELECT sector,
           CASE WHEN confidence >= hygiene AND confidence >= structural
                     THEN 'Confidence in management'
                WHEN hygiene >= structural THEN 'Hygiene'
                ELSE 'Structural' END AS main_problem
    FROM   v_establishments
    WHERE  rating_num IN (0, 1)
      AND  hygiene IS NOT NULL
)
SELECT sector,
       COUNT(*)                                                         AS rated_0_or_1,
       ROUND(100 * SUM(main_problem = 'Hygiene') / COUNT(*), 1)         AS pct_hygiene,
       ROUND(100 * SUM(main_problem = 'Structural') / COUNT(*), 1)      AS pct_structural,
       ROUND(100 * SUM(main_problem = 'Confidence in management')
             / COUNT(*), 1)                                             AS pct_confidence
FROM   failing
GROUP  BY sector
ORDER  BY rated_0_or_1 DESC;


-- ============================================================
-- Q39 | MULTIVARIATE
-- Question: Over the last 12 months, how many FHRS ratings were
--           issued each month in each nation, what share were rated
--           5, and what is the running total for the year?
-- Concept:  CTE + GROUP BY month and nation + window running SUM
--           partitioned by nation
-- ============================================================
WITH monthly AS (
    SELECT nation,
           DATE_FORMAT(rating_date, '%Y-%m')               AS rating_month,
           COUNT(*)                                        AS ratings,
           ROUND(100 * SUM(rating_num = 5) / COUNT(*), 1)  AS pct_rated_5
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
      AND  years_since_rating < 1
    GROUP  BY nation, DATE_FORMAT(rating_date, '%Y-%m')
)
SELECT nation,
       rating_month,
       ratings,
       pct_rated_5,
       SUM(ratings) OVER (PARTITION BY nation ORDER BY rating_month) AS running_total
FROM   monthly
ORDER  BY nation, rating_month;


-- ============================================================
-- Q40 | MULTIVARIATE
-- Question: In each local authority, which business type has the
--           lowest average rating (20+ rated), and how far is it
--           below the LA's overall average? Show the 25 widest
--           gaps.
-- Concept:  CTE (two steps) + window functions (ROW_NUMBER and AVG
--           OVER, both partitioned by LA)
-- ============================================================
WITH type_avgs AS (
    SELECT la_name,
           nation,
           business_type,
           COUNT(*)          AS rated,
           AVG(rating_num)   AS type_avg,
           SUM(SUM(rating_num)) OVER (PARTITION BY la_name)
             / SUM(COUNT(*)) OVER (PARTITION BY la_name)   AS la_avg
    FROM   v_establishments
    WHERE  rating_num IS NOT NULL
    GROUP  BY la_name, nation, business_type
),
ranked AS (
    SELECT t.*,
           ROW_NUMBER() OVER (PARTITION BY la_name ORDER BY type_avg) AS rn
    FROM   type_avgs t
    WHERE  rated >= 20
)
SELECT la_name,
       nation,
       business_type        AS weakest_type,
       rated,
       ROUND(type_avg, 2)   AS type_avg_rating,
       ROUND(la_avg, 2)     AS la_avg_rating,
       ROUND(la_avg - type_avg, 2) AS gap
FROM   ranked
WHERE  rn = 1
ORDER  BY gap DESC
LIMIT  25;
