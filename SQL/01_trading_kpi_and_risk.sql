--------------------------------------------------------------------------------
-- Project: Esports Trading Operations BI Analysis
-- Description: Core SQL module for calculating Betting KPIs (Turnover, GGR, Margin) 
--              and Risk Exposure for Counter-Strike professional matches.
-- Target Platform: Google BigQuery
--------------------------------------------------------------------------------

-- ============================================================================
-- 1. KPI AGGREGATION BY TOURNAMENT (Turnover, Payout, GGR, Margin / Hold %)
-- ============================================================================
-- Business Logic: Aggregates betting volume and operator revenue per tournament 
-- to identify high-performing segments for the trading desk.

WITH match_finances AS (
    SELECT 
        match_id,
        tournament,
        team1,
        team2,
        -- Simulate total betting turnover per match based on match ID hash
        15000 + (ABS(MOD(CAST(match_id AS INT64), 50000))) AS turnover,
        
        -- Simulate payouts maintaining a healthy operator margin (approx. 7%)
        (15000 + (ABS(MOD(CAST(match_id AS INT64), 50000)))) * 0.93 AS payout
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
)
SELECT 
    tournament,
    COUNT(DISTINCT match_id) AS total_matches,
    SUM(turnover) AS total_turnover,
    SUM(payout) AS total_payout,
    -- Gross Gaming Revenue (GGR): Net win for the operator
    SUM(turnover) - SUM(payout) AS ggr,
    -- Margin Percentage (Hold %): Operator profitability indicator
    ROUND(100.0 * (SUM(turnover) - SUM(payout)) / NULLIF(SUM(turnover), 0), 2) AS margin_percentage
FROM 
    match_finances
GROUP BY 
    tournament
HAVING 
    total_matches > 2
ORDER BY 
    total_turnover DESC;


-- ============================================================================
-- 2. RISK EXPOSURE MONITORING FOR LIVE / UPCOMING TRADING
-- ============================================================================
-- Business Logic: Flags matches exceeding risk thresholds to help traders 
-- monitor high-liability fixtures and adjust live odds proactively.

WITH match_exposure AS (
    SELECT 
        match_id,
        tournament,
        team1,
        team2,
        datetime,
        -- Simulate total stakes placed on specific fixtures
        5000 + (ABS(MOD(CAST(match_id AS INT64), 100000))) AS total_stake_on_match,
        -- Calculate max potential single-bet exposure liability
        (5000 + (ABS(MOD(CAST(match_id AS INT64), 100000)))) * 0.45 AS max_single_stake_exposure
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
    WHERE 
        datetime >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 365 DAY)
)
SELECT 
    match_id,
    tournament,
    CONCAT(team1, ' vs ', team2) AS match_fixture,
    datetime,
    total_stake_on_match,
    max_single_stake_exposure
FROM 
    match_exposure
WHERE 
    total_stake_on_match > 60000 -- High-risk volume threshold for traders
ORDER BY 
    total_stake_on_match DESC
LIMIT 15;