# 💊 Project 5: NHS Prescribing Cost and Value (NHSBSA)

**Business question:** Where does the NHS primary care prescribing budget go, and where are the best opportunities to get better value?

## 📦 Dataset
**NHSBSA English Prescribing Dataset (EPD), August 2026**: every item prescribed in primary care in England that month.

| Measure | Value |
|---|---|
| Prescription lines | **17,754,211** (a 6.9 GB file) |
| Items | **102.05 million** |
| Actual cost | **£904.5m** |
| Practices | 9,254 |
| ICBs | 37 |
| Presentations | 21,240 |

The file is loaded in three passes into a star-style schema:
- a `prescriptions` fact table
- `practices` and `presentations` dimension tables, built from the same file using `IGNORE` with a primary key

**End consumer:** ICB medicines optimisation pharmacist

## 🔍 Key Findings
- **A few products drive most of the spending:** 43 of 1,628 chemicals (2.6%) make up half of the budget, and 179 make up 80%.
- **Tirzepatide alone cost £79.8m** at £233 per item, and it is the top-cost product in every region.
- **Endocrine is now the most expensive BNF chapter**, at 22.0% of cost. Cardiovascular has the most items but only 12.1% of cost.
- **Generics are 86.3% of items but only 53.2% of cost**, at £4.89 per item against £27.09 for branded products.
- **Appliance, stoma and continence services** fill the top of every cost-per-item ranking at £52–93 per item, so they must be benchmarked separately from GP practices.
- **Cost per item varies** from £8.00 (North East and Yorkshire) to £10.05 (South East) by region.

## 🛠️ What I Built
**15 questions, each built around a different SQL function family:**

| Q | Function family | Q | Function family |
|---|---|---|---|
| 1 | Aggregates | 9 | Ranking (ROW_NUMBER, RANK) |
| 2 | ROLLUP + GROUPING() | 10 | Distribution (NTILE, PERCENT_RANK) |
| 3 | String extraction | 11 | Running totals (Pareto analysis) |
| 4 | String formatting | 12 | Navigation (LAG, FIRST_VALUE) |
| 5 | REGEXP on BNF code structure | 13 | Correlated subqueries + EXISTS |
| 6 | Numeric | 14 | UNION ALL |
| 7 | Conditional | 15 | Statistical (STDDEV_POP, VAR_POP) |
| 8 | Date functions | | |

## 📁 Files
| File | Description |
|---|---|
| `epd_setup.sql` | Creates the database and loads the 17.75m-row file in three passes |
| `Prescribing_Queries.sql` | All 15 queries |
| `Report.pdf` | Full report: every result, interpretation and summary |

**Tools:** MySQL 8, MySQL Workbench, PowerShell
