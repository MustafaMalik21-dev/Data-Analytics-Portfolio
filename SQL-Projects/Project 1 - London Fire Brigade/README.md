# 🚒 Project 1: London Fire Brigade Incidents (SkillVersed Capstone)

**Business question:** Where, when and why does the London Fire Brigade get called out, how quickly does it respond, and what does its workload cost?

*SkillVersed Data Analytics with Gen AI, SQL Phase 2 capstone (Social-Impact SQL Analytics Project).*

## 📦 Dataset
**London Fire Brigade Incident and Mobilisation Records** (London Datastore), **1 January 2025 to 30 June 2026**:
- `incidents`: **209,908 rows**, one per incident
- `mobilisations`: **312,817 rows**, one per engine sent
- linked on `incident_number`

**End consumer:** LFB resource planning lead

## 🔍 Key Findings
- **False alarms are the biggest opportunity:** they are the most common call-out and the most costly in total, with **93,736 in 18 months costing £46.2m**. Repeat sites include hospitals, schools and student halls.
- **Demand is rising and shifting:** incidents grew in almost every borough and hour of the day into 2026. Special services and false alarms increased while fires fell.
- **Demand is concentrated in central London**, with Westminster and the Soho and Paddington station grounds carrying the heaviest load. However, it is the **outer boroughs** that struggle most to meet the 6- and 8-minute attendance targets.
- **Response times are slowly getting worse.** Traffic is the most frequent cause of delay, and wrong addresses add the most time.
- **Flats, especially high-rise blocks, are the biggest fire risk.** Clear peaks in early summer and on Bonfire Night call for planned extra cover.

## 🛠️ What I Built
- **75 questions** across five perspectives, each running from easy to difficult:

  | Perspective | Questions |
  |---|---|
  | Where incidents happen | Q1–15 |
  | When they happen | Q16–30 |
  | Response times | Q31–45 |
  | Cost | Q46–60 |
  | Incident types and impact | Q61–75 |

- **Three reusable views** (borough, station ground and daily summaries), each created once and reused in later questions
- **Techniques used:**
  - joins across both tables
  - CTEs
  - window functions (running totals, moving averages, LAG/LEAD, RANK)
  - correlated subqueries
  - conditional aggregation

## 📁 Files
| File | Description |
|---|---|
| `lfb_setup_load.sql`, `lfb_setup_clean.sql` | Loads the raw CSVs and builds the clean tables |
| `MustafaMalik_Queries.sql` | All 75 queries, runs top to bottom |
| `Report.pdf` | Full report: every result, interpretation and summary |
| `MustafaMalik_PGDA0626_SQLPhase2_Report.docx` | Submitted capstone report (Word) |

**Tools:** MySQL 8, MySQL Workbench
