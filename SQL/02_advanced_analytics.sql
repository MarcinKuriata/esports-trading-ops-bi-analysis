--------------------------------------------------------------------------------
-- Project: Esports Trading Operations BI Analysis
-- Module: 02_advanced_analytics.sql
-- Description: Advanced SQL module featuring Window Functions (DENSE_RANK, 
--              running totals) and Match Format Risk Analysis at Match Grain.
-- Target Platform: Google BigQuery
--------------------------------------------------------------------------------

-- Common deduplicated CTE to enforce 1 row = 1 unique match series grain
WITH deduped_matches AS (
    SELECT 
        CAST(match_id AS STRING) AS match_id,
        tournament,
        team1,
        team2,
        datetime,
        COALESCE(bestOf, 3) AS bestOf,
        score1_match,
        score2_match,
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

-- ============================================================================
-- 1. FORMATTED FINANCIAL KPI AGGREGATION BY TOURNAMENT
-- ============================================================================
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches_played,
    FORMAT('%.2f', SUM(turnover)) AS cumulative_turnover_formatted,
    FORMAT('%.2f', SUM(payout)) AS cumulative_payout_formatted,
    FORMAT('%.2f', SUM(ggr)) AS total_ggr_formatted,
    ROUND(100.0 * SUM(ggr) / NULLIF(SUM(turnover), 0), 2) AS avg_margin_pct
FROM 
    deduped_matches
WHERE 
    rn = 1
GROUP BY 
    tournament
ORDER BY 
    SUM(turnover) DESC
LIMIT 10;


-- ============================================================================
-- 2. WINDOW FUNCTIONS: TOURNAMENT RANKING & CUMULATIVE EXPOSURE
-- ============================================================================
WITH tournament_performance AS (
    SELECT 
        tournament,
        COUNT(DISTINCT match_id) AS match_count,
        SUM(turnover) AS tournament_turnover
    FROM 
        deduped_matches
    WHERE 
        rn = 1
    GROUP BY 
        tournament
)
SELECT 
    tournament,
    match_count,
    FORMAT('%.2f', tournament_turnover) AS tournament_turnover_formatted,
    -- Competitive rank based on trading volume
    DENSE_RANK() OVER (ORDER BY tournament_turnover DESC) AS turnover_rank,
    -- Running cumulative sum of turnover across sorted tournaments
    FORMAT('%.2f', SUM(tournament_turnover) OVER (
        ORDER BY tournament_turnover DESC 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )) AS running_total_turnover_formatted
FROM 
    tournament_performance
ORDER BY 
    turnover_rank ASC
LIMIT 10;


-- ============================================================================
-- 3. SPORTSBOOK RISK ANALYSIS: FORMAT VOLATILITY & SCORE SPREADS
-- ============================================================================
-- Business Logic: Evaluates outcome competitiveness across formats.
SELECT 
    CASE 
        WHEN bestOf = 1 THEN 'BO1 (High Volatility)'
        WHEN bestOf = 3 THEN 'BO3 (Standard Pro)'
        WHEN bestOf = 5 THEN 'BO5 (Championship)'
        ELSE 'Other Format'
    END AS format_type,
    COUNT(match_id) AS total_matches,
    FORMAT('%.2f', SUM(turnover)) AS total_turnover_formatted,
    ROUND(AVG(ABS(score1_match - score2_match)), 2) AS avg_score_differential,
    ROUND(100.0 * COUNTIF(ABS(score1_match - score2_match) >= 2) / NULLIF(COUNT(match_id), 0), 2) AS dominant_series_pct
FROM 
    deduped_matches
WHERE 
    rn = 1
GROUP BY 
    format_type
ORDER BY 
    total_matches DESC;