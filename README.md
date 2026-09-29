# Esports Trading Operations & Sportsbook BI Analysis

## 🎯 Project Overview
This repository contains an end-to-end Business Intelligence and Data Analytics project tailored for **Esports Trading Operations**. The objective is to model, monitor, and optimize trading performance, track core sportsbook KPIs (Turnover, GGR, Margin), and analyze market behavior for professional Counter-Strike matches.

---

## 📊 Key Performance Indicators (KPIs) Tracked
1. **Turnover:** Total volume of stakes placed across tournaments and match formats.
2. **Gross Gaming Revenue (GGR):** Net win/loss for the operator (`Turnover - Payout`).
3. **Margin (Hold %):** Built-in operator profitability indicator (`GGR / Turnover`).
4. **Risk Exposure & Volatility:** Tracking cumulative liability and format-level variance (BO1 vs BO3).

---

## 📂 Repository Structure
```text
├── data/
│   └── trading_matches_fact.csv   # Fact table grain at match level
├── sql/
│   ├── 01_kpi_aggregation.sql     # Formatted turnover, payout, GGR, and hold margin
│   └── 02_advanced_analytics.sql   # Window functions (DENSE_RANK, running exposure, format risk)
├── power_bi/
│   └── esports_trading_ops_monitoring.pbix  # Interactive Operations Dashboard (In Progress)
└── README.md
```

---

## 💡 SQL Implementation & Core Results

### 1. Financial KPI Aggregation by Tournament

**SQL Code:**
```sql
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches_played,
    FORMAT('%.2f', SUM(turnover)) AS cumulative_turnover_formatted,
    FORMAT('%.2f', SUM(payout)) AS cumulative_payout_formatted,
    FORMAT('%.2f', SUM(turnover) - SUM(payout)) AS total_ggr_formatted,
    ROUND(100.0 * (SUM(turnover) - SUM(payout)) / NULLIF(SUM(turnover), 0), 2) AS avg_margin_pct
FROM base_match_finances
GROUP BY tournament
ORDER BY SUM(turnover) DESC;
```

**Business Results:**
| Tournament | Matches | Turnover ($) | Payout ($) | GGR ($) | Margin % |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **ESL Pro League Season 19** | 79 | 17,511,822.00 | 16,198,435.35 | 1,313,386.65 | 7.50% |
| **PGL CS2 Major Copenhagen 2024** | 202 | 16,775,852.00 | 15,517,663.10 | 1,258,188.90 | 7.50% |
| **StarLadder Budapest Major 2025** | 107 | 16,660,314.00 | 15,413,398.95 | 1,249,735.05 | 7.50% |

---

### 2. Window Functions: Tournament Ranking & Cumulative Exposure

**SQL Code:**
```sql
SELECT 
    tournament,
    match_count,
    FORMAT('%.2f', tournament_turnover) AS tournament_turnover_formatted,
    DENSE_RANK() OVER (ORDER BY tournament_turnover DESC) AS turnover_rank,
    FORMAT('%.2f', SUM(tournament_turnover) OVER (ORDER BY tournament_turnover DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS running_total_turnover_formatted
FROM tournament_performance
ORDER BY turnover_rank ASC;
```

**Business Results:**
| Tournament | Matches | Turnover ($) | Rank | Running Total Turnover ($) |
| :--- | :---: | :---: | :---: | :---: |
| **ESL Pro League Season 19** | 79 | 17,511,822.00 | 1 | 17,511,822.00 |
| **PGL CS2 Major Copenhagen 2024** | 202 | 16,775,852.00 | 2 | 34,287,674.00 |
| **StarLadder Budapest Major 2025** | 107 | 16,660,314.00 | 3 | 50,950,808.00 |

---

## 📈 Power BI Operations Dashboard (WIP)
- **Data Pipeline:** Extracted clean match-level granularity from BigQuery into a local model.
- **DAX Model Built:** Dedicated `_Measures` table housing `Total Turnover`, `Total Payout`, `Total GGR`, `Hold Margin %`, and `Total Matches`.
- **Core Visual Layout:**
  - Executive KPI Ribbon (Turnover, Payout, GGR, Hold Margin %, Matches).
  - Liquidity Concentration Bar Chart (`Total Turnover` & `GGR` by Tournament).
  - Turnover Exposure Trajectory over Time (Area Chart).
  - Match Format Distribution (`BO1` vs `BO3` vs `BO5` Donut Chart).

---

## 🔮 Roadmap / Next Steps
- [x] BigQuery Data Extraction & Advanced SQL Modeling
- [x] Initial Power BI Architecture & DAX Measures Setup
- [ ] Finalize Custom Dark UI Styling & Visual Alignment
- [ ] Python Scripting for Advanced Volatility Simulation
- [ ] Executive Summary & Trading Risk Recommendations