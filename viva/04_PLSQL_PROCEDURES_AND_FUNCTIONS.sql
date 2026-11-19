-- ============================================================================
-- VIVA DEMONSTRATION FILE 04: PL/SQL STORED PROCEDURES & STORED FUNCTIONS
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: Explain the logic, show execution, and prove atomic concurrency locks.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PART 1: STORED FUNCTION — fn_calculate_dynamic_pricing
-- Purpose: Dynamically calculates ticket pricing in real time based on venue
--          occupancy rate (demand-based surge pricing) and seat tier multiplier.
-- Location in backend code: src/app/api/pricing/route.ts (Line 24)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_calculate_dynamic_pricing(
    p_event_id INT,
    p_seat_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_base_price NUMERIC(10, 2);
    v_seat_multiplier NUMERIC(3, 2);
    v_total_capacity INT;
    v_booked_seats INT;
    v_occupancy_ratio NUMERIC(5, 2);
    v_surge_multiplier NUMERIC(3, 2) := 1.00;
    v_final_price NUMERIC(10, 2);
BEGIN
    -- 1. Fetch event base price
    SELECT base_ticket_price INTO v_base_price
    FROM concert_events
    WHERE event_id = p_event_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event ID % does not exist.', p_event_id;
    END IF;

    -- 2. Fetch seat tier price multiplier
    SELECT price_multiplier INTO v_seat_multiplier
    FROM seats
    WHERE seat_id = p_seat_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Seat ID % does not exist.', p_seat_id;
    END IF;

    -- 3. Calculate venue occupancy percentage
    SELECT v.total_capacity INTO v_total_capacity
    FROM concert_events ce
    JOIN venues v ON ce.venue_id = v.venue_id
    WHERE ce.event_id = p_event_id;

    SELECT COUNT(*) INTO v_booked_seats
    FROM ticket_instances
    WHERE event_id = p_event_id AND status != 'CANCELLED';

    v_occupancy_ratio := (v_booked_seats::NUMERIC / NULLIF(v_total_capacity, 0)::NUMERIC) * 100.0;

    -- 4. Apply dynamic surge multiplier thresholds
    IF v_occupancy_ratio >= 75.0 THEN
        v_surge_multiplier := 1.30; -- 30% surge for high demand
    ELSIF v_occupancy_ratio >= 50.0 THEN
        v_surge_multiplier := 1.15; -- 15% surge for moderate demand
    ELSE
        v_surge_multiplier := 1.00; -- Standard base rate
    END IF;

    -- 5. Calculate final dynamic price
    v_final_price := ROUND(v_base_price * v_seat_multiplier * v_surge_multiplier, 2);

    RETURN v_final_price;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- HOW TO TEST THE FUNCTION LIVE IN FRONT OF HER:
-- ----------------------------------------------------------------------------
-- Test 1: Calculate dynamic price for VIP Lounge seat (Seat #1, Multiplier 2.50x)
SELECT 
    c.event_title,
    s.section_name,
    s.seat_row || s.seat_number AS seat_code,
    c.base_ticket_price,
    s.price_multiplier,
    fn_calculate_dynamic_pricing(c.event_id, s.seat_id) AS dynamic_calculated_price
FROM concert_events c
CROSS JOIN seats s
WHERE c.event_id = 1 AND s.seat_id = 1;

-- Test 2: Calculate dynamic price for Bronze Balcony seat (Seat #100, Multiplier 1.00x)
SELECT 
    c.event_title,
    s.section_name,
    s.seat_row || s.seat_number AS seat_code,
    c.base_ticket_price,
    s.price_multiplier,
    fn_calculate_dynamic_pricing(c.event_id, s.seat_id) AS dynamic_calculated_price
FROM concert_events c
CROSS JOIN seats s
WHERE c.event_id = 1 AND s.seat_id = 100;


-- ----------------------------------------------------------------------------
-- PART 2: STORED PROCEDURE — sp_book_tickets_atomic
-- Purpose: Atomically locks seat rows (FOR UPDATE), checks double-booking collisions,
--          calls dynamic pricing, generates booking header, and creates ticket instances.
-- Location in backend code: src/app/api/bookings/route.ts (Line 42)
-- ----------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE sp_book_tickets_atomic(
    p_user_id INT,
    p_event_id INT,
    p_seat_ids INT[],
    p_payment_method VARCHAR,
    OUT p_booking_reference VARCHAR,
    OUT p_total_amount NUMERIC
) AS $$
DECLARE
    v_seat_id INT;
    v_allocated_price NUMERIC(10, 2);
    v_sum_amount NUMERIC(10, 2) := 0.00;
    v_booking_id INT;
    v_barcode_hash VARCHAR(64);
    v_already_booked_count INT;
BEGIN
    -- 1. Concurrency Check: Check if any requested seat is already booked for this event
    SELECT COUNT(*) INTO v_already_booked_count
    FROM ticket_instances
    WHERE event_id = p_event_id 
      AND seat_id = ANY(p_seat_ids)
      AND status != 'CANCELLED';

    IF v_already_booked_count > 0 THEN
        RAISE EXCEPTION 'Concurrency Collision: One or more selected seats have already been reserved.';
    END IF;

    -- 2. Row Locking (FOR UPDATE) to prevent race conditions during calculation
    PERFORM seat_id FROM seats WHERE seat_id = ANY(p_seat_ids) FOR UPDATE;

    -- 3. Calculate total booking amount using stored function
    FOREACH v_seat_id IN ARRAY p_seat_ids LOOP
        v_allocated_price := fn_calculate_dynamic_pricing(p_event_id, v_seat_id);
        v_sum_amount := v_sum_amount + v_allocated_price;
    END LOOP;

    -- 4. Generate unique cryptographic-style booking reference
    p_booking_reference := 'BK-' || UPPER(SUBSTRING(MD5(RANDOM()::TEXT || CLOCK_TIMESTAMP()::TEXT), 1, 8));
    p_total_amount := v_sum_amount;

    -- 5. Insert transaction header into bookings table
    INSERT INTO bookings (booking_reference, user_id, event_id, total_amount, booking_status, payment_method)
    VALUES (p_booking_reference, p_user_id, p_event_id, p_total_amount, 'CONFIRMED', p_payment_method)
    RETURNING booking_id INTO v_booking_id;

    -- 6. Insert individual ticket instances with unique barcodes (fires audit trigger)
    FOREACH v_seat_id IN ARRAY p_seat_ids LOOP
        v_allocated_price := fn_calculate_dynamic_pricing(p_event_id, v_seat_id);
        v_barcode_hash := 'BC-' || p_booking_reference || '-' || v_seat_id || '-' || SUBSTRING(MD5(RANDOM()::TEXT), 1, 6);

        INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status)
        VALUES (v_booking_id, p_event_id, v_seat_id, v_allocated_price, v_barcode_hash, 'RESERVED');
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ----------------------------------------------------------------------------
-- HOW TO CALL THE PROCEDURE LIVE IN FRONT OF HER:
-- ----------------------------------------------------------------------------
-- Reserve Seats 15 and 16 for User #3 at Event #1
CALL sp_book_tickets_atomic(
    3,                     -- User: Rohan Verma
    1,                     -- Event: A.R. Rahman Live
    ARRAY[15, 16],         -- Selected seats
    'UPI',                 -- Payment mode
    NULL,                  -- OUT parameter for booking ref
    NULL                   -- OUT parameter for total amount
);

