--------------------------------------------------------------------------------
-- Project: Esports Trading Operations BI Analysis
-- Module: 01_kpi_aggregation.sql
-- Description: Core SQL module for calculating Betting KPIs (Turnover, GGR, Margin) 
--              and Risk Exposure at deduplicated Match Series grain for CS2.
-- Target Platform: Google BigQuery
--------------------------------------------------------------------------------

-- ============================================================================
-- 1. KPI AGGREGATION BY TOURNAMENT (Turnover, Payout, GGR, Hold Margin %)
-- ============================================================================
-- Business Logic: Aggregates betting volume and operator revenue per tournament 
-- at unique match-series grain, matching production Power BI metrics.

WITH deduped_matches AS (
    SELECT 
        CAST(match_id AS STRING) AS match_id,
        tournament,
        team1,
        team2,
        datetime,
        -- Financial modeling: 7.50% theoretical operator hold margin
        ROUND(CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64), 2) AS turnover,
        ROUND(CAST((20000 + (ABS(MOD(CAST(match_id AS INT64), 75000)))) * 0.925 AS FLOAT64), 2) AS payout,
        ROUND(CAST((20000 + (ABS(MOD(CAST(match_id AS INT64), 75000)))) * 0.075 AS FLOAT64), 2) AS ggr,
        ROW_NUMBER() OVER(PARTITION BY match_id ORDER BY datetime DESC) AS rn
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
    WHERE 
        match_id IS NOT NULL 
        AND tournament IS NOT NULL
        AND team1 IS NOT NULL 
        AND team2 IS NOT NULL
)
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches_played,
    ROUND(SUM(turnover), 2) AS cumulative_turnover,
    ROUND(SUM(payout), 2) AS cumulative_payout,
    ROUND(SUM(ggr), 2) AS total_ggr,
    -- Margin Percentage (Hold %): Operator profitability indicator
    ROUND(100.0 * SUM(ggr) / NULLIF(SUM(turnover), 0), 2) AS hold_margin_pct
FROM 
    deduped_matches
WHERE 
    rn = 1
GROUP BY 
    tournament
HAVING 
    total_matches_played >= 5
ORDER BY 
    cumulative_turnover DESC;


-- ============================================================================
-- 2. RISK EXPOSURE MONITORING FOR LIVE / UPCOMING TRADING
-- ============================================================================
-- Business Logic: Flags deduplicated matches exceeding volume risk thresholds 
-- to monitor book liabilities and adjust pricing limits proactively.

WITH deduped_exposure AS (
    SELECT 
        CAST(match_id AS STRING) AS match_id,
        tournament,
        team1,
        team2,
        datetime,
        ROUND(CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64), 2) AS turnover,
        -- Simulate single-side book liability threshold (45% max concentration)
        ROUND(CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64) * 0.45, 2) AS max_single_stake_exposure,
        ROW_NUMBER() OVER(PARTITION BY match_id ORDER BY datetime DESC) AS rn
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
    WHERE 
        match_id IS NOT NULL 
        AND tournament IS NOT NULL
)
SELECT 
    match_id,
    tournament,
    CONCAT(team1, ' vs ', team2) AS match_fixture,
    datetime,
    turnover AS total_stake_on_match,
    max_single_stake_exposure
FROM 
    deduped_exposure
WHERE 
    rn = 1
    AND turnover > 80000 -- High-liability threshold for trading desks
ORDER BY 
    turnover DESC
LIMIT 15;