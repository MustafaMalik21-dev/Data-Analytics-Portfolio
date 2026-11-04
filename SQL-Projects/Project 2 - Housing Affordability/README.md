# 🏠 Project 2: Housing Affordability (HM Land Registry)

**Business question:** What do homes cost in England and Wales, where can buyers afford, and how are prices changing?

## 📦 Dataset
**HM Land Registry Price Paid Data** (gov.uk): every residential sale in England and Wales from **1 January 2025 to 30 September 2026**, **1,450,241 sales** in total.
- The two yearly files are loaded into one `sales` table, typed and cleaned on the way in.
- Two lookup tables decode the property type and tenure codes.

## 👥 End Consumers
One perspective (housing affordability), answered for three end consumers with **15 questions each (45 in total)**, from easy to difficult:
1. **First-time buyer adviser** at a housing charity (Q1–Q15)
2. **Local authority housing planner** (Q16–Q30)
3. **Property market journalist** (Q31–Q45)

## 🔍 Key Findings
- **First-time buyers:**
  - Starter-home prices range from a lower quartile of **£96,000 in County Durham** to **£387,750 in Greater London**.
  - Flats are the cheapest way in, but are almost always leasehold.
  - Birmingham and Leeds combine plenty of homes for sale with below-average entry prices.
- **Planners:**
  - New-build premiums are highest in **inner London, Salford and Birmingham**, where new supply targets the top of the market.
  - Company and buy-to-let purchases make up almost **a third of sales in Hartlepool, Middlesbrough and Hull**.
  - Prices rose fastest in cheaper Lancashire, Merseyside and Welsh districts, while central London fell.
- **Journalists:**
  - The **March 2025 stamp duty rush nearly doubled monthly sales** before an April collapse.
  - **Friday accounts for 46% of completions.**
  - Many "record" prices are commercial or bulk deals rather than single homes.

## 🛠️ What I Built
- A setup script that loads both yearly files (no header rows) into a single typed table, with data quality checks
- **Three reusable views** (`v_homes`, `v_district_year`, `v_monthly_market`)
- **Techniques used:**
  - CTEs
  - window functions (lower quartiles, RANK, running totals)
  - like-for-like year-on-year comparisons (Jan–Sep 2025 vs Jan–Sep 2026)
  - conditional aggregation

## 📁 Files
| File | Description |
|---|---|
| `pricepaid_setup.sql` | Creates the database and loads the data |
| `PricePaid_Queries.sql` | All 45 queries, runs top to bottom |
| `Report.pdf` | Full report: every result, interpretation and summary |

**Tools:** MySQL 8, MySQL Workbench
