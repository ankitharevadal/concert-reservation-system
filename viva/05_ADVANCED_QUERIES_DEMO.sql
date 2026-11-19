-- ============================================================================
-- VIVA DEMONSTRATION FILE 05: ADVANCED SQL QUERIES (RUBRIC REQUIREMENT: 4 MARKS)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: Show Join (with outer join), Nested query (HAVING),
--                        Correlated subquery, and Recursive CTE.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- QUERY 1: MULTI-TABLE JOIN (INNER + LEFT OUTER JOIN ACROSS 7 TABLES)
-- Concept: Joins bookings, users, concert events, artists, venues, tickets,
--          and seats, with a LEFT OUTER JOIN on event feedback to generate
--          a comprehensive concert admission summary.
-- ----------------------------------------------------------------------------
SELECT 
    b.booking_reference,
    u.full_name AS attendee_name,
    u.email AS attendee_email,
    ce.event_title,
    a.stage_name AS artist,
    v.venue_name,
    v.city,
    s.section_name,
    s.seat_row || s.seat_number AS seat_code,
    ti.allocated_price,
    ti.status AS ticket_status,
    ti.barcode_hash,
    b.payment_method,
    COALESCE(ef.review_doc->>'rating', 'No review yet') AS fan_rating
FROM bookings b
JOIN user_profiles u ON b.user_id = u.user_id
JOIN concert_events ce ON b.event_id = ce.event_id
JOIN artists a ON ce.artist_id = a.artist_id
JOIN venues v ON ce.venue_id = v.venue_id
JOIN ticket_instances ti ON b.booking_id = ti.booking_id
JOIN seats s ON ti.seat_id = s.seat_id
LEFT OUTER JOIN event_feedback_nosql ef 
    ON ef.event_id = ce.event_id AND ef.user_id = u.user_id
ORDER BY b.booking_id DESC
LIMIT 5;


-- ----------------------------------------------------------------------------
-- QUERY 2: NESTED SUBQUERY WITH AGGREGATION & HAVING CLAUSE
-- Concept: Identifies high-value "VIP Customers" whose cumulative ticket spending
--          strictly exceeds the platform-wide average booking value.
-- ----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    COUNT(b.booking_id) AS total_orders,
    SUM(b.total_amount) AS total_amount_spent,
    ROUND(AVG(b.total_amount), 2) AS avg_per_order
FROM user_profiles u
JOIN bookings b ON u.user_id = b.user_id
WHERE b.booking_status = 'CONFIRMED'
GROUP BY u.user_id, u.full_name, u.email
HAVING SUM(b.total_amount) > (
    -- Nested Subquery calculating platform average booking value:
    SELECT AVG(total_amount) 
    FROM bookings 
    WHERE booking_status = 'CONFIRMED'
)
ORDER BY total_amount_spent DESC;


-- ----------------------------------------------------------------------------
-- QUERY 3: CORRELATED SUBQUERY
-- Concept: The inner subquery references the outer query's column `c1.venue_id`.
--          Finds all concerts whose base ticket price is strictly higher than
--          the average ticket price of other events hosted at THAT SAME VENUE.
-- ----------------------------------------------------------------------------
SELECT 
    c1.event_id,
    c1.event_title,
    v.venue_name,
    c1.base_ticket_price,
    (
        SELECT ROUND(AVG(c2.base_ticket_price), 2)
        FROM concert_events c2
        WHERE c2.venue_id = c1.venue_id
    ) AS venue_average_price,
    ROUND(c1.base_ticket_price - (
        SELECT AVG(c2.base_ticket_price)
        FROM concert_events c2
        WHERE c2.venue_id = c1.venue_id
    ), 2) AS price_premium_above_venue_avg
FROM concert_events c1
JOIN venues v ON c1.venue_id = v.venue_id
WHERE c1.base_ticket_price >= (
    -- Correlated Subquery referencing c1.venue_id:
    SELECT AVG(c2.base_ticket_price)
    FROM concert_events c2
    WHERE c2.venue_id = c1.venue_id
)
ORDER BY price_premium_above_venue_avg DESC;


-- ----------------------------------------------------------------------------
-- QUERY 4: RECURSIVE COMMON TABLE EXPRESSION (WITH RECURSIVE)
-- Concept: Dynamically generates the hierarchical 4-level arena seat pricing
--          ladder (BRONZE -> SILVER -> GOLD -> VIP) starting from base level 1,
--          recursively computing progressive price escalation per tier.
-- ----------------------------------------------------------------------------
WITH RECURSIVE seat_tier_hierarchy AS (
    -- Anchor member: Level 1 (Base Balcony seating)
    SELECT 
        1 AS tier_level,
        'BRONZE_BALCONY'::VARCHAR AS tier_name,
        1.00::NUMERIC AS multiplier,
        2500.00::NUMERIC AS calculated_tier_price,
        'Entry Level Grandstand View'::VARCHAR AS tier_perks

    UNION ALL

    -- Recursive member: Escalates through Silver, Gold, to VIP Lounge
    SELECT 
        sth.tier_level + 1,
        CASE 
            WHEN sth.tier_level + 1 = 2 THEN 'SILVER_MIDDLE'::VARCHAR
            WHEN sth.tier_level + 1 = 3 THEN 'GOLD_FRONT'::VARCHAR
            WHEN sth.tier_level + 1 = 4 THEN 'VIP_LOUNGE'::VARCHAR
            ELSE 'UNKNOWN'::VARCHAR
        END,
        CASE 
            WHEN sth.tier_level + 1 = 2 THEN 1.25::NUMERIC
            WHEN sth.tier_level + 1 = 3 THEN 1.60::NUMERIC
            WHEN sth.tier_level + 1 = 4 THEN 2.50::NUMERIC
            ELSE sth.multiplier
        END,
        ROUND(2500.00 * CASE 
            WHEN sth.tier_level + 1 = 2 THEN 1.25::NUMERIC
            WHEN sth.tier_level + 1 = 3 THEN 1.60::NUMERIC
            WHEN sth.tier_level + 1 = 4 THEN 2.50::NUMERIC
            ELSE sth.multiplier
        END, 2),
        CASE 
            WHEN sth.tier_level + 1 = 2 THEN 'Elevated Sightline + Fast-Track Lane'::VARCHAR
            WHEN sth.tier_level + 1 = 3 THEN 'Center Proximity + Complimentary Beverage'::VARCHAR
            WHEN sth.tier_level + 1 = 4 THEN 'Front Row Stage Pit + Backstage Pass + Hospitality Lounge'::VARCHAR
            ELSE 'General'::VARCHAR
        END
    FROM seat_tier_hierarchy sth
    WHERE sth.tier_level < 4
)
SELECT 
    tier_level,
    tier_name,
    multiplier || 'x' AS price_multiplier,
    '₹' || calculated_tier_price AS price_for_2500_base_show,
    tier_perks
FROM seat_tier_hierarchy
ORDER BY tier_level ASC;

