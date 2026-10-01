# Esports Trading Operations & Sportsbook BI Analysis

![Power BI Operations Dashboard](Trading_dashboard_img.jpg)

## 🎯 Project Overview
This repository delivers an end-to-end Business Intelligence and Data Engineering project modeled for **Esports Trading Operations** (focusing on professional Counter-Strike fixtures). 

The pipeline ingests raw tournament records into **Google BigQuery**, enforces a strict automated **Data Quality & Audit Framework**, resolves map-vs-match granularity discrepancies, and delivers an executive **Dark UI Trading Console in Power BI** tracking liquidity, operator margins, and market liabilities.

---

## 📊 Core Trading KPIs Monitored
1. **Turnover (Total Handle):** Cumulative stake volume wagered across markets (**$527.0M**).
2. **Gross Gaming Revenue (GGR):** Net operator win/loss post-settlement: $\text{Turnover} - \text{Payout}$ (**$39.5M**).
3. **Hold Margin %:** Built-in operator profitability index: $\frac{\text{GGR}}{\text{Turnover}}$ (calibrated at **7.50%**).
4. **Unique Match Inventory:** Deduplicated competitive match series (**9,923 matches**).
5. **Format & Liability Exposure:** Risk dispersion across match structures (BO1 vs. BO3) and high-volume teams.

---

## 📂 Repository Structure
```text
├── data/
│   └── trading_matches_fact.csv            # Cleaned match-level fact table (9.9k series)
├── sql/
│   ├── 00_data_quality_audit.sql          # Automated pre-ingestion audit (PK, nulls, format validation)
│   ├── 01_kpi_aggregation.sql              # Tournament liquidity, GGR & margin aggregation
│   └── 02_advanced_analytics.sql           # Window functions (DENSE_RANK, running total handle)
├── power_bi/
│   └── esports_trading_ops_monitoring.pbix  # Production Power BI Dark UI report
├── Trading_dashboard_img.jpg               # Executive dashboard snapshot
└── README.md
```

---

## 🛠️ Data Quality & Audit Framework (BigQuery SQL)

Before downstream ingestion into Power BI, raw competitive records (`20,676` rows) were audited using `sql/00_data_quality_audit.sql`:

* **Granularity Audit:** Identified that `match_id` repeated across multi-map series (BO3/BO5). Ingesting raw logs directly would inflate trading turnover by ~2.1x. Deduplication logic (`ROW_NUMBER() OVER(PARTITION BY match_id)`) reduced the dataset to **9,923 unique series**.
* **Completeness & Metadata Sanity:** Isolated 136 records missing `bestOf` metadata; imputed default competitive standard (`BO3`) to prevent reporting drops.
* **Financial Integrity:** Verified non-negative stakes, payouts, and theoretical margin invariance ($\text{Hold} = 7.50\%$).

---

## 💡 SQL Analytics & Production Queries

### 1. Tournament Liquidity & Performance Aggregation (`01_kpi_aggregation.sql`)

```sql
WITH deduped_matches AS (
    SELECT 
        match_id,
        tournament,
        turnover,
        payout,
        (turnover - payout) AS ggr,
        ROW_NUMBER() OVER(PARTITION BY match_id ORDER BY datetime DESC) AS rn
    FROM `esports-trading-ops-analysis.cs2_tier_games.games`
    WHERE tournament IS NOT NULL
)
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches_played,
    FORMAT('%.2f', SUM(turnover)) AS cumulative_turnover_formatted,
    FORMAT('%.2f', SUM(payout)) AS cumulative_payout_formatted,
    FORMAT('%.2f', SUM(ggr)) AS total_ggr_formatted,
    ROUND(100.0 * SUM(ggr) / NULLIF(SUM(turnover), 0), 2) AS avg_margin_pct
FROM deduped_matches
WHERE rn = 1
GROUP BY tournament
ORDER BY SUM(turnover) DESC
LIMIT 10;
```

**Top Liquidity Tournaments:**
| Tournament | Matches | Turnover ($) | GGR ($) | Margin % |
| :--- | :---: | :---: | :---: | :---: |
| **PGL CS2 Major Copenhagen 2024: Closed Qualifiers** | 98 | 9,412,050.00 | 705,903.75 | 7.50% |
| **StarLadder Budapest Major 2025** | 68 | 6,698,820.00 | 502,411.50 | 7.50% |
| **BLAST.tv Austin Major 2025** | 64 | 6,211,400.00 | 465,855.00 | 7.50% |
| **ESL Pro League Season 19** | 52 | 5,340,900.00 | 400,567.50 | 7.50% |
| **IEM Cologne Major 2026** | 51 | 5,188,750.00 | 389,156.25 | 7.50% |

---

### 2. Window Functions: Exposure Ranking & Cumulative Run (`02_advanced_analytics.sql`)

```sql
WITH tournament_turnovers AS (
    SELECT 
        tournament,
        COUNT(DISTINCT match_id) AS match_count,
        SUM(turnover) AS tournament_turnover
    FROM deduped_matches
    WHERE rn = 1
    GROUP BY tournament
)
SELECT 
    tournament,
    match_count,
    FORMAT('%.2f', tournament_turnover) AS tournament_turnover_formatted,
    DENSE_RANK() OVER (ORDER BY tournament_turnover DESC) AS turnover_rank,
    FORMAT('%.2f', SUM(tournament_turnover) OVER (
        ORDER BY tournament_turnover DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )) AS running_total_turnover_formatted
FROM tournament_turnovers
ORDER BY turnover_rank ASC
LIMIT 10;
```

---

## 📈 Power BI Operations Dashboard (Dark UI Architecture)

* **Design Philosophy:** Engineered as a high-density Trading Desk console. Uses a tailored Dark UI palette (`#0F172A` background, `#1E293B` cards, `#334155` borders, 8px corner radius) with high-contrast Cyan (`#38BDF8`) and Purple accents.
* **Executive Metrics Ribbon:** Instant visibility on `$527.0M` Total Turnover, `$487.5M` Payout, `$39.5M` GGR, and a constant `7.5%` Hold Margin across `9.9K` fixtures[cite: 22, 23].
* **Liquidity Concentration:** Horizontal ranking of Tier-1 tournaments isolating peak volume events[cite: 22, 23].
* **Volume Trajectory:** Time-series area plot showcasing market seasonality and tournament clustering across months[cite: 22, 23].
* **Match Format Distribution:** Donut segmentation illustrating volume split across `BO3` (~91%), `BO1` (~8%), and `BO5` (<1%)[cite: 22, 23].
* **Team Exposure Monitor:** Top 10 teams (BetBoom Team, MOUZ, FURIA, 3DMAX, Vitality, Spirit) driving book handle and liability[cite: 22, 23].
* **Operational Slicers:** Compact vertical tile controls for match format selection (`BO1`, `BO3`, `BO5`) and a searchable dropdown for tournament filtering[cite: 22, 23].

---

## 📌 Strategic Recommendations for Trading Desks

1. **Dynamic Margin Buffering on BO1 Fixtures:**
   * *Finding:* BO1 matches display significantly higher outcome variance and upset frequency due to pistol round swing momentum.
   * *Action:* Elevate the theoretical hold from 7.50% to **8.50% - 9.00%** on BO1 group-stage fixtures to safeguard desk margin against unexpected underdog runs.
2. **Team Liability Limits & Real-Time Hedging:**
   * *Finding:* Handle is highly concentrated among top-tier squads (e.g., MOUZ, Vitality, Spirit)[cite: 22, 23].
   * *Action:* Institute automated liability caps and dynamic odds throttling when single-team exposure exceeds pre-set thresholds on matchday.
3. **Official Fast-Data Integration:**
   * *Action:* Pair algorithmic pricing models with sub-second official match server feeds (such as GRID data feeds) to eliminate court-siding exposure during live in-play trading.