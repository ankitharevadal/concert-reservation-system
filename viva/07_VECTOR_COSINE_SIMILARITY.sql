-- ============================================================================
-- VIVA DEMONSTRATION FILE 07: 5D VECTOR COSINE SIMILARITY SEARCH
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: "For vectors, show the queries and explain the similarity math."
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONCEPT EXPLANATION (Tell the evaluator):
-- Each concert has a 5-dimensional audio feature embedding vector:
-- [Energy, Acousticness, Danceability, Valence, Stadium Scale]
-- Values are normalized between 0.00 and 1.00.
-- When an attendee searches for a concert that matches their musical vibe,
-- we compute the Cosine Similarity between their target vector and all concerts:
--
--           u . v           SUM(u_i * v_i)
-- cos(θ) = ------- = -----------------------------
--          |u| |v|   SQRT(SUM(u_i^2)) * SQRT(SUM(v_i^2))
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 1. INSPECT THE CONCERT VECTOR EMBEDDINGS TABLE
-- ----------------------------------------------------------------------------
SELECT 
    embedding_id,
    event_title,
    vibe_category,
    feature_vector,
    tags
FROM concert_vector_embeddings;


-- ----------------------------------------------------------------------------
-- 2. DEMO QUERY A: USER WANTS AN "INTIMATE ACOUSTIC INDIE FOLK" VIBE
-- Target Vector: [0.30 Energy, 0.90 Acoustic, 0.35 Dance, 0.50 Valence, 0.25 Stadium]
-- Expected Winner: Prateek Kuhad: Silhouettes Under the Stars (~0.99 similarity!)
-- ----------------------------------------------------------------------------
WITH user_target AS (
    SELECT ARRAY[0.30, 0.90, 0.35, 0.50, 0.25]::FLOAT8[] AS u_vec
)
SELECT 
    cve.event_id,
    cve.event_title,
    cve.vibe_category,
    cve.tags,
    ROUND((
        (
            cve.feature_vector[1] * u_vec[1] +
            cve.feature_vector[2] * u_vec[2] +
            cve.feature_vector[3] * u_vec[3] +
            cve.feature_vector[4] * u_vec[4] +
            cve.feature_vector[5] * u_vec[5]
        ) / (
            SQRT(
                POWER(cve.feature_vector[1], 2) +
                POWER(cve.feature_vector[2], 2) +
                POWER(cve.feature_vector[3], 2) +
                POWER(cve.feature_vector[4], 2) +
                POWER(cve.feature_vector[5], 2)
            ) *
            SQRT(
                POWER(u_vec[1], 2) +
                POWER(u_vec[2], 2) +
                POWER(u_vec[3], 2) +
                POWER(u_vec[4], 2) +
                POWER(u_vec[5], 2)
            )
        )
    )::NUMERIC, 4) AS cosine_similarity,
    ROUND((
        (
            cve.feature_vector[1] * u_vec[1] +
            cve.feature_vector[2] * u_vec[2] +
            cve.feature_vector[3] * u_vec[3] +
            cve.feature_vector[4] * u_vec[4] +
            cve.feature_vector[5] * u_vec[5]
        ) / (
            SQRT(POWER(cve.feature_vector[1], 2) + POWER(cve.feature_vector[2], 2) + POWER(cve.feature_vector[3], 2) + POWER(cve.feature_vector[4], 2) + POWER(cve.feature_vector[5], 2)) *
            SQRT(POWER(u_vec[1], 2) + POWER(u_vec[2], 2) + POWER(u_vec[3], 2) + POWER(u_vec[4], 2) + POWER(u_vec[5], 2))
        )
    )::NUMERIC * 100.0, 1) || '%' AS match_percentage
FROM concert_vector_embeddings cve, user_target
ORDER BY cosine_similarity DESC;


-- ----------------------------------------------------------------------------
-- 3. DEMO QUERY B: USER WANTS A "HIGH-ENERGY STADIUM ROCK" VIBE
-- Target Vector: [0.95 Energy, 0.30 Acoustic, 0.80 Dance, 0.95 Valence, 0.98 Stadium]
-- Expected Winner: Coldplay: Music of the Spheres Live (~0.997 similarity!)
-- ----------------------------------------------------------------------------
WITH user_target AS (
    SELECT ARRAY[0.95, 0.30, 0.80, 0.95, 0.98]::FLOAT8[] AS u_vec
)
SELECT 
    cve.event_id,
    cve.event_title,
    cve.vibe_category,
    ROUND((
        (
            cve.feature_vector[1] * u_vec[1] +
            cve.feature_vector[2] * u_vec[2] +
            cve.feature_vector[3] * u_vec[3] +
            cve.feature_vector[4] * u_vec[4] +
            cve.feature_vector[5] * u_vec[5]
        ) / (
            SQRT(POWER(cve.feature_vector[1], 2) + POWER(cve.feature_vector[2], 2) + POWER(cve.feature_vector[3], 2) + POWER(cve.feature_vector[4], 2) + POWER(cve.feature_vector[5], 2)) *
            SQRT(POWER(u_vec[1], 2) + POWER(u_vec[2], 2) + POWER(u_vec[3], 2) + POWER(u_vec[4], 2) + POWER(u_vec[5], 2))
        )
    )::NUMERIC * 100.0, 1) || '%' AS match_percentage
FROM concert_vector_embeddings cve, user_target
ORDER BY match_percentage DESC;

