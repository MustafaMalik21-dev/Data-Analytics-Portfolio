# 🍽️ Project 4: Food Hygiene Ratings (Food Standards Agency)

**Business question:** How compliant are UK food businesses with hygiene law, which types of business and areas are weakest, and where are inspections falling behind?

## 📦 Dataset
**FSA Food Hygiene Rating Scheme open data** for all UK local authorities: over **600,000 food businesses**, with their rating, inspection date, business type and inspection sub-scores (hygiene, structural and confidence in management).
- England, Wales and Northern Ireland use the 0–5 FHRS scheme.
- Scotland uses the Pass / Improvement Required FHIS scheme, analysed separately.

**End consumer:** Local authority environmental health manager

## 🔍 Key Findings
- **Compliance is high overall:**
  - **97.0%** of rated businesses are broadly compliant, and **78.5%** are rated 5.
  - That still leaves **14,876 below 3**.
- **Inspections are falling behind:** **42,301 businesses are awaiting a first inspection**, and a quarter of ratings are over two years old.
- **Independent takeaways are the clearest problem group**, with only **52–59% rated 5**. Takeaways (5.7% below 3) and other retailers (5.2%) are the weakest business types.
- **Chain outlets outperform independents**, and **Northern Ireland outperforms England and Wales**.
- **14 authorities, led by Birmingham, fall behind on three counts at once:** compliance, backlog and rating age.
- **Poor confidence in management is behind almost every 0 or 1 rating**, so management training matters more than premises alone.

## 🛠️ What I Built
**40 questions in four analysis types, 10 of each:** KPI, univariate, bivariate and multivariate.

The setup script also handles several data problems:
- the file's quoted Windows line endings (`\r\n`), which otherwise halved the row count
- normalised "Awaiting Inspection" values
- malformed rows, which are removed
- nation coding for Welsh authorities

**Techniques used:**
- reusable views (`v_establishments`, `v_la_summary`)
- percentiles with window functions
- RANK partitioned by nation
- CROSS JOIN to national benchmarks
- multi-condition filters

## 📁 Files
| File | Description |
|---|---|
| `fsa_setup.sql` | Creates the database, loads and cleans the data |
| `FoodHygiene_Queries.sql` | All 40 queries |
| `Report.pdf` | Full report: every result, interpretation and summary |

**Tools:** MySQL 8, MySQL Workbench
