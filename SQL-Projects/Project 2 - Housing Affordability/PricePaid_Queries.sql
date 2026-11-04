-- ============================================================
-- PricePaid_Queries.sql
-- Housing Affordability SQL Project (Type 2: one perspective,
-- three end consumers, 15 questions each = 45 queries)
--
-- Dataset:  HM Land Registry Price Paid Data, England and Wales
--           1 Jan 2025 to 30 Sep 2026 (1,450,241 sales)
-- Tables:   sales (one row per sale), property_types, tenures
-- Engine:   MySQL 8
--
-- Perspective: Housing affordability - what homes cost, where,
--              and how prices are changing.
--
-- End consumers:
--   C1 Q1-Q15   First-time buyer adviser at a housing charity
--   C2 Q16-Q30  Local authority housing planner
--   C3 Q31-Q45  Property market journalist
--
-- Conventions used throughout:
--   * "Homes" = standard market sales (ppd_category = 'A'),
--     excluding property type 'O' (Other), unless stated.
--   * 2026 data ends on 30 Sep, so year-on-year comparisons are
--     like-for-like: Jan-Sep 2025 vs Jan-Sep 2026.
--
-- Views (each created once, near first use):
--   v_homes           created Q11, reused Q12-Q15, Q26-Q28, Q43, Q45
--   v_district_year   created Q26, reused Q30, Q44
--   v_monthly_market  created Q41, reused Q42
--
-- Run pricepaid_setup.sql first. This file then runs top to bottom.
-- ============================================================

USE price_paid;


-- ############################################################
-- END CONSUMER 1: First-time buyer adviser
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q1 | CONSUMER 1: First-time buyer adviser | EASY
-- Question: What were the 20 cheapest flats sold at market value
--           in Greater London in 2026?
-- Concept:  Basic SELECT - WHERE, ORDER BY, LIMIT
-- ============================================================
SELECT date_of_transfer,
       price,
       saon,
       paon,
       street,
       postcode,
       district
FROM   sales
WHERE  county = 'GREATER LONDON'
  AND  property_type = 'F'
  AND  ppd_category = 'A'
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price ASC
LIMIT  20;


-- ============================================================
-- Q2 | CONSUMER 1: First-time buyer adviser | EASY
-- Question: Which terraced houses sold at market value for under
--           GBP 150,000 in September 2026? Show the most recent 25.
-- Concept:  Basic WHERE - comparison, BETWEEN
-- ============================================================
SELECT date_of_transfer,
       price,
       street,
       town_city,
       district,
       county
FROM   sales
WHERE  property_type = 'T'
  AND  ppd_category = 'A'
  AND  price < 150000
  AND  date_of_transfer BETWEEN '2026-09-01' AND '2026-09-30'
ORDER  BY date_of_transfer DESC, price ASC
LIMIT  25;


-- ============================================================
-- Q3 | CONSUMER 1: First-time buyer adviser | EASY
-- Question: Which houses (not flats) were sold as leasehold in
--           2026 for under GBP 250,000? Show the 25 cheapest.
-- Concept:  Basic WHERE - IN, AND
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       street,
       town_city,
       district
FROM   sales
WHERE  property_type IN ('D', 'S', 'T')
  AND  duration = 'L'
  AND  ppd_category = 'A'
  AND  price < 250000
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price ASC
LIMIT  25;


-- ============================================================
-- Q4 | CONSUMER 1: First-time buyer adviser | EASY
-- Question: Which new-build flats in Manchester sold at market
--           value for between GBP 150,000 and GBP 250,000 across
--           2025-2026? Show the 25 most recent.
-- Concept:  Basic WHERE - BETWEEN, AND
-- ============================================================
SELECT date_of_transfer,
       price,
       saon,
       paon,
       street,
       postcode
FROM   sales
WHERE  district = 'MANCHESTER'
  AND  property_type = 'F'
  AND  old_new = 'Y'
  AND  ppd_category = 'A'
  AND  price BETWEEN 150000 AND 250000
ORDER  BY date_of_transfer DESC
LIMIT  25;


-- ============================================================
-- Q5 | CONSUMER 1: First-time buyer adviser | EASY
-- Question: Which homes in Slough-area postcodes (starting "SL")
--           sold at market value for under GBP 300,000 in 2026?
--           Show the 25 cheapest.
-- Concept:  Basic WHERE - LIKE, NOT
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       postcode,
       street,
       town_city
FROM   sales
WHERE  postcode LIKE 'SL%'
  AND  property_type <> 'O'
  AND  NOT ppd_category = 'B'
  AND  price < 300000
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price ASC
LIMIT  25;


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q6 | CONSUMER 1: First-time buyer adviser | MEDIUM
-- Question: In 2026, how many homes of each property type sold at
--           market value, and what was the average and lowest price?
-- Concept:  Join (lookup table) with GROUP BY
-- ============================================================
SELECT pt.type_name,
       COUNT(*)            AS sales,
       ROUND(AVG(s.price)) AS avg_price,
       MIN(s.price)        AS min_price
FROM   sales AS s
JOIN   property_types AS pt
       ON pt.property_type = s.property_type
WHERE  s.ppd_category = 'A'
  AND  s.property_type <> 'O'
  AND  s.date_of_transfer >= '2026-01-01'
GROUP  BY pt.type_name
ORDER  BY avg_price ASC;


-- ============================================================
-- Q7 | CONSUMER 1: First-time buyer adviser | MEDIUM
-- Question: For flats sold at market value in 2026, how do the
--           number of sales and average price compare between
--           leasehold and freehold?
-- Concept:  Join (lookup table) with GROUP BY
-- ============================================================
SELECT t.tenure_name,
       COUNT(*)            AS sales,
       ROUND(AVG(s.price)) AS avg_price
FROM   sales AS s
JOIN   tenures AS t
       ON t.duration = s.duration
WHERE  s.property_type = 'F'
  AND  s.ppd_category = 'A'
  AND  s.date_of_transfer >= '2026-01-01'
GROUP  BY t.tenure_name
ORDER  BY sales DESC;


-- ============================================================
-- Q8 | CONSUMER 1: First-time buyer adviser | MEDIUM
-- Question: Which 20 districts had the lowest average price for
--           entry-level homes (flats and terraced houses) in 2026,
--           counting only districts with at least 200 such sales?
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================
SELECT district,
       county,
       COUNT(*)            AS entry_level_sales,
       ROUND(AVG(price))   AS avg_price
FROM   sales
WHERE  property_type IN ('F', 'T')
  AND  ppd_category = 'A'
  AND  date_of_transfer >= '2026-01-01'
GROUP  BY district, county
HAVING COUNT(*) >= 200
ORDER  BY avg_price ASC
LIMIT  20;


-- ============================================================
-- Q9 | CONSUMER 1: First-time buyer adviser | MEDIUM
-- Question: In which 15 counties is it hardest to find a home for
--           under GBP 250,000, measured by the share of 2026 market
--           sales below that price (counties with 1,000+ sales)?
-- Concept:  GROUP BY / conditional aggregation with HAVING
-- ============================================================
SELECT county,
       COUNT(*)                                          AS sales,
       SUM(price < 250000)                               AS sales_under_250k,
       ROUND(100 * SUM(price < 250000) / COUNT(*), 1)    AS pct_under_250k
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer >= '2026-01-01'
GROUP  BY county
HAVING COUNT(*) >= 1000
ORDER  BY pct_under_250k ASC
LIMIT  15;


-- ============================================================
-- Q10 | CONSUMER 1: First-time buyer adviser | MEDIUM
-- Question: For each property type, how much more does a new-build
--           cost on average than an existing home (2025-2026 market sales)?
-- Concept:  Join + conditional aggregation
-- ============================================================
SELECT pt.type_name,
       ROUND(AVG(CASE WHEN s.old_new = 'Y' THEN s.price END)) AS avg_new_build,
       ROUND(AVG(CASE WHEN s.old_new = 'N' THEN s.price END)) AS avg_existing,
       ROUND(100 * (AVG(CASE WHEN s.old_new = 'Y' THEN s.price END)
                  / AVG(CASE WHEN s.old_new = 'N' THEN s.price END) - 1), 1)
                                                               AS new_build_premium_pct
FROM   sales AS s
JOIN   property_types AS pt
       ON pt.property_type = s.property_type
WHERE  s.ppd_category = 'A'
  AND  s.property_type <> 'O'
GROUP  BY pt.type_name
ORDER  BY new_build_premium_pct DESC;


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q11 | CONSUMER 1: First-time buyer adviser | DIFFICULT
-- Question: Create a reusable view of market-value home sales with
--           readable labels. Using it, what is the median 2026 price
--           of each property type, compared with the average?
-- Concept:  VIEW (creates v_homes) + CTE + window function
--           (ROW_NUMBER / COUNT OVER for the median)
-- Creates view: v_homes (reused in Q12-Q15, Q26-Q28, Q43, Q45)
-- ============================================================
CREATE OR REPLACE VIEW v_homes AS
SELECT s.transaction_id,
       s.price,
       s.date_of_transfer,
       YEAR(s.date_of_transfer)  AS sale_year,
       MONTH(s.date_of_transfer) AS sale_month,
       s.postcode,
       s.property_type,
       pt.type_name,
       s.old_new,
       s.duration,
       t.tenure_name,
       s.street,
       s.town_city,
       s.district,
       s.county
FROM   sales AS s
JOIN   property_types AS pt ON pt.property_type = s.property_type
JOIN   tenures        AS t  ON t.duration       = s.duration
WHERE  s.ppd_category = 'A'
  AND  s.property_type <> 'O';

WITH ranked AS (
    SELECT type_name,
           price,
           ROW_NUMBER() OVER (PARTITION BY type_name ORDER BY price) AS rn,
           COUNT(*)     OVER (PARTITION BY type_name)                AS n
    FROM   v_homes
    WHERE  sale_year = 2026
)
SELECT type_name,
       MAX(n)                 AS sales,
       ROUND(AVG(price))      AS median_price
FROM   ranked
WHERE  rn IN (FLOOR((n + 1) / 2), CEIL((n + 1) / 2))
GROUP  BY type_name
ORDER  BY median_price;


-- ============================================================
-- Q12 | CONSUMER 1: First-time buyer adviser | DIFFICULT
-- Question: In each county, which district has the lowest average
--           price for flats and terraced houses in 2026 (districts
--           with at least 100 such sales)?
-- Concept:  CTE + window function - RANK within a partition
-- ============================================================
WITH district_prices AS (
    SELECT county,
           district,
           COUNT(*)          AS sales,
           ROUND(AVG(price)) AS avg_price
    FROM   v_homes
    WHERE  property_type IN ('F', 'T')
      AND  sale_year = 2026
    GROUP  BY county, district
    HAVING COUNT(*) >= 100
),
ranked AS (
    SELECT county,
           district,
           sales,
           avg_price,
           RANK() OVER (PARTITION BY county ORDER BY avg_price) AS price_rank
    FROM   district_prices
)
SELECT county,
       district AS cheapest_district,
       sales,
       avg_price
FROM   ranked
WHERE  price_rank = 1
ORDER  BY avg_price;


-- ============================================================
-- Q13 | CONSUMER 1: First-time buyer adviser | DIFFICULT
-- Question: Which districts have an average entry-level price (flats
--           and terraced) below the national entry-level average in
--           2026, while still having a large market (500+ sales)?
-- Concept:  Uses v_homes + subquery against a national benchmark
-- ============================================================
SELECT district,
       county,
       COUNT(*)          AS entry_level_sales,
       ROUND(AVG(price)) AS avg_price,
       (SELECT ROUND(AVG(price))
        FROM   v_homes
        WHERE  property_type IN ('F', 'T')
          AND  sale_year = 2026)         AS national_avg
FROM   v_homes
WHERE  property_type IN ('F', 'T')
  AND  sale_year = 2026
GROUP  BY district, county
HAVING COUNT(*) >= 500
   AND AVG(price) < (SELECT AVG(price)
                     FROM   v_homes
                     WHERE  property_type IN ('F', 'T')
                       AND  sale_year = 2026)
ORDER  BY entry_level_sales DESC
LIMIT  20;


-- ============================================================
-- Q14 | CONSUMER 1: First-time buyer adviser | DIFFICULT
-- Question: Where are entry-level prices rising fastest? Compare the
--           average flat and terraced price in Jan-Sep 2025 with
--           Jan-Sep 2026 by district (100+ sales in each period).
-- Concept:  CTE + conditional aggregation + window function (RANK)
-- ============================================================
WITH by_period AS (
    SELECT district,
           county,
           SUM(sale_year = 2025)                                AS sales_2025,
           SUM(sale_year = 2026)                                AS sales_2026,
           AVG(CASE WHEN sale_year = 2025 THEN price END)       AS avg_2025,
           AVG(CASE WHEN sale_year = 2026 THEN price END)       AS avg_2026
    FROM   v_homes
    WHERE  property_type IN ('F', 'T')
      AND  sale_month <= 9
    GROUP  BY district, county
)
SELECT RANK() OVER (ORDER BY avg_2026 / avg_2025 DESC)  AS growth_rank,
       district,
       county,
       ROUND(avg_2025)                                  AS avg_2025,
       ROUND(avg_2026)                                  AS avg_2026,
       ROUND(100 * (avg_2026 / avg_2025 - 1), 1)        AS change_pct
FROM   by_period
WHERE  sales_2025 >= 100
  AND  sales_2026 >= 100
ORDER  BY growth_rank
LIMIT  15;


-- ============================================================
-- Q15 | CONSUMER 1: First-time buyer adviser | DIFFICULT
-- Question: What is the lower-quartile price (the typical
--           "starter home" price) in each county in 2026, and how
--           does it compare with the county median?
-- Concept:  CTE + window function (PERCENT_RANK)
-- ============================================================
WITH ranked AS (
    SELECT county,
           price,
           PERCENT_RANK() OVER (PARTITION BY county ORDER BY price) AS pr,
           COUNT(*)       OVER (PARTITION BY county)                AS n
    FROM   v_homes
    WHERE  sale_year = 2026
)
SELECT county,
       MAX(n)                                    AS sales,
       MIN(CASE WHEN pr >= 0.25 THEN price END)  AS lower_quartile_price,
       MIN(CASE WHEN pr >= 0.50 THEN price END)  AS median_price
FROM   ranked
GROUP  BY county
HAVING MAX(n) >= 1000
ORDER  BY lower_quartile_price DESC;


-- ############################################################
-- END CONSUMER 2: Local authority housing planner
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q16 | CONSUMER 2: Local authority housing planner | EASY
-- Question: What were the 20 most expensive new-build homes sold in
--           Birmingham across 2025-2026?
-- Concept:  Basic SELECT - WHERE, ORDER BY, LIMIT
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       street,
       postcode
FROM   sales
WHERE  district = 'BIRMINGHAM'
  AND  old_new = 'Y'
  AND  ppd_category = 'A'
ORDER  BY price DESC
LIMIT  20;


-- ============================================================
-- Q17 | CONSUMER 2: Local authority housing planner | EASY
-- Question: Which local authority districts in Kent recorded sales?
--           List each once, alphabetically.
-- Concept:  Basic SELECT - DISTINCT, ORDER BY
-- ============================================================
SELECT DISTINCT district
FROM   sales
WHERE  county = 'KENT'
ORDER  BY district;


-- ============================================================
-- Q18 | CONSUMER 2: Local authority housing planner | EASY
-- Question: Which additional-price-paid (category B) sales, such as
--           company or buy-to-let purchases, exceeded GBP 1 million in
--           2026? Show the 25 largest.
-- Concept:  Basic WHERE - comparison, AND
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       street,
       town_city,
       district
FROM   sales
WHERE  ppd_category = 'B'
  AND  price > 1000000
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price DESC
LIMIT  25;


-- ============================================================
-- Q19 | CONSUMER 2: Local authority housing planner | EASY
-- Question: Which 2026 market sales have no postcode recorded, which
--           weakens location-based planning? Show the first 25.
-- Concept:  Basic WHERE - IS NULL
-- ============================================================
SELECT transaction_id,
       date_of_transfer,
       price,
       street,
       town_city,
       district
FROM   sales
WHERE  postcode IS NULL
  AND  ppd_category = 'A'
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY date_of_transfer
LIMIT  25;


-- ============================================================
-- Q20 | CONSUMER 2: Local authority housing planner | EASY
-- Question: Which semi-detached houses sold at market value in Leeds,
--           Bradford or Sheffield between January and March 2026?
--           Show the first 30, grouped by district.
-- Concept:  Basic WHERE - IN, BETWEEN
-- ============================================================
SELECT date_of_transfer,
       price,
       district,
       street,
       postcode
FROM   sales
WHERE  district IN ('LEEDS', 'BRADFORD', 'SHEFFIELD')
  AND  property_type = 'S'
  AND  ppd_category = 'A'
  AND  date_of_transfer BETWEEN '2026-01-01' AND '2026-03-31'
ORDER  BY district, date_of_transfer
LIMIT  30;


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q21 | CONSUMER 2: Local authority housing planner | MEDIUM
-- Question: Which 20 districts had the highest share of new-build
--           homes among their 2025-2026 market sales (1,000+ sales)?
-- Concept:  GROUP BY / conditional aggregation with HAVING
-- ============================================================
SELECT district,
       county,
       COUNT(*)                                        AS sales,
       SUM(old_new = 'Y')                              AS new_build_sales,
       ROUND(100 * SUM(old_new = 'Y') / COUNT(*), 1)   AS new_build_pct
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
GROUP  BY district, county
HAVING COUNT(*) >= 1000
ORDER  BY new_build_pct DESC
LIMIT  20;


-- ============================================================
-- Q22 | CONSUMER 2: Local authority housing planner | MEDIUM
-- Question: In which 15 counties do additional-price-paid sales
--           (category B, e.g. company and buy-to-let purchases) make
--           up the largest share of all sales, 2025-2026?
-- Concept:  GROUP BY / conditional aggregation with HAVING
-- ============================================================
SELECT county,
       COUNT(*)                                           AS all_sales,
       SUM(ppd_category = 'B')                            AS category_b_sales,
       ROUND(100 * SUM(ppd_category = 'B') / COUNT(*), 1) AS category_b_pct
FROM   sales
GROUP  BY county
HAVING COUNT(*) >= 2000
ORDER  BY category_b_pct DESC
LIMIT  15;


-- ============================================================
-- Q23 | CONSUMER 2: Local authority housing planner | MEDIUM
-- Question: For each property type and tenure, how many homes sold at
--           market value in 2026, and at what average price?
-- Concept:  Join (two lookup tables) with GROUP BY
-- ============================================================
SELECT pt.type_name,
       t.tenure_name,
       COUNT(*)            AS sales,
       ROUND(AVG(s.price)) AS avg_price
FROM   sales AS s
JOIN   property_types AS pt ON pt.property_type = s.property_type
JOIN   tenures        AS t  ON t.duration       = s.duration
WHERE  s.ppd_category = 'A'
  AND  s.property_type <> 'O'
  AND  s.date_of_transfer >= '2026-01-01'
GROUP  BY pt.type_name, t.tenure_name
ORDER  BY pt.type_name, sales DESC;


-- ============================================================
-- Q24 | CONSUMER 2: Local authority housing planner | MEDIUM
-- Question: In which districts did detached houses average more than
--           GBP 1 million across 2025-2026 (50+ detached sales)?
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================
SELECT district,
       county,
       COUNT(*)          AS detached_sales,
       ROUND(AVG(price)) AS avg_detached_price
FROM   sales
WHERE  property_type = 'D'
  AND  ppd_category = 'A'
GROUP  BY district, county
HAVING COUNT(*) >= 50
   AND AVG(price) > 1000000
ORDER  BY avg_detached_price DESC;


-- ============================================================
-- Q25 | CONSUMER 2: Local authority housing planner | MEDIUM
-- Question: For each county, how many districts are there, how many
--           homes sold at market value in 2026, and what were the
--           lowest, highest and average prices?
-- Concept:  GROUP BY / aggregation (COUNT DISTINCT, MIN, MAX, AVG)
-- ============================================================
SELECT county,
       COUNT(DISTINCT district) AS districts,
       COUNT(*)                 AS sales,
       MIN(price)               AS min_price,
       MAX(price)               AS max_price,
       ROUND(AVG(price))        AS avg_price
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer >= '2026-01-01'
GROUP  BY county
ORDER  BY sales DESC;


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q26 | CONSUMER 2: Local authority housing planner | DIFFICULT
-- Question: Create a reusable like-for-like (Jan-Sep) summary of each
--           district by year. Using it, which 15 districts saw the
--           largest rise in average price from 2025 to 2026, and which
--           15 the largest fall (300+ sales in each year)?
-- Concept:  VIEW (creates v_district_year) + CTE + window functions
--           (RANK both ways)
-- Creates view: v_district_year (reused in Q30, Q44)
-- ============================================================
CREATE OR REPLACE VIEW v_district_year AS
SELECT district,
       county,
       sale_year,
       COUNT(*)                   AS sales,
       AVG(price)                 AS avg_price,
       SUM(old_new = 'Y')         AS new_build_sales
FROM   v_homes
WHERE  sale_month <= 9
GROUP  BY district, county, sale_year;

WITH change_by_district AS (
    SELECT y25.district,
           y25.county,
           ROUND(y25.avg_price)                            AS avg_2025,
           ROUND(y26.avg_price)                            AS avg_2026,
           ROUND(100 * (y26.avg_price / y25.avg_price - 1), 1) AS change_pct
    FROM   v_district_year AS y25
    JOIN   v_district_year AS y26
           ON  y26.district = y25.district
           AND y26.sale_year = 2026
    WHERE  y25.sale_year = 2025
      AND  y25.sales >= 300
      AND  y26.sales >= 300
),
ranked AS (
    SELECT change_by_district.*,
           RANK() OVER (ORDER BY change_pct DESC) AS rise_rank,
           RANK() OVER (ORDER BY change_pct ASC)  AS fall_rank
    FROM   change_by_district
)
SELECT CASE WHEN rise_rank <= 15 THEN 'Largest rise' ELSE 'Largest fall' END AS grp,
       district,
       county,
       avg_2025,
       avg_2026,
       change_pct
FROM   ranked
WHERE  rise_rank <= 15 OR fall_rank <= 15
ORDER  BY change_pct DESC;


-- ============================================================
-- Q27 | CONSUMER 2: Local authority housing planner | DIFFICULT
-- Question: Within each county, how wide is the gap between its most
--           and least expensive district in 2026 (districts with 200+
--           sales)? Show the 15 counties with the widest gaps.
-- Concept:  CTE (two steps) + aggregation over district averages
-- ============================================================
WITH district_avg AS (
    SELECT county,
           district,
           AVG(price) AS avg_price
    FROM   v_homes
    WHERE  sale_year = 2026
    GROUP  BY county, district
    HAVING COUNT(*) >= 200
),
county_spread AS (
    SELECT county,
           COUNT(*)              AS districts,
           ROUND(MIN(avg_price)) AS cheapest_district_avg,
           ROUND(MAX(avg_price)) AS dearest_district_avg
    FROM   district_avg
    GROUP  BY county
    HAVING COUNT(*) >= 2
)
SELECT county,
       districts,
       cheapest_district_avg,
       dearest_district_avg,
       dearest_district_avg - cheapest_district_avg                      AS gap,
       ROUND(dearest_district_avg / cheapest_district_avg, 2)            AS ratio
FROM   county_spread
ORDER  BY ratio DESC
LIMIT  15;


-- ============================================================
-- Q28 | CONSUMER 2: Local authority housing planner | DIFFICULT
-- Question: Which 15 districts charge the largest new-build premium
--           over existing homes of the same type across 2025-2026, so the
--           premium is not distorted by property mix (districts with
--           100+ new-build sales)?
-- Concept:  CTE + join + window function (RANK)
-- ============================================================
WITH type_prices AS (
    SELECT district,
           county,
           property_type,
           SUM(old_new = 'Y')                              AS new_sales,
           AVG(CASE WHEN old_new = 'Y' THEN price END)     AS avg_new,
           AVG(CASE WHEN old_new = 'N' THEN price END)     AS avg_existing
    FROM   v_homes
    GROUP  BY district, county, property_type
),
district_premium AS (
    SELECT district,
           county,
           SUM(new_sales)                                             AS new_build_sales,
           SUM(new_sales * (avg_new / avg_existing - 1)) / SUM(new_sales) AS premium
    FROM   type_prices
    WHERE  avg_new IS NOT NULL
      AND  avg_existing IS NOT NULL
    GROUP  BY district, county
    HAVING SUM(new_sales) >= 100
)
SELECT RANK() OVER (ORDER BY premium DESC) AS premium_rank,
       district,
       county,
       new_build_sales,
       ROUND(100 * premium, 1)              AS new_build_premium_pct
FROM   district_premium
ORDER  BY premium_rank
LIMIT  15;


-- ============================================================
-- Q29 | CONSUMER 2: Local authority housing planner | DIFFICULT
-- Question: How has the monthly number of new-build sales moved
--           across all 21 months, and what is its 3-month moving
--           average (shown from the third month onward)?
-- Concept:  CTE + window function (moving average with ROWS frame)
-- ============================================================
WITH monthly AS (
    SELECT DATE_FORMAT(date_of_transfer, '%Y-%m') AS sale_month,
           COUNT(*)                               AS new_build_sales
    FROM   sales
    WHERE  old_new = 'Y'
      AND  ppd_category = 'A'
      AND  property_type <> 'O'
    GROUP  BY DATE_FORMAT(date_of_transfer, '%Y-%m')
)
SELECT sale_month,
       new_build_sales,
       CASE WHEN ROW_NUMBER() OVER (ORDER BY sale_month) >= 3
            THEN ROUND(AVG(new_build_sales) OVER (
                       ORDER BY sale_month
                       ROWS BETWEEN 2 PRECEDING AND CURRENT ROW))
       END AS moving_avg_3m
FROM   monthly
ORDER  BY sale_month;


-- ============================================================
-- Q30 | CONSUMER 2: Local authority housing planner | DIFFICULT
-- Question: Using the district summary, which districts saw sales
--           volumes fall while prices still rose (Jan-Sep 2025 vs
--           Jan-Sep 2026), a sign of supply pressure?
-- Concept:  Uses v_district_year (self-join) + filtering on changes
-- ============================================================
SELECT y25.district,
       y25.county,
       y25.sales                                            AS sales_2025,
       y26.sales                                            AS sales_2026,
       ROUND(100 * (y26.sales / y25.sales - 1), 1)          AS volume_change_pct,
       ROUND(100 * (y26.avg_price / y25.avg_price - 1), 1)  AS price_change_pct
FROM   v_district_year AS y25
JOIN   v_district_year AS y26
       ON  y26.district  = y25.district
       AND y26.sale_year = 2026
WHERE  y25.sale_year = 2025
  AND  y25.sales >= 300
  AND  y26.sales <  y25.sales
  AND  y26.avg_price > y25.avg_price
ORDER  BY price_change_pct DESC
LIMIT  20;


-- ############################################################
-- END CONSUMER 3: Property market journalist
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q31 | CONSUMER 3: Property market journalist | EASY
-- Question: What were the 10 most expensive property sales of any
--           kind recorded in 2026?
-- Concept:  Basic SELECT - ORDER BY, LIMIT
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       ppd_category,
       paon,
       street,
       town_city,
       district
FROM   sales
WHERE  date_of_transfer >= '2026-01-01'
ORDER  BY price DESC
LIMIT  10;


-- ============================================================
-- Q32 | CONSUMER 3: Property market journalist | EASY
-- Question: Which homes sold at market value for GBP 5 million or
--           more in 2025?
-- Concept:  Basic WHERE - comparison, BETWEEN
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       street,
       district,
       county
FROM   sales
WHERE  price >= 5000000
  AND  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer BETWEEN '2025-01-01' AND '2025-12-31'
ORDER  BY price DESC;


-- ============================================================
-- Q33 | CONSUMER 3: Property market journalist | EASY
-- Question: Which were the 20 most expensive market sales that
--           completed on Christmas Eve or New Year's Eve 2025?
-- Concept:  Basic WHERE - IN, ORDER BY, LIMIT
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       town_city,
       district
FROM   sales
WHERE  date_of_transfer IN ('2025-12-24', '2025-12-31')
  AND  ppd_category = 'A'
ORDER  BY price DESC
LIMIT  20;


-- ============================================================
-- Q34 | CONSUMER 3: Property market journalist | EASY
-- Question: Which homes on a "High Street" sold at market value for
--           over GBP 1 million in 2026? Show the 25 most expensive.
-- Concept:  Basic WHERE - LIKE
-- ============================================================
SELECT date_of_transfer,
       price,
       property_type,
       paon,
       street,
       town_city
FROM   sales
WHERE  street LIKE '%HIGH STREET%'
  AND  price > 1000000
  AND  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price DESC
LIMIT  25;


-- ============================================================
-- Q35 | CONSUMER 3: Property market journalist | EASY
-- Question: Which new-build flats in London (town "LONDON") sold at
--           market value for under GBP 400,000 in 2026?
-- Concept:  Basic WHERE - AND conditions
-- ============================================================
SELECT date_of_transfer,
       price,
       saon,
       street,
       postcode,
       district
FROM   sales
WHERE  town_city = 'LONDON'
  AND  property_type = 'F'
  AND  old_new = 'Y'
  AND  ppd_category = 'A'
  AND  price < 400000
  AND  date_of_transfer >= '2026-01-01'
ORDER  BY price ASC
LIMIT  25;


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q36 | CONSUMER 3: Property market journalist | MEDIUM
-- Question: How many homes sold at market value each month, and at
--           what average price, from January 2025 to September 2026?
-- Concept:  GROUP BY / aggregation on date parts
-- ============================================================
SELECT YEAR(date_of_transfer)  AS sale_year,
       MONTH(date_of_transfer) AS sale_month,
       COUNT(*)                AS sales,
       ROUND(AVG(price))       AS avg_price
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
GROUP  BY YEAR(date_of_transfer), MONTH(date_of_transfer)
ORDER  BY sale_year, sale_month;


-- ============================================================
-- Q37 | CONSUMER 3: Property market journalist | MEDIUM
-- Question: Which 10 counties had the highest average market price in
--           2026 (counties with at least 2,000 sales)?
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================
SELECT county,
       COUNT(*)          AS sales,
       ROUND(AVG(price)) AS avg_price
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer >= '2026-01-01'
GROUP  BY county
HAVING COUNT(*) >= 2000
ORDER  BY avg_price DESC
LIMIT  10;


-- ============================================================
-- Q38 | CONSUMER 3: Property market journalist | MEDIUM
-- Question: How are 2026 market sales spread across price bands, and
--           what share of the market does each band hold?
-- Concept:  GROUP BY on a CASE expression + share of total
-- ============================================================
SELECT CASE
           WHEN price <  125000  THEN '1. Under 125k'
           WHEN price <  250000  THEN '2. 125k-250k'
           WHEN price <  500000  THEN '3. 250k-500k'
           WHEN price <  1000000 THEN '4. 500k-1m'
           ELSE                       '5. 1m and over'
       END                                                  AS price_band,
       COUNT(*)                                             AS sales,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)     AS share_pct
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
  AND  date_of_transfer >= '2026-01-01'
GROUP  BY price_band
ORDER  BY price_band;


-- ============================================================
-- Q39 | CONSUMER 3: Property market journalist | MEDIUM
-- Question: On which days of the week do house sales complete, and is
--           Friday really the busiest completion day (2025-2026)?
-- Concept:  GROUP BY on a date function (DAYNAME / DAYOFWEEK)
-- ============================================================
SELECT DAYNAME(date_of_transfer)                           AS weekday,
       COUNT(*)                                            AS sales,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS share_pct
FROM   sales
WHERE  ppd_category = 'A'
GROUP  BY DAYNAME(date_of_transfer), DAYOFWEEK(date_of_transfer)
ORDER  BY DAYOFWEEK(date_of_transfer);


-- ============================================================
-- Q40 | CONSUMER 3: Property market journalist | MEDIUM
-- Question: For each property type, how many GBP 1 million-plus market
--           sales were there in 2025-2026, and what share of all
--           million-pound sales does each type make up?
-- Concept:  Join (lookup table) + GROUP BY + share of total
-- ============================================================
SELECT pt.type_name,
       COUNT(*)                                            AS million_plus_sales,
       ROUND(AVG(s.price))                                 AS avg_price,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)    AS share_pct
FROM   sales AS s
JOIN   property_types AS pt
       ON pt.property_type = s.property_type
WHERE  s.price >= 1000000
  AND  s.ppd_category = 'A'
  AND  s.property_type <> 'O'
GROUP  BY pt.type_name
ORDER  BY million_plus_sales DESC;


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q41 | CONSUMER 3: Property market journalist | DIFFICULT
-- Question: Create a reusable monthly market summary. Using it, how
--           did the average price change from one month to the next,
--           in pounds and in percent?
-- Concept:  VIEW (creates v_monthly_market) + window function (LAG)
-- Creates view: v_monthly_market (reused in Q42)
-- ============================================================
CREATE OR REPLACE VIEW v_monthly_market AS
SELECT DATE_FORMAT(date_of_transfer, '%Y-%m') AS sale_month,
       COUNT(*)                               AS sales,
       AVG(price)                             AS avg_price,
       SUM(price)                             AS total_value
FROM   sales
WHERE  ppd_category = 'A'
  AND  property_type <> 'O'
GROUP  BY DATE_FORMAT(date_of_transfer, '%Y-%m');

SELECT sale_month,
       sales,
       ROUND(avg_price)                                         AS avg_price,
       ROUND(avg_price - LAG(avg_price) OVER (ORDER BY sale_month)) AS change_gbp,
       ROUND(100 * (avg_price / LAG(avg_price) OVER (ORDER BY sale_month) - 1), 2)
                                                                AS change_pct
FROM   v_monthly_market
ORDER  BY sale_month;


-- ============================================================
-- Q42 | CONSUMER 3: Property market journalist | DIFFICULT
-- Question: Using the monthly summary, how did the total value of
--           homes sold build up through each year, as a running total
--           that restarts each January?
-- Concept:  Uses v_monthly_market + window function (running SUM
--           partitioned by year)
-- ============================================================
SELECT sale_month,
       sales,
       ROUND(total_value / 1000000, 1)                         AS value_gbp_m,
       ROUND(SUM(total_value) OVER (
                 PARTITION BY LEFT(sale_month, 4)
                 ORDER BY sale_month) / 1000000000, 2)          AS year_to_date_gbp_bn
FROM   v_monthly_market
ORDER  BY sale_month;


-- ============================================================
-- Q43 | CONSUMER 3: Property market journalist | DIFFICULT
-- Question: What were the three most expensive home sales in each
--           county in 2026?
-- Concept:  CTE + window function (ROW_NUMBER within a partition)
-- ============================================================
WITH ranked AS (
    SELECT county,
           district,
           date_of_transfer,
           price,
           type_name,
           street,
           ROW_NUMBER() OVER (PARTITION BY county ORDER BY price DESC) AS price_rank
    FROM   v_homes
    WHERE  sale_year = 2026
)
SELECT county,
       price_rank,
       price,
       type_name,
       street,
       district,
       date_of_transfer
FROM   ranked
WHERE  price_rank <= 3
ORDER  BY county, price_rank;


-- ============================================================
-- Q44 | CONSUMER 3: Property market journalist | DIFFICULT
-- Question: Using the district summary, where is market activity
--           heating up? Rank districts by the like-for-like rise in
--           sales volume from Jan-Sep 2025 to Jan-Sep 2026 (300+
--           sales in 2025), alongside their price change.
-- Concept:  Uses v_district_year + window function (DENSE_RANK)
-- ============================================================
SELECT DENSE_RANK() OVER (ORDER BY y26.sales / y25.sales DESC) AS activity_rank,
       y25.district,
       y25.county,
       y25.sales                                              AS sales_2025,
       y26.sales                                              AS sales_2026,
       ROUND(100 * (y26.sales / y25.sales - 1), 1)            AS volume_change_pct,
       ROUND(100 * (y26.avg_price / y25.avg_price - 1), 1)    AS price_change_pct
FROM   v_district_year AS y25
JOIN   v_district_year AS y26
       ON  y26.district  = y25.district
       AND y26.sale_year = 2026
WHERE  y25.sale_year = 2025
  AND  y25.sales >= 300
ORDER  BY activity_rank
LIMIT  20;


-- ============================================================
-- Q45 | CONSUMER 3: Property market journalist | DIFFICULT
-- Question: Which 2026 sales were extreme outliers, at more than ten
--           times the average price for the same property type in the
--           same district?
-- Concept:  CTE + window function (AVG OVER a partition)
-- ============================================================
WITH with_benchmark AS (
    SELECT date_of_transfer,
           price,
           type_name,
           street,
           district,
           county,
           AVG(price) OVER (PARTITION BY district, property_type) AS local_type_avg,
           COUNT(*)   OVER (PARTITION BY district, property_type) AS local_type_sales
    FROM   v_homes
    WHERE  sale_year = 2026
)
SELECT date_of_transfer,
       price,
       type_name,
       street,
       district,
       county,
       ROUND(local_type_avg)                AS local_type_avg,
       ROUND(price / local_type_avg, 1)     AS times_local_avg
FROM   with_benchmark
WHERE  local_type_sales >= 30
  AND  price > 10 * local_type_avg
ORDER  BY times_local_avg DESC
LIMIT  25;


-- ============================================================
-- END OF FILE
-- ============================================================
