-- ============================================================================
-- VIVA DEMONSTRATION FILE 06: NoSQL JSONB DOCUMENT STORE QUERIES
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: "For NoSQL, show the queries and explain indexing/manipulation."
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CONCEPT EXPLANATION (Tell the evaluator):
-- Why PostgreSQL JSONB instead of MongoDB?
-- PostgreSQL JSONB provides binary-format NoSQL document storage inside an ACID
-- database. It allows flexible, semi-structured schemas for artist technical riders
-- and fan feedback without requiring a separate database cluster.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- 1. GIN INVERTED INDEX CREATION (For O(1) tag lookup)
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_gin_review_doc 
ON event_feedback_nosql USING gin (review_doc);

CREATE INDEX IF NOT EXISTS idx_gin_review_tags 
ON event_feedback_nosql USING gin ((review_doc->'vibe_tags'));


-- ----------------------------------------------------------------------------
-- 2. NoSQL CONTAINMENT QUERY (@> OPERATOR)
-- Purpose: Searches for reviews that contain specific nested tag arrays.
--          Uses the GIN index for high-speed retrieval.
-- ----------------------------------------------------------------------------
SELECT 
    feedback_id,
    event_id,
    review_doc->>'reviewer' AS reviewer_name,
    (review_doc->>'rating')::INT AS star_rating,
    review_doc->'vibe_tags' AS tags_array,
    review_doc->>'comment' AS fan_comment,
    (review_doc->>'helpful_votes')::INT AS helpful_votes
FROM event_feedback_nosql
WHERE review_doc @> '{"vibe_tags": ["spiritual"]}';


-- ----------------------------------------------------------------------------
-- 3. IN-PLACE DOCUMENT UPDATE (jsonb_set FUNCTION)
-- Purpose: Atomically updates a deeply nested key inside the JSON document
--          WITHOUT rewriting the entire row.
-- Example: Upvoting a review from 42 votes to 50 votes.
-- ----------------------------------------------------------------------------
-- Before update:
SELECT feedback_id, review_doc->>'helpful_votes' AS votes_before 
FROM event_feedback_nosql 
WHERE feedback_id = 1;

-- Execute atomic in-place modification:
UPDATE event_feedback_nosql
SET review_doc = jsonb_set(
    review_doc,
    '{helpful_votes}',
    '50'::jsonb,
    false -- false = do not create if path does not exist
)
WHERE feedback_id = 1;

-- After update:
SELECT feedback_id, review_doc->>'helpful_votes' AS votes_after 
FROM event_feedback_nosql 
WHERE feedback_id = 1;


-- ----------------------------------------------------------------------------
-- 4. HYBRID RELATIONAL + NoSQL AGGREGATION
-- Purpose: Combines relational concert titles with extracted NoSQL star ratings.
-- ----------------------------------------------------------------------------
SELECT 
    ce.event_title,
    COUNT(ef.feedback_id) AS total_fan_reviews,
    ROUND(AVG((ef.review_doc->>'rating')::NUMERIC), 2) AS average_star_rating,
    SUM((ef.review_doc->>'helpful_votes')::INT) AS total_helpful_upvotes
FROM concert_events ce
JOIN event_feedback_nosql ef ON ce.event_id = ef.event_id
GROUP BY ce.event_id, ce.event_title
ORDER BY average_star_rating DESC;

