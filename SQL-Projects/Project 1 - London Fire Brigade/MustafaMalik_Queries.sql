-- ============================================================
-- MustafaMalik_Queries.sql
-- SkillVersed | Data Analytics with Gen AI | SQL Phase 2, Level 2
-- Batch PGDA0626 | Social-Impact SQL Analytics Project
--
-- Dataset:  London Fire Brigade Incident and Mobilisation Records
--           (London Datastore), 1 Jan 2025 to 30 Jun 2026
-- Tables:   incidents (209,908 rows), mobilisations (312,817 rows),
--           linked on incident_number
-- Consumer: London Fire Brigade resource planning lead
-- Engine:   MySQL 8.0.46
--
-- Before running: build the clean tables with lfb_setup_load.sql
-- then lfb_setup_clean.sql. This file then runs top to bottom.
--
-- Structure: Perspective 1 to 5, easy to difficult within each.
--   P1 Q1-Q15   Where incidents happen and how concentrated they are
--   P2 Q16-Q30  When incidents happen and how demand is changing
--   P3 Q31-Q45  How fast engines respond and what delays them
--   P4 Q46-Q60  What incidents and call-outs cost
--   P5 Q61-Q75  What types of incidents occur and their impact
--
-- Views (each created once, near first use):
--   v_borough_summary        created Q12, reused Q45, Q58
--   v_station_ground_summary created Q13, reused Q42, Q60
--   v_daily_summary          created Q27, reused Q30, Q57
-- ============================================================

USE lfb_project;


-- ############################################################
-- PERSPECTIVE 1: Where incidents happen and how concentrated they are
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q1 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | EASY
-- Question: Which London boroughs appear in the incident records?
--           List each borough once, in alphabetical order.
-- Concept:  Basic SELECT - DISTINCT, ORDER BY
-- ============================================================

-- write SQL here


-- ============================================================
-- Q2 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | EASY
-- Question: What were the 10 incidents that needed the most fire
--           engines? For each, show the incident number, date of
--           call, borough, ward, property type and number of pumps
--           attending, largest first.
-- Concept:  Basic SELECT - ORDER BY, LIMIT
-- ============================================================

-- write SQL here


-- ============================================================
-- Q3 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | EASY
-- Question: Which fire incidents happened in Westminster, Camden or
--           Tower Hamlets between 1 January and 30 June 2026? Show
--           the date, ward, property type and station ground, most
--           recent first.
-- Concept:  Basic WHERE - IN, BETWEEN
-- ============================================================

-- write SQL here


-- ============================================================
-- Q4 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | EASY
-- Question: Which incidents have a postcode district recorded but no
--           full postcode? Show the incident number, borough,
--           postcode district and incident group, so we can see
--           where location precision is weakest.
-- Concept:  Basic WHERE - IS NULL / IS NOT NULL
-- ============================================================

-- write SQL here


-- ============================================================
-- Q5 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | EASY
-- Question: Which incidents that were not false alarms happened in
--           wards whose name contains "Park"? Show the ward,
--           borough, incident group and date of call.
-- Concept:  Basic WHERE - LIKE, NOT
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q6 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | MEDIUM
-- Question: For each property category, how many incidents occurred
--           and in how many different boroughs? Show only categories
--           with more than 1,000 incidents, busiest first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q7 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | MEDIUM
-- Question: Which station grounds dealt with more than 2,000
--           incidents in the period? For each, show the number of
--           incidents and the number of distinct wards covered.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q8 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | MEDIUM
-- Question: For each borough, how many incidents were fires, special
--           services and false alarms? Show all three counts side by
--           side on one row per borough.
-- Concept:  GROUP BY / conditional aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q9 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | MEDIUM
-- Question: Which boroughs received the most fire engine
--           deployments? For each borough, show the total engines
--           sent, and the average number of engines per incident,
--           counting only incidents that had at least one engine
--           mobilised.
-- Concept:  Join (INNER JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q10 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | MEDIUM
-- Question: In each borough, how many incidents have no fire engine
--           mobilisation linked to them at all, and what proportion
--           of that borough's incidents does that represent?
-- Concept:  Join (LEFT JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q11 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | DIFFICULT
-- Question: Within each borough, which are the three wards with the
--           most incidents? Rank the wards inside their own borough
--           and show only the top three per borough.
-- Concept:  Window function - ranking within a partition
-- ============================================================

-- write SQL here


-- ============================================================
-- Q12 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | DIFFICULT
-- Question: Create a reusable borough summary showing, for each
--           borough, the number of incidents, the number with a
--           recorded cost, the total notional cost and the average
--           first pump attendance time. Using it, what share of all
--           London incidents does each borough account for? Ordering
--           boroughs from busiest to quietest, what is the running
--           cumulative share, and how many boroughs together make up
--           half of all incidents?
-- Concept:  VIEW (creates borough summary) + window function (running total)
-- Creates view: v_borough_summary (reused in Q45, Q58)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q13 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | DIFFICULT
-- Question: Create a reusable station ground summary showing, for
--           each station ground, total incidents, fires, false
--           alarms, the false alarm percentage, average first pump
--           attendance time, average second pump attendance time
--           (where a second engine attended) and total notional
--           cost. Using it, which station grounds have a false alarm
--           percentage above London's overall false alarm
--           percentage, meaning all false alarms divided by all
--           incidents?
-- Concept:  VIEW (creates station ground summary) + subquery
-- Creates view: v_station_ground_summary (reused in Q42, Q60)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q14 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | DIFFICULT
-- Question: Which individual properties, identified by property
--           reference number and ignoring incidents with no
--           reference recorded, have been the site of five or more
--           incidents? For each, show the borough, property type and
--           incident count, along with the share of its borough's
--           total incidents that this one property accounts for.
-- Concept:  CTE
-- ============================================================

-- write SQL here


-- ============================================================
-- Q15 | PERSPECTIVE 1: Where incidents happen and how concentrated they are | DIFFICULT
-- Question: Which wards have an incident count more than double the
--           average ward in their own borough? Show the ward,
--           borough, ward incident count and the borough's average
--           incidents per ward, ordered by how far above average
--           each ward is.
-- Concept:  CTE
-- ============================================================

-- write SQL here


-- ############################################################
-- PERSPECTIVE 2: When incidents happen and how demand is changing
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q16 | PERSPECTIVE 2: When incidents happen and how demand is changing | EASY
-- Question: What incidents did the brigade handle on Bonfire Night,
--           5 November 2025? Show the time of call, incident group,
--           detailed incident category and borough, in the order the
--           calls came in.
-- Concept:  Basic WHERE - date filter, ORDER BY
-- ============================================================

-- write SQL here


-- ============================================================
-- Q17 | PERSPECTIVE 2: When incidents happen and how demand is changing | EASY
-- Question: Which incidents were reported on Christmas Day 2025, New
--           Year's Eve 2025 or New Year's Day 2026? Show the date,
--           time of call, incident group and borough, ordered by
--           date and time.
-- Concept:  Basic WHERE - IN
-- ============================================================

-- write SQL here


-- ============================================================
-- Q18 | PERSPECTIVE 2: When incidents happen and how demand is changing | EASY
-- Question: Which incidents during July 2025 were called in the
--           evening peak, between 17:00 and 19:59, and needed three
--           or more pumps? Show the date, time of call, incident
--           group, borough and number of pumps attending, most
--           recent first.
-- Concept:  Basic WHERE - BETWEEN, AND
-- ============================================================

-- write SQL here


-- ============================================================
-- Q19 | PERSPECTIVE 2: When incidents happen and how demand is changing | EASY
-- Question: Which false alarms at properties whose type mentions
--           "school" were called during school hours, between 09:00
--           and 15:59? Show the date, time of call, property type,
--           borough and detailed incident category, most recent
--           first.
-- Concept:  Basic WHERE - LIKE, BETWEEN
-- ============================================================

-- write SQL here


-- ============================================================
-- Q20 | PERSPECTIVE 2: When incidents happen and how demand is changing | EASY
-- Question: Which incidents in the last week of the data, 24 to 30
--           June 2026, used more than 60 pump minutes? Show the
--           date, time of call, incident group, borough, number of
--           pumps attending and pump minutes, highest pump minutes
--           first.
-- Concept:  Basic WHERE - BETWEEN, comparison
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q21 | PERSPECTIVE 2: When incidents happen and how demand is changing | MEDIUM
-- Question: How many incidents does the brigade receive in each hour
--           of the day, and what share of each hour's incidents are
--           false alarms? Show only the hours where false alarms
--           make up more than a third of incidents, busiest hour
--           first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q22 | PERSPECTIVE 2: When incidents happen and how demand is changing | MEDIUM
-- Question: How does demand vary by day of the week? For each
--           weekday, show the total incidents and the number of
--           fires, special services and false alarms, from busiest
--           day to quietest.
-- Concept:  GROUP BY / conditional aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q23 | PERSPECTIVE 2: When incidents happen and how demand is changing | MEDIUM
-- Question: Comparing January-June 2025 with January-June 2026, how
--           many incidents of each incident group occurred in each
--           period, and what is the change in number and in
--           percentage?
-- Concept:  GROUP BY / conditional aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q24 | PERSPECTIVE 2: When incidents happen and how demand is changing | MEDIUM
-- Question: Which station grounds have the highest share of their
--           incidents called in overnight, between midnight and
--           05:59? Consider only station grounds with at least 500
--           incidents, and show total incidents, overnight incidents
--           and the overnight share, highest share first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q25 | PERSPECTIVE 2: When incidents happen and how demand is changing | MEDIUM
-- Question: For each incident group, how long on average is a fire
--           engine committed to a call in each hour of the day,
--           measured from mobilisation to returning? Exclude engines
--           with no recorded return time, show the result in
--           minutes, and order by incident group and hour.
-- Concept:  Join (INNER JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q26 | PERSPECTIVE 2: When incidents happen and how demand is changing | DIFFICULT
-- Question: How did the monthly number of incidents change from one
--           month to the next across all 18 months? Show each
--           month's total, the previous month's total, and the
--           change in number and in percentage.
-- Concept:  Window function - LAG
-- ============================================================

-- write SQL here


-- ============================================================
-- Q27 | PERSPECTIVE 2: When incidents happen and how demand is changing | DIFFICULT
-- Question: Create a reusable daily summary showing, for each date,
--           the number of incidents, fires, special services and
--           false alarms, and the total notional cost. Using it,
--           which 10 periods saw the highest sustained demand based
--           on a 7-day moving average of daily incidents? Count only
--           complete 7-day windows, so start from 7 January 2025,
--           and show the end date of each window, that day's count
--           and the moving average.
-- Concept:  VIEW (creates daily summary) + window function (moving average)
-- Creates view: v_daily_summary (reused in Q30, Q57)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q28 | PERSPECTIVE 2: When incidents happen and how demand is changing | DIFFICULT
-- Question: Which hours of the day saw the biggest growth in
--           incidents between January-June 2025 and January-June
--           2026? For each hour of call, show the number of
--           incidents in both periods and the change in number and
--           percentage, then rank the hours from largest percentage
--           increase to largest decrease.
-- Concept:  CTE + window function (RANK)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q29 | PERSPECTIVE 2: When incidents happen and how demand is changing | DIFFICULT
-- Question: Which boroughs saw the biggest percentage increase in
--           incidents between January-June 2025 and January-June
--           2026? Rank all boroughs by percentage change, from
--           largest increase to largest decrease.
-- Concept:  CTE + window function (RANK)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q30 | PERSPECTIVE 2: When incidents happen and how demand is changing | DIFFICULT
-- Question: Using the daily summary, which days had more than 50%
--           more incidents than the average day in the same month of
--           the same year? For each of these surge days, show its
--           count, that month's daily average and the following
--           day's count, to see whether demand stayed high.
-- Concept:  VIEW (reuses daily summary) + window function (LEAD)
-- Uses view: v_daily_summary (created in Q27)
-- ============================================================

-- write SQL here


-- ############################################################
-- PERSPECTIVE 3: How fast engines respond and what delays them
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q31 | PERSPECTIVE 3: How fast engines respond and what delays them | EASY
-- Question: Which incidents waited more than 20 minutes for the
--           first fire engine to arrive? Show the incident number,
--           date of call, borough, station ground and first pump
--           attendance time in both seconds and minutes, slowest
--           first.
-- Concept:  Basic WHERE - comparison, calculated column
-- ============================================================

-- write SQL here


-- ============================================================
-- Q32 | PERSPECTIVE 3: How fast engines respond and what delays them | EASY
-- Question: What are the actual delay reasons recorded against fire
--           engine mobilisations? List each reason once, excluding
--           mobilisations with no delay reason recorded and those
--           marked "Not held up", in alphabetical order.
-- Concept:  Basic SELECT - DISTINCT with WHERE
-- ============================================================

-- write SQL here


-- ============================================================
-- Q33 | PERSPECTIVE 3: How fast engines respond and what delays them | EASY
-- Question: Which mobilisations were held up by any traffic-related
--           delay and still took longer than 8 minutes to arrive?
--           Show the engine, the station it was sent from, the delay
--           reason and the attendance time, slowest first.
-- Concept:  Basic WHERE - LIKE, AND
-- ============================================================

-- write SQL here


-- ============================================================
-- Q34 | PERSPECTIVE 3: How fast engines respond and what delays them | EASY
-- Question: Which incidents had the first engine arrive within the
--           6-minute target but the second engine arrive outside the
--           8-minute target? Show the incident number, borough,
--           station ground, and first and second pump attendance
--           times.
-- Concept:  Basic WHERE - AND conditions
-- ============================================================

-- write SQL here


-- ============================================================
-- Q35 | PERSPECTIVE 3: How fast engines respond and what delays them | EASY
-- Question: What were the 25 longest turnout times for engines that
--           were not at their home station when mobilised? Show the
--           engine, the station it was deployed from, its deployment
--           location and the turnout time in seconds.
-- Concept:  Basic WHERE - ORDER BY, LIMIT
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q36 | PERSPECTIVE 3: How fast engines respond and what delays them | MEDIUM
-- Question: How does the speed of the first engine vary by hour of
--           the day? For each hour of call, show the number of
--           incidents with a recorded first pump attendance time,
--           the average attendance time in seconds, and the
--           percentage arriving within 6 minutes, slowest hour
--           first.
-- Concept:  GROUP BY / conditional aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q37 | PERSPECTIVE 3: How fast engines respond and what delays them | MEDIUM
-- Question: What does each actual delay reason cost in response
--           time? For each reason, show the number of mobilisations
--           affected and the average turnout, travel and attendance
--           times, most frequent reason first.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q38 | PERSPECTIVE 3: How fast engines respond and what delays them | MEDIUM
-- Question: Which stations are slowest to get their engines moving
--           once mobilised? For each station engines are sent from,
--           show the number of mobilisations and the average turnout
--           and travel times. Show only stations with at least 1,000
--           mobilisations, slowest average turnout first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q39 | PERSPECTIVE 3: How fast engines respond and what delays them | MEDIUM
-- Question: In each borough, what share of engines counted as first
--           for performance reporting had an actual delay recorded?
--           Show the number of first engines, the number delayed and
--           the percentage delayed, highest percentage first.
-- Concept:  Join (INNER JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q40 | PERSPECTIVE 3: How fast engines respond and what delays them | MEDIUM
-- Question: Do engines respond faster when they are sent from their
--           home station rather than from elsewhere? For each
--           deployment location, show the number of mobilisations
--           and the average turnout, travel and attendance times.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q41 | PERSPECTIVE 3: How fast engines respond and what delays them | DIFFICULT
-- Question: For each actual delay reason, which three boroughs
--           record the most mobilisations held up by that reason?
--           Rank the boroughs within each delay reason and show only
--           the top three per reason.
-- Concept:  Join + window function - ranking within a partition
-- ============================================================

-- write SQL here


-- ============================================================
-- Q42 | PERSPECTIVE 3: How fast engines respond and what delays them | DIFFICULT
-- Question: Using the station ground summary, which station grounds
--           miss both the 6-minute first-engine target and the
--           8-minute second-engine target on average? Show their
--           incident counts and both average attendance times, worst
--           first-engine average first.
-- Concept:  VIEW (reuses station ground summary)
-- Uses view: v_station_ground_summary (created in Q13)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q43 | PERSPECTIVE 3: How fast engines respond and what delays them | DIFFICULT
-- Question: How has London's average first pump attendance time
--           moved month by month across all 18 months? Show each
--           month's average, the change from the previous month and
--           a 3-month moving average. Show the moving average only
--           from March 2025 onward, where three full months are
--           available.
-- Concept:  Window function - LAG and moving average
-- ============================================================

-- write SQL here


-- ============================================================
-- Q44 | PERSPECTIVE 3: How fast engines respond and what delays them | DIFFICULT
-- Question: For each fire engine, how much time typically passes
--           between returning from one call and being mobilised to
--           its next one? Show each engine's number of
--           mobilisations, its average gap in minutes and how often
--           it was sent to a new call before it had returned from
--           the previous one. Exclude mobilisations with no recorded
--           return time, and list the busiest engines first.
-- Concept:  CTE + window function - LAG within a partition
-- ============================================================

-- write SQL here


-- ============================================================
-- Q45 | PERSPECTIVE 3: How fast engines respond and what delays them | DIFFICULT
-- Question: Using the borough summary, rank boroughs from slowest to
--           fastest average first pump attendance time. For each
--           borough, show its average, whether it misses the
--           6-minute target, the average of the next borough in the
--           ranking and the gap in seconds between them, to see
--           where the biggest step-changes in performance lie.
-- Concept:  VIEW (reuses borough summary) + window function (LEAD)
-- Uses view: v_borough_summary (created in Q12)
-- ============================================================

-- write SQL here


-- ############################################################
-- PERSPECTIVE 4: What incidents and call-outs cost
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q46 | PERSPECTIVE 4: What incidents and call-outs cost | EASY
-- Question: What were the 10 most expensive incidents in the period?
--           Show the incident number, date of call, borough,
--           incident group, property type, number of pumps
--           attending, pump minutes and notional cost, most
--           expensive first.
-- Concept:  Basic SELECT - ORDER BY, LIMIT
-- ============================================================

-- write SQL here


-- ============================================================
-- Q47 | PERSPECTIVE 4: What incidents and call-outs cost | EASY
-- Question: Which false alarms had a notional cost of more than GBP
--           1,000? Show the date, borough, property type, detailed
--           incident category and cost, highest cost first.
-- Concept:  Basic WHERE - comparison
-- ============================================================

-- write SQL here


-- ============================================================
-- Q48 | PERSPECTIVE 4: What incidents and call-outs cost | EASY
-- Question: Which incidents have no notional cost recorded? Show the
--           incident number, date of call, incident group, borough
--           and pump minutes, to see where cost data is missing.
-- Concept:  Basic WHERE - IS NULL
-- ============================================================

-- write SQL here


-- ============================================================
-- Q49 | PERSPECTIVE 4: What incidents and call-outs cost | EASY
-- Question: Which special service incidents between January and June
--           2026 kept fire engines busy for between two and four
--           hours in total pump time? Show the date, special service
--           type, borough, pump minutes and notional cost, longest
--           first.
-- Concept:  Basic WHERE - BETWEEN
-- ============================================================

-- write SQL here


-- ============================================================
-- Q50 | PERSPECTIVE 4: What incidents and call-outs cost | EASY
-- Question: Which fires in properties whose type mentions "flat"
--           cost more than GBP 5,000? Show the date, borough, ward,
--           property type, number of pumps attending and notional
--           cost, highest cost first.
-- Concept:  Basic WHERE - LIKE
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q51 | PERSPECTIVE 4: What incidents and call-outs cost | MEDIUM
-- Question: How is the brigade's notional cost split across incident
--           groups? For each of fires, special services and false
--           alarms, show the number of incidents, total cost,
--           average cost per incident and total pump minutes.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q52 | PERSPECTIVE 4: What incidents and call-outs cost | MEDIUM
-- Question: Which 15 wards account for the most fire engine time?
--           For each ward, show its borough, the number of
--           incidents, total pump minutes, total notional cost and
--           average pump minutes per incident, highest total pump
--           minutes first.
-- Concept:  GROUP BY / aggregation, LIMIT
-- ============================================================

-- write SQL here


-- ============================================================
-- Q53 | PERSPECTIVE 4: What incidents and call-outs cost | MEDIUM
-- Question: How much do false alarms cost in each property category?
--           Considering only false alarms, show the number of
--           incidents, total cost and average cost per category.
--           Include only categories where false alarms cost more
--           than GBP 100,000 in total, highest first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q54 | PERSPECTIVE 4: What incidents and call-outs cost | MEDIUM
-- Question: How does cost rise as more engines attend? For each
--           number of pumps attending, show the number of incidents,
--           the average notional cost and the average pump minutes,
--           in order of pumps attending. Exclude incidents with no
--           number of pumps recorded.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q55 | PERSPECTIVE 4: What incidents and call-outs cost | MEDIUM
-- Question: For each special service type, how many fire engines
--           were sent and how long did they spend on scene on
--           average, from arriving to leaving? Show the time in
--           minutes, excluding engines with no recorded arrival or
--           leaving time, longest average first.
-- Concept:  Join (INNER JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q56 | PERSPECTIVE 4: What incidents and call-outs cost | DIFFICULT
-- Question: Within each borough, what were the five most expensive
--           incidents? Rank incidents by notional cost inside their
--           own borough and show the borough, rank, incident number,
--           date, incident group, property type and cost.
-- Concept:  Window function - ranking within a partition
-- ============================================================

-- write SQL here


-- ============================================================
-- Q57 | PERSPECTIVE 4: What incidents and call-outs cost | DIFFICULT
-- Question: Using the daily summary, how did the brigade's total
--           notional cost build up month by month across all 18
--           months? Show each month's total cost, the running
--           cumulative total, and the change from the previous month
--           in pounds and percentage.
-- Concept:  VIEW (reuses daily summary) + window function (running total, LAG)
-- Uses view: v_daily_summary (created in Q27)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q58 | PERSPECTIVE 4: What incidents and call-outs cost | DIFFICULT
-- Question: Using the borough summary, which boroughs have an
--           average cost per incident above London's overall
--           average, meaning total cost divided by the number of
--           incidents with a recorded cost? Show each borough's
--           average, London's average and the difference, highest
--           first.
-- Concept:  VIEW (reuses borough summary) + subquery
-- Uses view: v_borough_summary (created in Q12)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q59 | PERSPECTIVE 4: What incidents and call-outs cost | DIFFICULT
-- Question: Do incidents where at least one engine had an actual
--           delay cost more than incidents with no delay? Classify
--           each incident that had at least one engine mobilised as
--           delayed or not delayed, then compare the number of
--           incidents, average notional cost and average pump
--           minutes for the two groups.
-- Concept:  CTE + join
-- ============================================================

-- write SQL here


-- ============================================================
-- Q60 | PERSPECTIVE 4: What incidents and call-outs cost | DIFFICULT
-- Question: Using the station ground summary, which station grounds
--           have both a false alarm percentage above London's
--           overall false alarm percentage and a total notional cost
--           above the average station ground? Show their false alarm
--           percentage and total cost, highest cost first, as the
--           places where reducing false alarms would free the most
--           resource.
-- Concept:  VIEW (reuses station ground summary) + subquery
-- Uses view: v_station_ground_summary (created in Q13)
-- ============================================================

-- write SQL here


-- ############################################################
-- PERSPECTIVE 5: What types of incidents occur and their impact
-- ############################################################

-- ------------------------------------------------------------
-- EASY QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q61 | PERSPECTIVE 5: What types of incidents occur and their impact | EASY
-- Question: What types of special service does the brigade attend?
--           List each special service type once, excluding incidents
--           with no type recorded, in alphabetical order.
-- Concept:  Basic SELECT - DISTINCT
-- ============================================================

-- write SQL here


-- ============================================================
-- Q62 | PERSPECTIVE 5: What types of incidents occur and their impact | EASY
-- Question: Which fires prompted 10 or more calls from the public?
--           Show the date, time of call, borough, property type,
--           number of calls and number of pumps attending, most
--           calls first.
-- Concept:  Basic WHERE - comparison
-- ============================================================

-- write SQL here


-- ============================================================
-- Q63 | PERSPECTIVE 5: What types of incidents occur and their impact | EASY
-- Question: Which incidents needed engines from four or more
--           different stations? Show the incident number, date,
--           borough, incident group, property type, number of
--           stations with pumps attending and number of pumps
--           attending, largest first.
-- Concept:  Basic WHERE - comparison
-- ============================================================

-- write SQL here


-- ============================================================
-- Q64 | PERSPECTIVE 5: What types of incidents occur and their impact | EASY
-- Question: Which special service incidents had a type that mentions
--           flooding? Show the date, borough, ward, property type,
--           special service type and pump minutes, longest pump time
--           first.
-- Concept:  Basic WHERE - LIKE
-- ============================================================

-- write SQL here


-- ============================================================
-- Q65 | PERSPECTIVE 5: What types of incidents occur and their impact | EASY
-- Question: Which incidents were recorded as malicious false alarms
--           between January and June 2026? Show the date, time of
--           call, borough, ward and property type, most recent
--           first.
-- Concept:  Basic WHERE - LIKE, BETWEEN
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- MEDIUM QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q66 | PERSPECTIVE 5: What types of incidents occur and their impact | MEDIUM
-- Question: What is the typical impact of each detailed incident
--           category? For each category, show the number of
--           incidents, the average number of pumps attending, the
--           average pump minutes and the average number of calls
--           received, highest average pump minutes first.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q67 | PERSPECTIVE 5: What types of incidents occur and their impact | MEDIUM
-- Question: Which special service types most often need more than
--           one fire engine? For each type with at least 500
--           incidents, show the number of incidents and the
--           percentage where two or more pumps attended, based on
--           incidents with a recorded pump count, highest percentage
--           first.
-- Concept:  GROUP BY / aggregation with HAVING
-- ============================================================

-- write SQL here


-- ============================================================
-- Q68 | PERSPECTIVE 5: What types of incidents occur and their impact | MEDIUM
-- Question: Which 10 property types have the most fires? For each,
--           show the number of fires, the average number of pumps
--           attending and the average pump minutes per fire.
-- Concept:  GROUP BY / aggregation, LIMIT
-- ============================================================

-- write SQL here


-- ============================================================
-- Q69 | PERSPECTIVE 5: What types of incidents occur and their impact | MEDIUM
-- Question: Which types of incident most often draw fire engines
--           from outside their home station? For each incident
--           group, show the number of engines mobilised, the number
--           not at their home station when mobilised, and that
--           number as a percentage of all engines mobilised.
-- Concept:  Join (INNER JOIN) with aggregation
-- ============================================================

-- write SQL here


-- ============================================================
-- Q70 | PERSPECTIVE 5: What types of incidents occur and their impact | MEDIUM
-- Question: Where exactly do fires happen relative to the recorded
--           address? Considering only fires, show for each address
--           qualifier the number of fires, the average number of
--           pumps attending and the average pump minutes, most
--           common first.
-- Concept:  GROUP BY / aggregation
-- ============================================================

-- write SQL here


-- ------------------------------------------------------------
-- DIFFICULT QUERIES
-- ------------------------------------------------------------

-- ============================================================
-- Q71 | PERSPECTIVE 5: What types of incidents occur and their impact | DIFFICULT
-- Question: In each borough, what is the single most common type of
--           special service? Show the borough, the special service
--           type, its number of incidents and its share of that
--           borough's special service incidents. If two types tie,
--           show both.
-- Concept:  CTE + window function (RANK, keeps ties)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q72 | PERSPECTIVE 5: What types of incidents occur and their impact | DIFFICULT
-- Question: How often do incidents in each property category
--           escalate beyond the initial attendance? Classify each
--           incident that had at least one engine mobilised by
--           whether any engine was sent as additional resources. For
--           each property category, show the number of incidents,
--           the number that escalated and the escalation percentage,
--           and rank the categories from most to least likely to
--           escalate.
-- Concept:  CTE + join
-- ============================================================

-- write SQL here


-- ============================================================
-- Q73 | PERSPECTIVE 5: What types of incidents occur and their impact | DIFFICULT
-- Question: For incidents where at least three engines arrived, how
--           long after the first engine did the third one arrive?
--           Number the engines within each incident by their
--           recorded arrival time (not the recorded pump order),
--           excluding engines with no arrival time. Then, for each
--           incident group, show the number of such incidents and
--           the average gap in minutes between the first and third
--           arrivals.
-- Concept:  CTE + window function (ROW_NUMBER)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q74 | PERSPECTIVE 5: What types of incidents occur and their impact | DIFFICULT
-- Question: Which properties suffer repeated false alarms in quick
--           succession? For each property (by property reference
--           number, ignoring incidents with no reference), find the
--           gap in days between consecutive false alarms. List the
--           properties with at least three false alarms that
--           followed the previous one within 30 days, with their
--           borough, property type and number of quick repeats, most
--           repeats first.
-- Concept:  CTE + window function (LAG within a partition)
-- ============================================================

-- write SQL here


-- ============================================================
-- Q75 | PERSPECTIVE 5: What types of incidents occur and their impact | DIFFICULT
-- Question: Which special service types take up a bigger share of
--           the brigade's special service engine time than their
--           share of special service incidents? For each type, show
--           its share of special service incidents, its share of
--           special service pump minutes and the ratio between the
--           two, highest ratio first.
-- Concept:  CTE
-- ============================================================

-- write SQL here


-- ============================================================
-- END OF FILE
-- ============================================================
