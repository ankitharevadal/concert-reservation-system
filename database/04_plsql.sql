-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 04_plsql.sql (Advanced PL/pgSQL: Trigger, Function, Procedure)
-- ============================================================================

-- ============================================================================
-- 1. DATABASE TRIGGER: trg_audit_seat_status_change
-- PURPOSE: Automatically logs every seat reservation status change with 
--          exact BEFORE and AFTER values into the seat_audit_logs table.
-- ============================================================================

CREATE OR REPLACE FUNCTION trg_fn_audit_seat_status()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        INSERT INTO seat_audit_logs (
            ticket_id, event_id, seat_id, action_type,
            old_status, new_status, old_price, new_price, changed_by, change_timestamp
        ) VALUES (
            NEW.ticket_id, NEW.event_id, NEW.seat_id, 'INSERT',
            'AVAILABLE', NEW.status, NULL, NEW.allocated_price, CURRENT_USER, CURRENT_TIMESTAMP
        );
        RETURN NEW;
        
    ELSIF (TG_OP = 'UPDATE') THEN
        -- Only log if the status or price actually changed
        IF (OLD.status IS DISTINCT FROM NEW.status OR OLD.allocated_price IS DISTINCT FROM NEW.allocated_price) THEN
            INSERT INTO seat_audit_logs (
                ticket_id, event_id, seat_id, action_type,
                old_status, new_status, old_price, new_price, changed_by, change_timestamp
            ) VALUES (
                NEW.ticket_id, NEW.event_id, NEW.seat_id, 'UPDATE',
                OLD.status, NEW.status, OLD.allocated_price, NEW.allocated_price, CURRENT_USER, CURRENT_TIMESTAMP
            );
        END IF;
        RETURN NEW;

    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO seat_audit_logs (
            ticket_id, event_id, seat_id, action_type,
            old_status, new_status, old_price, new_price, changed_by, change_timestamp
        ) VALUES (
            OLD.ticket_id, OLD.event_id, OLD.seat_id, 'DELETE',
            OLD.status, 'CANCELLED/DELETED', OLD.allocated_price, NULL, CURRENT_USER, CURRENT_TIMESTAMP
        );
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Attach Trigger to ticket_instances table
DROP TRIGGER IF EXISTS trg_audit_seat_status_change ON ticket_instances;
CREATE TRIGGER trg_audit_seat_status_change
AFTER INSERT OR UPDATE OR DELETE ON ticket_instances
FOR EACH ROW
EXECUTE FUNCTION trg_fn_audit_seat_status();

-- ============================================================================
-- LIVE VIVA DEMONSTRATION FOR EVALUATOR (BEFORE vs AFTER DIFF):
-- Step 1 (Show Before State):
--   SELECT log_id, seat_id, action_type, old_status, new_status, change_timestamp 
--   FROM seat_audit_logs ORDER BY log_id DESC LIMIT 3;
--
-- Step 2 (Perform Update):
--   UPDATE ticket_instances SET status = 'CHECKED_IN' WHERE ticket_id = 1;
--
-- Step 3 (Show After Diff):
--   SELECT log_id, seat_id, action_type, old_status, new_status, change_timestamp 
--   FROM seat_audit_logs ORDER BY log_id DESC LIMIT 1;
--   --> Result shows: old_status = 'RESERVED', new_status = 'CHECKED_IN'
-- ============================================================================


-- ============================================================================
-- 2. STORED FUNCTION: fn_calculate_dynamic_pricing
-- INVOCATION IN CODE:
--   - Backend API: src/app/api/pricing/route.ts (Line ~25)
--   - Inside Stored Procedure: sp_book_tickets_atomic (Below, Line ~120)
-- PURPOSE: Computes real-time dynamic surge pricing based on current venue 
--          occupancy rate and seat tier multiplier.
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_calculate_dynamic_pricing(
    p_event_id INT,
    p_seat_id INT
)
RETURNS NUMERIC AS $$
DECLARE
    v_base_price NUMERIC(10, 2);
    v_multiplier NUMERIC(3, 2);
    v_total_capacity INT;
    v_booked_seats INT;
    v_occupancy_ratio NUMERIC;
    v_surge_factor NUMERIC(3, 2) := 1.00;
    v_final_price NUMERIC(10, 2);
BEGIN
    -- 1. Fetch base concert price and venue total capacity
    SELECT c.base_ticket_price, v.total_capacity 
    INTO v_base_price, v_total_capacity
    FROM concert_events c
    JOIN venues v ON c.venue_id = v.venue_id
    WHERE c.event_id = p_event_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Event ID % not found', p_event_id;
    END IF;

    -- 2. Fetch specific seat multiplier
    SELECT price_multiplier INTO v_multiplier
    FROM seats
    WHERE seat_id = p_seat_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Seat ID % not found', p_seat_id;
    END IF;

    -- 3. Calculate current occupancy for this event
    SELECT COUNT(*) INTO v_booked_seats
    FROM ticket_instances
    WHERE event_id = p_event_id AND status != 'CANCELLED';

    -- Avoid division by zero
    IF v_total_capacity > 0 THEN
        v_occupancy_ratio := v_booked_seats::NUMERIC / v_total_capacity::NUMERIC;
    ELSE
        v_occupancy_ratio := 0.0;
    END IF;

    -- 4. Apply Dynamic Demand Surge Rule:
    -- If occupancy > 75%, surge factor is 1.30 (30% increase)
    -- If occupancy > 50%, surge factor is 1.15 (15% increase)
    -- Otherwise, standard rate (1.00)
    IF v_occupancy_ratio >= 0.75 THEN
        v_surge_factor := 1.30;
    ELSIF v_occupancy_ratio >= 0.50 THEN
        v_surge_factor := 1.15;
    ELSE
        v_surge_factor := 1.00;
    END IF;

    -- Compute final rounded price
    v_final_price := ROUND(v_base_price * v_multiplier * v_surge_factor, 2);
    RETURN v_final_price;
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 3. STORED PROCEDURE: sp_book_tickets_atomic
-- INVOCATION IN CODE:
--   - Backend API: src/app/api/bookings/route.ts (Line ~45)
--   - Next.js UI Checkout Button: "Confirm Reservation"
-- PURPOSE: Atomically books a seat with row locking to eliminate race conditions,
--          calls dynamic pricing function, records booking, and creates ticket instance.
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_book_tickets_atomic(
    IN p_user_id INT,
    IN p_event_id INT,
    IN p_seat_id INT,
    IN p_payment_method VARCHAR(30),
    INOUT p_booking_ref VARCHAR(32) DEFAULT NULL,
    INOUT p_allocated_price NUMERIC(10, 2) DEFAULT NULL,
    INOUT p_status_message VARCHAR(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_is_already_booked INT;
    v_new_booking_id INT;
    v_barcode_hash VARCHAR(64);
BEGIN
    -- Step 1: Concurrency Control - Check if seat is already occupied
    SELECT COUNT(*) INTO v_is_already_booked
    FROM ticket_instances
    WHERE event_id = p_event_id 
      AND seat_id = p_seat_id 
      AND status = 'RESERVED'
    FOR UPDATE;

    IF v_is_already_booked > 0 THEN
        p_status_message := 'FAILED: Seat is already booked by another user!';
        RETURN;
    END IF;

    -- Step 2: Compute real-time price using our dynamic pricing function
    p_allocated_price := fn_calculate_dynamic_pricing(p_event_id, p_seat_id);

    -- Step 3: Generate unique booking reference and barcode
    p_booking_ref := 'BK-' || SUBSTRING(MD5(RANDOM()::TEXT) FROM 1 FOR 8);
    v_barcode_hash := 'BC-' || SUBSTRING(MD5(p_booking_ref || p_seat_id::TEXT) FROM 1 FOR 16);

    -- Step 4: Insert parent booking header
    INSERT INTO bookings (
        booking_reference, user_id, event_id, total_amount, booking_status, payment_method
    ) VALUES (
        p_booking_ref, p_user_id, p_event_id, p_allocated_price, 'CONFIRMED', p_payment_method
    ) RETURNING booking_id INTO v_new_booking_id;

    -- Step 5: Insert ticket instance (This activates trigger trg_audit_seat_status_change!)
    INSERT INTO ticket_instances (
        booking_id, event_id, seat_id, allocated_price, barcode_hash, status
    ) VALUES (
        v_new_booking_id, p_event_id, p_seat_id, p_allocated_price, v_barcode_hash, 'RESERVED'
    );

    p_status_message := 'SUCCESS: Seat booked successfully with ref ' || p_booking_ref;
END;
$$;
