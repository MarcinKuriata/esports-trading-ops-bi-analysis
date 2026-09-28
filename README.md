# Esports Trading Operations & Sportsbook BI Analysis

## 🎯 Project Overview
This repository contains an end-to-end Business Intelligence and Data Analytics project tailored for **Esports Trading Operations**. The objective is to model, monitor, and optimize trading performance, track core sportsbook KPIs (Turnover, GGR, Margin), and analyze market behavior for professional Counter-Strike matches.

---

## 📊 Key Performance Indicators (KPIs) Tracked
1. **Turnover:** Total volume of stakes placed across tournaments and match formats.
2. **Gross Gaming Revenue (GGR):** Net win/loss for the operator (Turnover - Payout).
3. **Margin (Hold %):** Built-in operator profitability indicator.
4. **Risk Exposure:** Tracking cumulative financial liability and match format volatility.

---

## 📂 Repository Structure
- data/                  # Raw match, team, and tournament datasets
- sql/                   
  - trading_analysis.sql   # Advanced BigQuery SQL scripts (KPIs, Window Functions, Market Balance)
- README.md

---

## 💡 SQL Implementation & Business Results

### 1. Financial KPI Aggregation by Tournament

**SQL Code:**
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

**Sample Output (BigQuery Results):**
| tournament | total_matches_played | cumulative_turnover_formatted | cumulative_payout_formatted | total_ggr_formatted | avg_margin_pct |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **ESL Pro League Season 19** | 79 | 17511822.00 | 16198435.35 | 1313386.65 | 7.5 |
| **PGL CS2 Major Copenhagen 2024** | 202 | 16775852.00 | 15517663.10 | 1258188.90 | 7.5 |
| **StarLadder Budapest Major 2025** | 107 | 16660314.00 | 15413398.95 | 1249735.05 | 7.5 |

---

### 2. Window Functions: Tournament Ranking & Cumulative Exposure

**SQL Code:**
SELECT 
    tournament,
    match_count,
    FORMAT('%.2f', tournament_turnover) AS tournament_turnover_formatted,
    DENSE_RANK() OVER (ORDER BY tournament_turnover DESC) AS turnover_rank,
    FORMAT('%.2f', SUM(tournament_turnover) OVER (ORDER BY tournament_turnover DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS running_total_turnover_formatted
FROM tournament_performance
ORDER BY turnover_rank ASC;

**Sample Output (BigQuery Results):**
| tournament | match_count | tournament_turnover_formatted | turnover_rank | running_total_turnover_formatted |
| :--- | :--- | :--- | :--- | :--- |
| **ESL Pro League Season 19** | 79 | 17511822.00 | 1 | 17511822.00 |
| **PGL CS2 Major Copenhagen 2024** | 202 | 16775852.00 | 2 | 34287674.00 |
| **StarLadder Budapest Major 2025** | 107 | 16660314.00 | 3 | 50950808.00 |

---

## 🚀 Business Impact for Traders
* **Volume Identification:** Pinpoints high-traffic tournaments allowing risk management teams to allocate capital and monitoring focus effectively.
* **Market Volatility Tracking:** Analyzes match formats (BO1 vs BO3) to evaluate score differentials and predictable outcomes, assisting in live odds adjustment.