-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 03_joins_nested_cte.sql (Advanced SQL: Joins, Nested, Correlated, Recursive CTE)
-- ============================================================================

-- ============================================================================
-- 1. COMPLEX MULTI-TABLE JOIN (4-Table Join with Left Outer Join)
-- Retrieves comprehensive booking details: Attendee details, Concert title,
-- Artist name, Venue name, Allocated Seat, and Section.
-- ============================================================================
SELECT 
    b.booking_reference,
    u.full_name AS customer_name,
    u.email AS customer_email,
    c.event_title,
    a.stage_name AS performer,
    v.venue_name,
    s.section_name,
    s.seat_row || s.seat_number AS assigned_seat,
    ti.allocated_price,
    b.booking_status
FROM bookings b
JOIN user_profiles u ON b.user_id = u.user_id
JOIN concert_events c ON b.event_id = c.event_id
JOIN artists a ON c.artist_id = a.artist_id
JOIN venues v ON c.venue_id = v.venue_id
LEFT JOIN ticket_instances ti ON b.booking_id = ti.booking_id
LEFT JOIN seats s ON ti.seat_id = s.seat_id
ORDER BY b.booking_timestamp DESC;

-- ============================================================================
-- 2. NESTED SUBQUERY (Uncorrelated Subquery with Aggregation)
-- Finds all users who have spent more than the average booking amount across
-- all completed concert bookings in the entire system.
-- ============================================================================
SELECT 
    u.user_id,
    u.full_name,
    u.email,
    SUM(b.total_amount) AS total_spent_by_user
FROM user_profiles u
JOIN bookings b ON u.user_id = b.user_id
WHERE b.booking_status = 'CONFIRMED'
GROUP BY u.user_id, u.full_name, u.email
HAVING SUM(b.total_amount) > (
    -- Nested subquery calculating system-wide average booking value
    SELECT AVG(total_amount) 
    FROM bookings 
    WHERE booking_status = 'CONFIRMED'
)
ORDER BY total_spent_by_user DESC;

-- ============================================================================
-- 3. CORRELATED SUBQUERY
-- Finds concert events that are priced strictly higher than the average
-- ticket price of all events hosted in the VERY SAME venue.
-- (Correlated because inner query references outer query's c1.venue_id)
-- ============================================================================
SELECT 
    c1.event_id,
    c1.event_title,
    c1.base_ticket_price,
    v.venue_name,
    (
        -- Scalar subquery showing the venue average for instant comparison
        SELECT ROUND(AVG(c2.base_ticket_price), 2)
        FROM concert_events c2
        WHERE c2.venue_id = c1.venue_id
    ) AS venue_average_price
FROM concert_events c1
JOIN venues v ON c1.venue_id = v.venue_id
WHERE c1.base_ticket_price > (
    -- Correlated subquery condition
    SELECT AVG(c2.base_ticket_price)
    FROM concert_events c2
    WHERE c2.venue_id = c1.venue_id
);

-- ============================================================================
-- 4. RECURSIVE CTE (Common Table Expression)
-- Hierarchical Seat Tier Pricing & Waitlist Escalation Chain
-- Generates an escalation ladder from Bronze -> Silver -> Gold -> VIP
-- showing price progression and seat upgrade priority level.
-- ============================================================================
WITH RECURSIVE seat_tier_hierarchy AS (
    -- Anchor Member: Bronze Balcony (Baseline tier, Level 1)
    SELECT 
        1 AS tier_level,
        'BRONZE_BALCONY'::VARCHAR(50) AS tier_name,
        1.00::NUMERIC(3, 2) AS multiplier,
        'Base admission tier with standard view'::TEXT AS perks
    
    UNION ALL
    
    -- Recursive Member: Advances each tier to the next prestige level
    SELECT 
        sth.tier_level + 1,
        CASE 
            WHEN sth.tier_level = 1 THEN 'SILVER_MIDDLE'::VARCHAR(50)
            WHEN sth.tier_level = 2 THEN 'GOLD_FRONT'::VARCHAR(50)
            WHEN sth.tier_level = 3 THEN 'VIP_LOUNGE'::VARCHAR(50)
        END,
        CASE 
            WHEN sth.tier_level = 1 THEN 1.20::NUMERIC(3, 2)
            WHEN sth.tier_level = 2 THEN 1.60::NUMERIC(3, 2)
            WHEN sth.tier_level = 3 THEN 2.50::NUMERIC(3, 2)
        END,
        CASE 
            WHEN sth.tier_level = 1 THEN 'Upgraded acoustics & central sightline'::TEXT
            WHEN sth.tier_level = 2 THEN 'Near stage proximity with dedicated beverage line'::TEXT
            WHEN sth.tier_level = 3 THEN 'Front row stage access, lounge entry & signed merchandise'::TEXT
        END
    FROM seat_tier_hierarchy sth
    WHERE sth.tier_level < 4
)
SELECT 
    tier_level,
    tier_name,
    multiplier,
    perks,
    ROUND(2500.00 * multiplier, 2) AS effective_price_for_arr_concert
FROM seat_tier_hierarchy
ORDER BY tier_level ASC;
