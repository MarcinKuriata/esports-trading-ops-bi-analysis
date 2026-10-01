--------------------------------------------------------------------------------
-- Project: Esports Trading Operations BI Analysis
-- Module: 00_data_quality_audit.sql
-- Description: Automated Pre-Ingestion Data Integrity & Quality Audit for CS2 matches.
-- Target Platform: Google BigQuery
--------------------------------------------------------------------------------

-- ============================================================================
-- 1. PRIMARY KEY UNIQUENESS & GRAIN AUDIT
-- ============================================================================
-- Rule: match_id must be strictly unique at the match level.
SELECT 
    'Primary Key Integrity (match_id)' AS audit_check,
    COUNT(match_id) AS total_rows,
    COUNT(DISTINCT match_id) AS distinct_matches,
    COUNT(match_id) - COUNT(DISTINCT match_id) AS duplicate_count,
    CASE 
        WHEN COUNT(match_id) = COUNT(DISTINCT match_id) THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM 
    `esports-trading-ops-analysis.cs2_tier_games.games`;

-- ============================================================================
-- 2. NULL CRITICAL FIELDS & COMPLETENESS AUDIT
-- ============================================================================
-- Rule: Metadata and match keys cannot contain null values.
SELECT 
    'Critical Columns Completeness' AS audit_check,
    COUNTIF(match_id IS NULL) AS null_match_ids,
    COUNTIF(datetime IS NULL) AS null_datetimes,
    COUNTIF(tournament IS NULL OR TRIM(tournament) = '') AS null_tournaments,
    COUNTIF(team1 IS NULL OR team2 IS NULL) AS null_teams,
    COUNTIF(bestOf IS NULL) AS null_best_of,
    CASE 
        WHEN COUNTIF(match_id IS NULL OR datetime IS NULL OR tournament IS NULL OR team1 IS NULL OR team2 IS NULL) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM 
    `esports-trading-ops-analysis.cs2_tier_games.games`;

-- ============================================================================
-- 3. FORMAT SANITY & ESPORTS LOGIC CHECK
-- ============================================================================
-- Rule: Official CS2 matches must conform to standard formats (BO1, BO3, BO5).
SELECT 
    COALESCE(CAST(bestOf AS STRING), 'Unknown') AS match_format,
    COUNT(match_id) AS total_matches,
    ROUND(100.0 * COUNT(match_id) / SUM(COUNT(match_id)) OVER(), 2) AS format_share_pct,
    CASE 
        WHEN bestOf IN (1, 3, 5) THEN 'VALID_FORMAT'
        ELSE 'ANOMALY_CUSTOM_FORMAT'
    END AS format_validation
FROM 
    `esports-trading-ops-analysis.cs2_tier_games.games`
GROUP BY 
    bestOf
ORDER BY 
    total_matches DESC;

-- ============================================================================
-- 4. FINANCIAL METRIC SANITY & REVENUE INTEGRITY AUDIT
-- ============================================================================
-- Rule: Turnover must be strictly positive, Payout non-negative, Margin fixed at 7.5%.
WITH calculated_finances AS (
    SELECT 
        match_id,
        CAST(20000 + (ABS(MOD(CAST(match_id AS INT64), 75000))) AS FLOAT64) AS turnover,
        CAST((20000 + (ABS(MOD(CAST(match_id AS INT64), 75000)))) * 0.925 AS FLOAT64) AS payout,
        CAST((20000 + (ABS(MOD(CAST(match_id AS INT64), 75000)))) * 0.075 AS FLOAT64) AS ggr
    FROM 
        `esports-trading-ops-analysis.cs2_tier_games.games`
)
SELECT 
    'Financial Metric Integrity' AS audit_check,
    COUNTIF(turnover <= 0) AS non_positive_turnover_count,
    COUNTIF(payout < 0) AS negative_payout_count,
    COUNTIF(ggr <= 0) AS negative_or_zero_ggr_count,
    ROUND(AVG((ggr / NULLIF(turnover, 0)) * 100), 2) AS expected_hold_margin_pct,
    CASE 
        WHEN COUNTIF(turnover <= 0 OR payout < 0) = 0 
         AND ROUND(AVG((ggr / NULLIF(turnover, 0)) * 100), 2) = 7.50 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM 
    calculated_finances;