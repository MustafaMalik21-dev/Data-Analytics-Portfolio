# 🗄️ SQL Projects

Six end-to-end SQL analyses of large UK public datasets, built in **MySQL 8**. Each project goes from raw download to a loaded, cleaned database, then answers a structured set of business questions for a named end consumer, with every result interpreted in a written report.

| # | Project | Dataset | Scale | Questions | Headline finding |
|---|---|---|---|---|---|
| 1 | [London Fire Brigade](Project%201%20-%20London%20Fire%20Brigade) | LFB incident and mobilisation records, Jan 2025 – Jun 2026 | 522k rows, 2 tables | 75 | False alarms are the most common and most costly call-out: 93,736 in 18 months, costing £46.2m |
| 2 | [Housing Affordability](Project%202%20-%20Housing%20Affordability) | HM Land Registry Price Paid Data, Jan 2025 – Sep 2026 | 1.45m sales | 45 | Starter homes range from £96,000 (County Durham) to £387,750 (Greater London) |
| 3 | [School Performance](Project%203%20-%20School%20Performance) | DfE KS4 performance tables 2024/25 + GIAS | 3 joined sources | 40 | Disadvantaged pupils average 34.9 in Attainment 8 against 50.4 for others |
| 4 | [Food Hygiene](Project%204%20-%20Food%20Hygiene) | FSA Food Hygiene Rating Scheme, all UK authorities | 600k+ businesses | 40 | 97.0% broadly compliant, but independent takeaways have only 52–59% rated 5 |
| 5 | [Prescribing Data](Project%205%20-%20Prescribing%20Data) | NHSBSA English Prescribing Dataset, Aug 2026 | 17.75m rows | 15 | 43 of 1,628 chemicals make up half of the £904.5m monthly spend |
| 6 | [Air Quality](Project%206%20-%20Air%20Quality) | Defra AURN hourly monitoring, 2025 | 4.52m readings, 201 sites | 15 | No site breaches the UK NO2 limit, but 81% exceed the WHO guideline |

## Project types
- **Structured by difficulty** (Projects 1–2): questions grouped by perspective or end consumer, from easy to difficult.
- **Analysis types** (Projects 3–4): 10 KPI, 10 univariate, 10 bivariate and 10 multivariate questions.
- **SQL function families** (Projects 5–6): 15 questions, each built around a different family: aggregates, ROLLUP/GROUPING, string, REGEXP, numeric, conditional, date, ranking, distribution, window aggregates, LAG/LEAD, correlated subqueries, set operations and statistics.

## What every project includes
- A **setup script** that creates the database and loads the raw files with `LOAD DATA LOCAL INFILE`, cleaning and typing on the way in
- A **query file** where each question has its business question and SQL concept in a comment header
- A **report** with every result table, an interpretation of each result, and a summary of findings for the end consumer

**Tools:** MySQL 8, MySQL Workbench, PowerShell (data preparation)
