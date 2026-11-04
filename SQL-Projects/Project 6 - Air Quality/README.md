# 🌫️ Project 6: UK Air Quality (Defra AURN)

**Business question:** Where and when is air pollution highest in the UK, and how far is each area from UK objectives and WHO health guidelines?

## 📦 Dataset
**Defra UK-AIR, Automatic Urban and Rural Network (AURN)**: hourly measurements for **2025** from **201 monitoring sites**, giving **4,516,584 readings** of NO2, ozone, PM10 and PM2.5.

Defra's own download tool caps output at 502 columns, so I scripted the data collection in PowerShell (`prepare_data.ps1`). The script:
1. Reads all 215 AURN site codes from Defra's network page.
2. Downloads each site's pre-formatted 2025 file.
3. Reshapes the wide per-site files (up to ~50 pollutant columns each) into one long table.
4. Reads each site's page for its environment type, region and coordinates.

**End consumer:** Local authority air quality / public health officer

## 🔍 Key Findings
- **NO2 is a roadside problem:**
  - No site exceeded the UK annual objective of 40 µg/m³, but **81% of sites, and 58 of 60 roadside sites, exceeded the WHO guideline of 10**.
  - The highest sites are Glasgow Kerbside (34.8) and Belfast Stockman's Lane (33.5).
- **Traffic drives the pattern:** roadside NO2 on weekday mornings is more than **twice the overnight level**, and Sunday is **31% lower** than Wednesday.
- **PM2.5 is regional:**
  - Every region averages below England's 2040 target of 10, with Greater London highest at 9.16.
  - Only Highland reaches the WHO guideline of 5.
  - Only 4 sites are in the top 20 for both NO2 and PM2.5.
- **Ozone fails the UK objective at background sites:** the worst sites had 27–36 high days against an allowance of 10.
- **NO2 and ozone are negatively correlated** at every site type (r = −0.40 to −0.60).
- **The worst PM2.5 episode** ran from 8 to 10 March, when the network average reached 40.4 µg/m³. Bonfire Night also shows up clearly.

## 🛠️ What I Built
**15 questions, each built around a different SQL function family:**

| Q | Function family | Q | Function family |
|---|---|---|---|
| 1 | Aggregates | 9 | Ranking (ROW_NUMBER, RANK) |
| 2 | ROLLUP + GROUPING() | 10 | Distribution (NTILE, PERCENT_RANK, CUME_DIST) |
| 3 | String extraction | 11 | Window aggregates: 8-hour running mean (RANGE INTERVAL) |
| 4 | String formatting | 12 | Navigation (LAG, LEAD) |
| 5 | REGEXP with word boundaries | 13 | Correlated subqueries + EXISTS |
| 6 | Numeric | 14 | UNION ALL |
| 7 | Conditional (Daily Air Quality Index bands) | 15 | Statistical (STDDEV_POP, VAR_POP, Pearson correlation) |
| 8 | Date functions (DAYOFWEEK, HOUR) | | |

## 📁 Files
| File | Description |
|---|---|
| `prepare_data.ps1` | Downloads and reshapes the Defra data (PowerShell) |
| `air_setup.sql` | Creates the database and loads the prepared files |
| `AirQuality_Queries.sql` | Helper view plus all 15 queries |
| `Report.pdf` | Full report: every result, interpretation and summary |

**Tools:** MySQL 8, MySQL Workbench, PowerShell
