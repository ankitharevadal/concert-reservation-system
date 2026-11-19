-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 05_nosql_vector.sql (NoSQL Document Store CRUD & Vector Database Engine)
-- ============================================================================

-- ============================================================================
-- PART A: NoSQL DOCUMENT STORE (PostgreSQL JSONB / Document RUD)
-- ============================================================================

-- 1. NoSQL SCHEMA SETUP
DROP TABLE IF EXISTS event_feedback_nosql;
CREATE TABLE event_feedback_nosql (
    feedback_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    review_doc JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- GIN Index for rapid inverted-index NoSQL querying
CREATE INDEX idx_feedback_jsonb ON event_feedback_nosql USING gin (review_doc);

-- ----------------------------------------------------------------------------
-- 2. NoSQL [CREATE]: Inserting Rich Nested Document Objects
-- ----------------------------------------------------------------------------
INSERT INTO event_feedback_nosql (event_id, user_id, review_doc) VALUES
(1, 3, '{
    "reviewer": "Rohan Verma",
    "rating": 5,
    "sentiment": "ECSTATIC",
    "categories": {
        "sound_quality": 9.8,
        "seat_comfort": 8.5,
        "entry_smoothness": 9.0
    },
    "vibe_tags": ["spiritual", "orchestral", "immersive"],
    "comment": "Roja performed live with 50 violinists was life-changing!",
    "helpful_votes": 34
}'),
(1, 4, '{
    "reviewer": "Sneha Reddy",
    "rating": 4,
    "sentiment": "VERY_GOOD",
    "categories": {
        "sound_quality": 9.0,
        "seat_comfort": 7.8,
        "entry_smoothness": 6.5
    },
    "vibe_tags": ["nostalgic", "energetic"],
    "comment": "Incredible music, though parking line was long at gate 2.",
    "helpful_votes": 12
}'),
(2, 5, '{
    "reviewer": "Vikram Malhotra",
    "rating": 5,
    "sentiment": "MIND_BLOWING",
    "categories": {
        "sound_quality": 9.9,
        "seat_comfort": 9.2,
        "entry_smoothness": 9.5
    },
    "vibe_tags": ["colorful", "stadium_rock", "lasers"],
    "comment": "The wristband light show synchronized with Yellow was pure magic!",
    "helpful_votes": 89
}');

-- ----------------------------------------------------------------------------
-- 3. NoSQL [READ]: Querying Nested Attributes and Array Search
-- ----------------------------------------------------------------------------
-- Query A: Filter documents containing the specific vibe tag "spiritual" (JSON containment @>)
SELECT 
    feedback_id,
    event_id,
    review_doc->>'reviewer' AS reviewer_name,
    (review_doc->>'rating')::INT AS star_rating,
    review_doc->'categories'->>'sound_quality' AS sound_score,
    review_doc->>'comment' AS review_text
FROM event_feedback_nosql
WHERE review_doc @> '{"vibe_tags": ["spiritual"]}';

-- Query B: Calculate Average Rating and Sound Quality from NoSQL documents
SELECT 
    event_id,
    ROUND(AVG((review_doc->>'rating')::NUMERIC), 2) AS avg_star_rating,
    ROUND(AVG((review_doc->'categories'->>'sound_quality')::NUMERIC), 2) AS avg_sound_quality,
    COUNT(*) AS total_reviews
FROM event_feedback_nosql
GROUP BY event_id;

-- ----------------------------------------------------------------------------
-- 4. NoSQL [UPDATE]: Modify Nested Field in JSON document
-- (Simulate user upvoting a review: helpful_votes + 1)
-- ----------------------------------------------------------------------------
UPDATE event_feedback_nosql
SET review_doc = jsonb_set(
    review_doc, 
    '{helpful_votes}', 
    to_jsonb(((review_doc->>'helpful_votes')::INT + 1))
)
WHERE feedback_id = 1;

-- ----------------------------------------------------------------------------
-- 5. NoSQL [DELETE]: Remove review document by feedback_id
-- ----------------------------------------------------------------------------
DELETE FROM event_feedback_nosql 
WHERE feedback_id = 999; -- Safely target demo ID


-- ============================================================================
-- PART B: VECTOR DATABASE & INTELLIGENT RECOMMENDATION ENGINE
-- ============================================================================
-- Embeddings represent a 5-dimensional audio feature space:
-- Dimension 1: Energy (0.0 to 1.0)
-- Dimension 2: Acousticness (0.0 to 1.0)
-- Dimension 3: Danceability (0.0 to 1.0)
-- Dimension 4: Valence / Positivity (0.0 to 1.0)
-- Dimension 5: Crowd Scale / Stadium Intensity (0.0 to 1.0)
-- ============================================================================

DROP TABLE IF EXISTS concert_vector_embeddings;
CREATE TABLE concert_vector_embeddings (
    embedding_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL REFERENCES concert_events(event_id) ON DELETE CASCADE,
    event_title VARCHAR(200) NOT NULL,
    vibe_category VARCHAR(50) NOT NULL,
    -- 5-dimensional embedding vector stored as numeric array
    feature_vector FLOAT8[] NOT NULL,
    tags VARCHAR(100) NOT NULL
);

-- Seed Vector Embeddings for our concerts
INSERT INTO concert_vector_embeddings (event_id, event_title, vibe_category, feature_vector, tags) VALUES
-- AR Rahman: Moderate Energy, High Acoustic/Orchestral, Moderate Dance, High Valence, High Stadium
(1, 'A. R. Rahman: Symphony of India', 'Symphonic Fusion', ARRAY[0.65, 0.88, 0.45, 0.82, 0.90], 'orchestra,sufi,spiritual,peaceful'),

-- Coldplay: High Energy, Medium Acoustic, High Dance, High Valence, Massive Stadium
(2, 'Coldplay: Music of the Spheres Live', 'Stadium Anthem Rock', ARRAY[0.92, 0.35, 0.78, 0.95, 0.98], 'rock,lights,euphoric,colorful'),

-- Diljit Dosanjh: Maximum Energy, Low Acoustic, Maximum Dance, High Valence, High Stadium
(3, 'Dil-Luminati Arena Tour Bengaluru', 'Bhangra Hip-Hop Pop', ARRAY[0.96, 0.12, 0.98, 0.91, 0.92], 'party,bhangra,loud,club,dancing'),

-- Prateek Kuhad: Low Energy, High Acoustic, Low Dance, Intimate/Melancholy, Small Crowd
(4, 'Prateek Kuhad: Silhouettes Under the Stars', 'Intimate Indie Folk', ARRAY[0.32, 0.94, 0.38, 0.55, 0.25], 'acoustic,cozy,intimate,calm,gentle');


-- ============================================================================
-- VECTOR COSINE SIMILARITY QUERY
-- Finds concerts matching a user's taste preference vector:
-- User Target Vector: [0.30, 0.90, 0.35, 0.50, 0.30] 
-- (User wants: Calm, highly acoustic, intimate evening vibe)
-- Formula: Cosine Similarity = (A . B) / (||A|| * ||B||)
-- ============================================================================

WITH user_target AS (
    SELECT ARRAY[0.30, 0.90, 0.35, 0.50, 0.30]::FLOAT8[] AS u_vec
)
SELECT 
    cve.event_id,
    cve.event_title,
    cve.vibe_category,
    cve.tags,
    ROUND(
        (
            -- Dot product calculation:
            (cve.feature_vector[1] * u_vec[1] +
             cve.feature_vector[2] * u_vec[2] +
             cve.feature_vector[3] * u_vec[3] +
             cve.feature_vector[4] * u_vec[4] +
             cve.feature_vector[5] * u_vec[5])
            /
            -- Magnitudes:
            (
                SQRT(POWER(cve.feature_vector[1], 2) + POWER(cve.feature_vector[2], 2) + POWER(cve.feature_vector[3], 2) + POWER(cve.feature_vector[4], 2) + POWER(cve.feature_vector[5], 2))
                *
                SQRT(POWER(u_vec[1], 2) + POWER(u_vec[2], 2) + POWER(u_vec[3], 2) + POWER(u_vec[4], 2) + POWER(u_vec[5], 2))
            )
        )::NUMERIC, 4
    ) AS cosine_similarity_score
FROM concert_vector_embeddings cve, user_target
ORDER BY cosine_similarity_score DESC;
-- Result: "Prateek Kuhad: Silhouettes Under the Stars" scores highest (~0.99 match)!
