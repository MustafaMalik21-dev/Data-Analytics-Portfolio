# 🎓 Project 3: School Performance and Disadvantage (DfE KS4)

**Business question:** How strongly does disadvantage shape GCSE results in England, and which areas and schools beat the odds?

## 📦 Dataset
Three Department for Education sources, joined on school URN and local authority code:
- **KS4 performance tables 2024/25 (final)**, school level: Attainment 8, English and maths grade 5+, disadvantaged pupil measures
- **Get Information About Schools (GIAS)**: school type, admissions policy, trust, gender and other characteristics
- **LA and region codes**

Suppression codes (NA, NP, NE, SUPP, LOWCOV, SP, RE) are converted to NULL during the load, and % signs are stripped.

**End consumer:** Local authority education officer

## 🔍 Key Findings
- **Disadvantage is the strongest single influence:**
  - Disadvantaged pupils average **34.9 in Attainment 8 against 50.4** for other pupils.
  - They are half as likely to get grade 5+ in English and maths (**25.8% v 53.1%**).
  - Disadvantage correlates with Attainment 8 at **−0.56**.
- **London leads every region** by at least 3.4 points. Its disadvantaged pupils average 44.3, with the smallest gap.
- **19 of the 24 high-disadvantage local authorities that beat the national average are London boroughs.**
- **High disadvantage does not rule out high attainment.** "Beating the odds" schools such as those in Star Academies and Mossbourne show this.
- **Higher EAL (pupils with English as an additional language) is linked to higher results** at every level of disadvantage.
- **Academy status makes little difference** once region is held constant.
- **Girls outperform boys** in four out of five mixed schools.

## 🛠️ What I Built
**40 questions in four analysis types, 10 of each:**

| Type | Questions | What it covers |
|---|---|---|
| KPI | Q1–Q10 | Headline figures and benchmarks |
| Univariate | Q11–Q20 | Distributions of single measures |
| Bivariate | Q21–Q30 | How one measure varies with another, including correlation |
| Multivariate | Q31–Q40 | Disadvantage, region, EAL and school type together |

**Techniques used:**
- multi-source joins
- reusable views (`v_schools`, `v_la_benchmarks`)
- CTEs
- banding with CASE
- window functions
- Pearson correlation calculated in SQL

## 📁 Files
| File | Description |
|---|---|
| `ks4_setup.sql` | Creates the database and loads the three sources |
| `KS4_Queries.sql` | All 40 queries |
| `Report.pdf` | Full report: every result, interpretation and summary |

**Limitation:** Progress 8 was not published this year, so school comparisons reflect pupil intake as well as teaching.

**Tools:** MySQL 8, MySQL Workbench
