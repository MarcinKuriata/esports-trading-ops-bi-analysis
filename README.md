# Esports Trading Operations & Sportsbook BI Analysis

## 🎯 Project Overview
This repository contains an end-to-end Business Intelligence and Data Analytics project tailored for **Esports Trading Operations**. The objective is to model, monitor, and optimize trading performance, track core sportsbook KPIs (Turnover, GGR, Margin), and analyze market behavior for professional Counter-Strike matches.

---

## 📊 Key Performance Indicators (KPIs) Tracked
1. **Turnover:** Total volume of stakes placed across tournaments and match formats.
2. **Gross Gaming Revenue (GGR):** Net win/loss for the operator (`Turnover - Payout`).
3. **Margin (Hold %):** Built-in operator profitability indicator.
4. **Risk Exposure:** Tracking cumulative financial liability and match format volatility.

---

## 📂 Repository Structure
```text
├── data/
├── sql/
│   ├── 01_kpi_aggregation.sql
│   └── 02_advanced_analytics.sql
└── README.md
```

---

## 💡 SQL Implementation & Business Results

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

## 🚀 Business Impact for Traders
* **Volume Identification:** Pinpoints high-traffic tournaments allowing risk management teams to allocate capital and monitoring focus effectively.
* **Market Volatility Tracking:** Analyzes match formats (BO1 vs BO3) to evaluate score differentials and predictable outcomes, assisting in live odds adjustment.

---

## 🔮 Roadmap / Next Steps (In Progress)
- [ ] **Power BI Dashboard:** Interactive executive dashboard visualizing turnover trends, live margin monitoring, and tournament exposure cards.
- [ ] **Python Integration:** Automated pipeline / feature engineering scripts for odds drift analysis and predictive market simulations.
- [ ] **Stakeholder Recommendations:** Executive summary report with actionable trading limits and risk adjustment strategies.