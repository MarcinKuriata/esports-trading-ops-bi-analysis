--------------------------------------------------------------------------------
-- Project: Esports Trading Operations BI Analysis
-- Description: Advanced SQL module (02) featuring Window Functions (DENSE_RANK, 
--              running totals) and Sportsbook Market Balance / Match Format Analysis.
-- Target Platform: Google BigQuery
--------------------------------------------------------------------------------

-- ============================================================================
-- 1. FORMATTED FINANCIAL KPI AGGREGATION BY TOURNAMENT
-- ============================================================================
-- Business Logic: Aggregates match turnover, payouts, and GGR with clean 
-- string formatting (separators and 2 decimal places) for executive presentation.

WITH base_match_finances AS (
    SELECT 
        match_id,
        tournament,
        team1,
        team2,
        datetime,
        -- Simulate total betting turnover per match
        CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64) AS turnover,
        -- Simulate payout securing a stable 7.5% operator margin
        CAST((20000 + (ABS(MOD(CAST(match_id AS INT64), 75000)))) * 0.925 AS FLOAT64) AS payout
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
)
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches_played,
    -- Formatting numbers with clear comma separators and 2 decimal places
    FORMAT('%.2f', SUM(turnover)) AS cumulative_turnover_formatted,
    FORMAT('%.2f', SUM(payout)) AS cumulative_payout_formatted,
    FORMAT('%.2f', SUM(turnover) - SUM(payout)) AS total_ggr_formatted,
    ROUND(100.0 * (SUM(turnover) - SUM(payout)) / NULLIF(SUM(turnover), 0), 2) AS avg_margin_pct
FROM 
    base_match_finances
GROUP BY 
    tournament
ORDER BY 
    SUM(turnover) DESC;


-- ============================================================================
-- 2. WINDOW FUNCTIONS: TOURNAMENT RANKING & CUMULATIVE EXPOSURE
-- ============================================================================
-- Business Logic: Ranks tournaments by volume and tracks running financial 
-- totals over time with formatted output.

WITH tournament_performance AS (
    SELECT 
        tournament,
        COUNT(DISTINCT match_id) AS match_count,
        SUM(CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64)) AS tournament_turnover
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
    GROUP BY 
        tournament
)
SELECT 
    tournament,
    match_count,
    FORMAT('%.2f', tournament_turnover) AS tournament_turnover_formatted,
    -- Competitive rank based on trading volume
    DENSE_RANK() OVER (ORDER BY tournament_turnover DESC) AS turnover_rank,
    -- Running cumulative sum of turnover across all sorted tournaments
    FORMAT('%.2f', SUM(tournament_turnover) OVER (ORDER BY tournament_turnover DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS running_total_turnover_formatted
FROM 
    tournament_performance
ORDER BY 
    turnover_rank ASC;


-- ============================================================================
-- 3. SPORTSBOOK INSIGHT: MATCH OUTCOME & COMPETITIVE BALANCE ANALYSIS
-- ============================================================================
-- Business Logic: Standard sportsbook analysis evaluating match competitiveness.

SELECT 
    tournament,
    CASE 
        WHEN bestOf = 1 THEN 'BO1 (High Volatility)'
        WHEN bestOf = 3 THEN 'BO3 (Standard Pro)'
        WHEN bestOf = 5 THEN 'BO5 (Championship)'
        ELSE 'Other Format'
    END AS format_type,
    COUNT(match_id) AS total_matches,
    ROUND(AVG(ABS(score1_match - score2_match)), 2) AS avg_score_differential,
    ROUND(100.0 * COUNTIF(ABS(score1_match - score2_match) >= 2) / NULLIF(COUNT(match_id), 0), 2) AS dominant_wins_pct
FROM 
    `esports-trading-ops-analysis.cs2_tier_games.games`
WHERE 
    bestOf IS NOT NULL
GROUP BY 
    tournament, format_type
ORDER BY 
    total_matches DESC
LIMIT 20;