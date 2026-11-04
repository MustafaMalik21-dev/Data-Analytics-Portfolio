-- ============================================================
-- PRESCRIBING DATA PROJECT: ANALYSIS QUERIES
-- Project type: Type 3 (15 questions, each built around a
--               different family of SQL functions)
-- Perspective:  Prescribing cost and value
-- End consumer: ICB medicines optimisation pharmacist
-- Data:         NHSBSA English Prescribing Dataset, August 2026
--               (17.75 million rows)
-- ============================================================
--   Q1   Aggregate functions        SUM, COUNT, AVG, MIN, MAX
--   Q2   Grouping functions         WITH ROLLUP, GROUPING()
--   Q3   String: extraction         LEFT, SUBSTRING_INDEX
--   Q4   String: formatting         CONCAT, UPPER, LOWER, LOCATE
--   Q5   Pattern matching           REGEXP, LIKE
--   Q6   Numeric functions          ROUND, ABS, CEIL, FLOOR
--   Q7   Conditional functions      CASE, IF, NULLIF, COALESCE
--   Q8   Date functions             STR_TO_DATE, LAST_DAY, DAY,
--                                   DATE_FORMAT
--   Q9   Ranking window functions   ROW_NUMBER, RANK
--   Q10  Distribution window        NTILE, PERCENT_RANK
--   Q11  Window aggregates          SUM() OVER (running total)
--   Q12  Navigation window          LAG, FIRST_VALUE
--   Q13  Subqueries                 correlated subquery, EXISTS
--   Q14  Set operations             UNION ALL
--   Q15  Statistical aggregates     STDDEV_POP, VAR_POP
-- ============================================================
-- Conventions
--   * Cost = ACTUAL_COST (what the NHS paid, after the national
--     discount deduction). NIC = net ingredient cost (list price).
--   * Items = number of prescription items dispensed.
--   * BNF presentation codes for medicines (chapters 01-15) are
--     15 characters: chapter (2), section (2), paragraph (2),
--     sub-paragraph (1), chemical (2), product (2), strength and
--     formulation (2), generic equivalent (2). Product code "AA"
--     at characters 10-11 means a generic product.
--   * Practice-level questions use practices with 1,000+ items
--     in the month, so very small or non-GP prescribing settings
--     do not distort averages.
--   * The data covers one month, so every figure is for August
--     2026.
-- Each query scans the full 17.75 million rows, so allow up to a
-- minute or two per query. Run the file from the command line
-- (as for the earlier projects) or raise the Workbench timeout.
-- Run epd_setup.sql first.
-- ============================================================

USE prescribing;


-- ============================================================
-- Q1 | AGGREGATE FUNCTIONS
-- Question: What are the headline totals for August 2026: rows,
--           practices, items, cost and NIC, and the average,
--           lowest and highest cost per prescription line?
-- Concept:  SUM, COUNT, COUNT(DISTINCT), AVG, MIN, MAX
-- ============================================================
SELECT COUNT(*)                                 AS prescription_lines,
       COUNT(DISTINCT practice_code)            AS practices,
       COUNT(DISTINCT presentation_code)        AS presentations,
       SUM(items)                               AS items,
       ROUND(SUM(actual_cost), 0)               AS actual_cost_gbp,
       ROUND(SUM(nic), 0)                       AS nic_gbp,
       ROUND(SUM(actual_cost) / SUM(items), 2)  AS cost_per_item_gbp,
       ROUND(AVG(actual_cost), 2)               AS avg_cost_per_line_gbp,
       MIN(actual_cost)                         AS min_line_cost_gbp,
       MAX(actual_cost)                         AS max_line_cost_gbp
FROM   prescriptions;


-- ============================================================
-- Q2 | GROUPING FUNCTIONS
-- Question: How are items and cost split across NHS England
--           regions and their ICBs, with a subtotal for each
--           region and a grand total?
-- Concept:  GROUP BY ... WITH ROLLUP + GROUPING() to label the
--           subtotal and total rows
-- ============================================================
SELECT IF(GROUPING(p.region_name) = 1, 'ALL REGIONS', p.region_name) AS region,
       IF(GROUPING(p.icb_name) = 1,
          IF(GROUPING(p.region_name) = 1, '(grand total)', '(region total)'),
          p.icb_name)                                                AS icb,
       SUM(rx.items)                                                 AS items,
       ROUND(SUM(rx.actual_cost) / 1000000, 2)                       AS cost_gbp_m,
       ROUND(SUM(rx.actual_cost) / SUM(rx.items), 2)                 AS cost_per_item_gbp
FROM   prescriptions rx
JOIN   practices p ON p.practice_code = rx.practice_code
WHERE  p.region_name <> 'UNIDENTIFIED'
GROUP  BY p.region_name, p.icb_name WITH ROLLUP;


-- ============================================================
-- Q3 | STRING FUNCTIONS: EXTRACTION
-- Question: Which BNF chapters account for the most spending?
--           Split the chapter field ("20: Dressings") into its
--           number and name.
-- Concept:  CTE + LEFT, SUBSTRING_INDEX, TRIM + share of total
-- ============================================================
WITH chapters AS (
    SELECT pr.bnf_chapter,
           SUM(rx.items)       AS items,
           SUM(rx.actual_cost) AS cost
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.bnf_chapter
)
SELECT LEFT(bnf_chapter, 2)                               AS chapter_no,
       TRIM(SUBSTRING_INDEX(bnf_chapter, ':', -1))        AS chapter_name,
       items,
       ROUND(cost / 1000000, 2)                           AS cost_gbp_m,
       ROUND(100 * cost / SUM(cost) OVER (), 1)           AS pct_of_cost
FROM   chapters
ORDER  BY cost DESC;


-- ============================================================
-- Q4 | STRING FUNCTIONS: FORMATTING
-- Question: Which 15 practices had the highest prescribing cost?
--           Show each name in sentence case with its postcode
--           district and a single readable label.
-- Concept:  CONCAT, UPPER, LOWER, LEFT, SUBSTRING, LOCATE
-- ============================================================
WITH practice_cost AS (
    SELECT practice_code,
           SUM(items)       AS items,
           SUM(actual_cost) AS cost
    FROM   prescriptions
    GROUP  BY practice_code
)
SELECT CONCAT(UPPER(LEFT(p.practice_name, 1)),
              LOWER(SUBSTRING(p.practice_name, 2)))               AS practice,
       LEFT(p.postcode, LOCATE(' ', p.postcode) - 1)              AS postcode_district,
       CONCAT(p.practice_code, ' | ', p.icb_code, ' | ',
              LOWER(p.region_name))                               AS label,
       pc.items,
       ROUND(pc.cost, 0)                                          AS cost_gbp
FROM   practice_cost pc
JOIN   practices p ON p.practice_code = pc.practice_code
WHERE  p.postcode LIKE '% %'
ORDER  BY pc.cost DESC
LIMIT  15;


-- ============================================================
-- Q5 | PATTERN MATCHING
-- Question: For medicines (BNF chapters 01-15), what share of
--           items and cost is generic rather than branded, and how
--           many modified-release products are prescribed?
-- Concept:  REGEXP on the BNF code structure + LIKE on the
--           presentation name
-- ============================================================
SELECT CASE WHEN pr.presentation_code REGEXP '^.{9}AA' THEN 'Generic'
            ELSE 'Branded' END                                      AS product_type,
       SUM(rx.items)                                                AS items,
       ROUND(100 * SUM(rx.items) / SUM(SUM(rx.items)) OVER (), 1)   AS pct_of_items,
       ROUND(SUM(rx.actual_cost) / 1000000, 2)                      AS cost_gbp_m,
       ROUND(100 * SUM(rx.actual_cost)
             / SUM(SUM(rx.actual_cost)) OVER (), 1)                 AS pct_of_cost,
       ROUND(SUM(rx.actual_cost) / SUM(rx.items), 2)                AS cost_per_item_gbp,
       SUM(CASE WHEN pr.presentation_name LIKE '%modified%release%'
                  OR pr.presentation_name LIKE '% m/r %'
                THEN rx.items END)                                  AS modified_release_items
FROM   prescriptions rx
JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
WHERE  pr.presentation_code REGEXP '^(0[1-9]|1[0-5])'
GROUP  BY product_type
ORDER  BY product_type DESC;


-- ============================================================
-- Q6 | NUMERIC FUNCTIONS
-- Question: For each BNF chapter, how far is the actual cost below
--           the list price (NIC), and what is the cost per item
--           rounded up and down to the nearest pound?
-- Concept:  ROUND, ABS, CEIL, FLOOR
-- ============================================================
WITH chapter_totals AS (
    SELECT pr.bnf_chapter,
           SUM(rx.nic)         AS nic,
           SUM(rx.actual_cost) AS cost,
           SUM(rx.items)       AS items
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.bnf_chapter
)
SELECT LEFT(bnf_chapter, 2)                        AS chapter_no,
       TRIM(SUBSTRING_INDEX(bnf_chapter, ':', -1)) AS chapter_name,
       ROUND(nic, 0)                              AS nic_gbp,
       ROUND(cost, 0)                             AS actual_cost_gbp,
       ROUND(ABS(cost - nic), 0)                  AS difference_gbp,
       ROUND(100 * (nic - cost) / nic, 2)         AS pct_below_nic,
       ROUND(cost / items, 2)                     AS cost_per_item_gbp,
       FLOOR(cost / items)                        AS cost_per_item_floor,
       CEIL(cost / items)                         AS cost_per_item_ceil
FROM   chapter_totals
ORDER  BY nic_gbp DESC;


-- ============================================================
-- Q7 | CONDITIONAL FUNCTIONS
-- Question: Group practices by the number of items they dispensed
--           in the month. How do cost per item and the share of
--           unidentified prescribing differ by practice size?
-- Concept:  CASE, IF, NULLIF (safe division), COALESCE
-- ============================================================
WITH practice_totals AS (
    SELECT rx.practice_code,
           SUM(rx.items)                               AS items,
           SUM(rx.actual_cost)                         AS cost,
           SUM(IF(rx.unidentified = 'Y', rx.items, 0)) AS unidentified_items
    FROM   prescriptions rx
    GROUP  BY rx.practice_code
)
SELECT CASE WHEN items <  1000  THEN '1. Under 1,000'
            WHEN items <  5000  THEN '2. 1,000-4,999'
            WHEN items < 10000  THEN '3. 5,000-9,999'
            WHEN items < 20000  THEN '4. 10,000-19,999'
            ELSE '5. 20,000+' END                                       AS size_band,
       COUNT(*)                                                         AS practices,
       SUM(items)                                                       AS items,
       ROUND(SUM(cost) / NULLIF(SUM(items), 0), 2)                      AS cost_per_item_gbp,
       ROUND(100 * COALESCE(SUM(unidentified_items), 0)
             / NULLIF(SUM(items), 0), 2)                                AS pct_unidentified
FROM   practice_totals
GROUP  BY size_band
ORDER  BY size_band;


-- ============================================================
-- Q8 | DATE FUNCTIONS
-- Question: Turn the month field into a real date. Using the
--           number of days in the month, how many patients could
--           the 15 most-used medicines treat each day, based on
--           average daily quantities (ADQ)?
-- Concept:  STR_TO_DATE, LAST_DAY, DAY, DATE_FORMAT
-- ============================================================
WITH by_chemical AS (
    SELECT pr.chemical_name,
           MIN(STR_TO_DATE(CONCAT(rx.rx_month, '-01'), '%Y-%m-%d')) AS month_start,
           SUM(rx.adq_usage)                                       AS adq,
           SUM(rx.items)                                           AS items
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    WHERE  rx.adq_usage > 0
    GROUP  BY pr.chemical_name
)
SELECT chemical_name,
       DATE_FORMAT(month_start, '%M %Y')               AS month,
       DAY(LAST_DAY(month_start))                      AS days_in_month,
       items,
       ROUND(adq, 0)                                   AS total_adq,
       ROUND(adq / DAY(LAST_DAY(month_start)), 0)      AS patients_treated_per_day
FROM   by_chemical
ORDER  BY adq DESC
LIMIT  15;


-- ============================================================
-- Q9 | RANKING WINDOW FUNCTIONS
-- Question: What are the three most expensive chemical substances
--           in each NHS England region?
-- Concept:  ROW_NUMBER and RANK partitioned by region
-- ============================================================
WITH region_chem AS (
    SELECT p.region_name,
           pr.chemical_name,
           SUM(rx.actual_cost) AS cost,
           SUM(rx.items)       AS items
    FROM   prescriptions rx
    JOIN   practices     p  ON p.practice_code      = rx.practice_code
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    WHERE  p.region_name <> 'UNIDENTIFIED'
    GROUP  BY p.region_name, pr.chemical_name
),
ranked AS (
    SELECT rc.*,
           ROW_NUMBER() OVER (PARTITION BY region_name ORDER BY cost DESC) AS rn,
           RANK()       OVER (PARTITION BY region_name ORDER BY items DESC) AS items_rank
    FROM   region_chem rc
)
SELECT region_name,
       rn                           AS cost_rank,
       chemical_name,
       ROUND(cost / 1000000, 2)     AS cost_gbp_m,
       items,
       items_rank
FROM   ranked
WHERE  rn <= 3
ORDER  BY region_name, rn;


-- ============================================================
-- Q10 | DISTRIBUTION WINDOW FUNCTIONS
-- Question: Split practices (1,000+ items) into ten equal groups
--           by cost per item. What range does each decile cover,
--           and how many practices are in the most expensive 5%?
-- Concept:  NTILE and PERCENT_RANK
-- ============================================================
WITH practice_totals AS (
    SELECT practice_code,
           SUM(actual_cost) / SUM(items) AS cost_per_item
    FROM   prescriptions
    GROUP  BY practice_code
    HAVING SUM(items) >= 1000
),
dist AS (
    SELECT cost_per_item,
           NTILE(10)      OVER (ORDER BY cost_per_item) AS decile,
           PERCENT_RANK() OVER (ORDER BY cost_per_item) AS pr
    FROM   practice_totals
)
SELECT decile,
       COUNT(*)                        AS practices,
       ROUND(MIN(cost_per_item), 2)    AS min_cost_per_item,
       ROUND(MAX(cost_per_item), 2)    AS max_cost_per_item,
       ROUND(AVG(cost_per_item), 2)    AS avg_cost_per_item,
       SUM(pr >= 0.95)                 AS in_top_5_pct
FROM   dist
GROUP  BY decile
ORDER  BY decile;


-- ============================================================
-- Q11 | WINDOW AGGREGATE FUNCTIONS
-- Question: How concentrated is spending? Rank chemical substances
--           by cost and use a running total to find how many
--           account for 50%, 80%, 90% and 99% of all spending.
-- Concept:  SUM() OVER (ORDER BY ...) running total + share of
--           total
-- ============================================================
WITH chem_cost AS (
    SELECT pr.chemical_name,
           SUM(rx.actual_cost) AS cost
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.chemical_name
),
running AS (
    SELECT chemical_name,
           cost,
           ROW_NUMBER() OVER (ORDER BY cost DESC)                   AS cost_rank,
           100 * SUM(cost) OVER (ORDER BY cost DESC
                                 ROWS BETWEEN UNBOUNDED PRECEDING
                                          AND CURRENT ROW)
               / SUM(cost) OVER ()                                  AS cumulative_pct,
           COUNT(*) OVER ()                                         AS total_chemicals
    FROM   chem_cost
)
SELECT t.threshold_pct,
       MIN(r.cost_rank)                                         AS chemicals_needed,
       MAX(r.total_chemicals)                                   AS total_chemicals,
       ROUND(100 * MIN(r.cost_rank) / MAX(r.total_chemicals), 1) AS pct_of_chemicals
FROM   running r
JOIN  (SELECT 50 AS threshold_pct UNION ALL SELECT 80
       UNION ALL SELECT 90 UNION ALL SELECT 99) t
  ON   r.cumulative_pct >= t.threshold_pct
GROUP  BY t.threshold_pct
ORDER  BY t.threshold_pct;


-- ============================================================
-- Q12 | NAVIGATION WINDOW FUNCTIONS
-- Question: In each of the four most expensive BNF chapters, what
--           are the top five chemicals by cost, how far is each
--           behind the one above it, and what share of the
--           chapter leader's cost does it reach?
-- Concept:  LAG and FIRST_VALUE partitioned by chapter
-- ============================================================
WITH chap_chem AS (
    SELECT pr.bnf_chapter,
           pr.chemical_name,
           SUM(rx.actual_cost) AS cost
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.bnf_chapter, pr.chemical_name
),
top_chapters AS (
    SELECT bnf_chapter
    FROM   chap_chem
    GROUP  BY bnf_chapter
    ORDER  BY SUM(cost) DESC
    LIMIT  4
),
nav AS (
    SELECT c.bnf_chapter,
           c.chemical_name,
           c.cost,
           ROW_NUMBER() OVER (PARTITION BY c.bnf_chapter ORDER BY c.cost DESC) AS rn,
           LAG(c.cost)  OVER (PARTITION BY c.bnf_chapter ORDER BY c.cost DESC) AS cost_above,
           FIRST_VALUE(c.cost)
                        OVER (PARTITION BY c.bnf_chapter ORDER BY c.cost DESC) AS leader_cost
    FROM   chap_chem c
    JOIN   top_chapters t ON t.bnf_chapter = c.bnf_chapter
)
SELECT bnf_chapter,
       rn                                        AS chapter_rank,
       chemical_name,
       ROUND(cost / 1000000, 2)                  AS cost_gbp_m,
       ROUND((cost_above - cost) / 1000000, 2)   AS gap_to_above_gbp_m,
       ROUND(100 * cost / leader_cost, 1)        AS pct_of_leader
FROM   nav
WHERE  rn <= 5
ORDER  BY bnf_chapter, rn;


-- ============================================================
-- Q13 | SUBQUERIES
-- Question: Which practices (2,000+ items) have a cost per item
--           more than 50% above the average for their own ICB, and
--           do they prescribe any of the ten most expensive
--           chemicals nationally? Show the 20 furthest above.
-- Concept:  Correlated subquery (ICB average per row) + EXISTS
--           against a subquery of top chemicals
-- ============================================================
WITH practice_totals AS (
    SELECT rx.practice_code,
           p.practice_name,
           p.icb_name,
           SUM(rx.items)                        AS items,
           SUM(rx.actual_cost) / SUM(rx.items)  AS cost_per_item
    FROM   prescriptions rx
    JOIN   practices p ON p.practice_code = rx.practice_code
    GROUP  BY rx.practice_code, p.practice_name, p.icb_name
    HAVING SUM(rx.items) >= 2000
),
top_chems AS (
    SELECT pr.chemical_code
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.chemical_code
    ORDER  BY SUM(rx.actual_cost) DESC
    LIMIT  10
)
SELECT pt.practice_name,
       pt.icb_name,
       pt.items,
       ROUND(pt.cost_per_item, 2)                                   AS cost_per_item_gbp,
       ROUND((SELECT AVG(i.cost_per_item)
              FROM   practice_totals i
              WHERE  i.icb_name = pt.icb_name), 2)                  AS icb_avg_cost_per_item,
       IF(EXISTS (SELECT 1
                  FROM   prescriptions rx
                  JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
                  JOIN   top_chems tc     ON tc.chemical_code     = pr.chemical_code
                  WHERE  rx.practice_code = pt.practice_code),
          'Yes', 'No')                                              AS prescribes_top10_chemical
FROM   practice_totals pt
WHERE  pt.cost_per_item > 1.5 * (SELECT AVG(i.cost_per_item)
                                 FROM   practice_totals i
                                 WHERE  i.icb_name = pt.icb_name)
ORDER  BY pt.cost_per_item / (SELECT AVG(i.cost_per_item)
                              FROM   practice_totals i
                              WHERE  i.icb_name = pt.icb_name) DESC
LIMIT  20;


-- ============================================================
-- Q14 | SET OPERATIONS
-- Question: Compare the 20 most-prescribed chemicals by items with
--           the 20 most expensive by cost. Which appear in both
--           lists, and which in only one?
-- Concept:  UNION ALL of two ranked lists + GROUP BY to classify
-- ============================================================
WITH chem AS (
    SELECT pr.chemical_name,
           SUM(rx.items)       AS items,
           SUM(rx.actual_cost) AS cost
    FROM   prescriptions rx
    JOIN   presentations pr ON pr.presentation_code = rx.presentation_code
    GROUP  BY pr.chemical_name
),
lists AS (
    (SELECT chemical_name, 'items' AS list FROM chem ORDER BY items DESC LIMIT 20)
    UNION ALL
    (SELECT chemical_name, 'cost'  AS list FROM chem ORDER BY cost  DESC LIMIT 20)
)
SELECT l.chemical_name,
       CASE WHEN COUNT(*) = 2        THEN 'Both lists'
            WHEN MAX(l.list) = 'items' THEN 'High volume only'
            ELSE 'High cost only' END             AS appears_in,
       MAX(c.items)                               AS items,
       ROUND(MAX(c.cost) / 1000000, 2)            AS cost_gbp_m,
       ROUND(MAX(c.cost) / MAX(c.items), 2)       AS cost_per_item_gbp
FROM   lists l
JOIN   chem  c ON c.chemical_name = l.chemical_name
GROUP  BY l.chemical_name
ORDER  BY appears_in, cost_gbp_m DESC;


-- ============================================================
-- Q15 | STATISTICAL AGGREGATE FUNCTIONS
-- Question: How much do practices within each ICB vary in cost per
--           item? Calculate the mean, standard deviation, variance
--           and coefficient of variation for practices with 1,000+
--           items.
-- Concept:  AVG, STDDEV_POP, VAR_POP + coefficient of variation
-- ============================================================
WITH practice_totals AS (
    SELECT rx.practice_code,
           p.icb_name,
           SUM(rx.actual_cost) / SUM(rx.items) AS cost_per_item
    FROM   prescriptions rx
    JOIN   practices p ON p.practice_code = rx.practice_code
    GROUP  BY rx.practice_code, p.icb_name
    HAVING SUM(rx.items) >= 1000
)
SELECT icb_name,
       COUNT(*)                                            AS practices,
       ROUND(AVG(cost_per_item), 2)                        AS mean_cost_per_item,
       ROUND(STDDEV_POP(cost_per_item), 2)                 AS sd,
       ROUND(VAR_POP(cost_per_item), 2)                    AS variance,
       ROUND(100 * STDDEV_POP(cost_per_item) / AVG(cost_per_item), 1) AS cv_pct
FROM   practice_totals
GROUP  BY icb_name
ORDER  BY cv_pct DESC;
