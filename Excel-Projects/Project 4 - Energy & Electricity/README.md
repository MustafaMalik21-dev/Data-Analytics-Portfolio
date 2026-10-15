# ☀️ Project 4: Energy & Electricity (Solar Power Generation)

**Business question:** How well are two solar plants performing, which inverters need maintenance, and how much output is lost to weather versus equipment?

![Plant Output & Performance](Dashboard%201.png)

## 📦 Dataset
**Solar Power Generation Data** (public, Kaggle): 4 source files covering **2 solar plants, 44 inverters and 2 weather sensors**, recorded every 15 minutes over **34 days** (15 May – 17 Jun 2020), **142,917 rows** in total.

## 🧹 Data Quality Work
Before building anything, I measured every row of the dataset and documented the results in a full data quality assessment. Two real defects turned up:
- **Plant 1 DC power was inflated exactly 10×.** Its inverters showed a 9.78% AC/DC ratio, which is physically impossible. Dividing by 10 gives 97.8%, an exact match to Plant 2, confirming a systematic scaling error. I corrected it before any efficiency analysis.
- **Most Plant 2 lifetime yield values were on the wrong scale.** I derived all energy figures from daily yield instead.

I also replaced unreadable inverter IDs (e.g. `1BY6WEcLGh8j5v7`) with clear labels (`P1-INV01` … `P2-INV22`), flagged inverters with poor telemetry coverage, and built a **star schema** (fact tables for generation and weather, dimension tables for plants and inverters) in Power Pivot.

## 🔍 Key Findings
- The two plants delivered **9.38 million kWh** at an estimated **performance ratio of 82.2%**, with **Plant 1 outproducing Plant 2** by a wide margin.
- **Plant 2's performance ratio is much more volatile**, dipping sharply on many days while Plant 1 stays steady, which points to equipment issues rather than weather, since both plants experience similar sunlight.
- Plant 2's midday output shows a **flat top**, a sign of **inverter clipping** that caps generation at peak sunshine.
- Inverter conversion efficiency is healthy at **97.8%**, but **4 inverters need attention**, with **P2-INV20** the weakest. Several Plant 2 inverters fall below the **80% telemetry coverage** target.
- Panels run on average **5.1°C hotter** than the surrounding air, and losses concentrate in the middle of the day.

## 🛠️ What I Built
Three themed dashboards with shared navigation, each for a different audience:
1. **Plant Output & Performance**: energy delivered, performance ratio and best-performing inverters (for plant managers)
2. **Inverter Fleet Health**: efficiency, telemetry coverage and fault detection (for maintenance teams)
3. **Environmental Response & Losses**: irradiance, temperature and when losses occur (for engineers)

<p align="center">
  <img src="Dashboard%202.png" width="45%"> <img src="Dashboard%203.png" width="45%">
</p>

## 📁 Files
| File | Description |
|---|---|
| Excel workbook | The full multi-file Power Pivot workbook |
| `Solar_Dataset2_Data_Quality_Assessment_-_Work_Log.pdf` | Full data quality assessment, issue log and fixes |

**Tools:** Excel, Power Pivot (star schema, DAX measures), Power Query, timeline and slicers
