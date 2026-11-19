-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 06_rbac_roles.sql (Database-Level Role Based Access Control & Security)
-- ============================================================================

-- ============================================================================
-- 1. DEFINE DATABASE ROLES
-- Minimum two roles as mandated by PES rubric:
-- Role 1: 'organizer_admin_role' (Event manager with CRUD privileges)
-- Role 2: 'attendee_customer_role' (End user with browse & self-booking privileges)
-- ============================================================================

-- Clean up existing roles if testing
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'organizer_admin_role') THEN
        DROP ROLE organizer_admin_role;
    END IF;
    IF EXISTS (SELECT FROM pg_roles WHERE rolname = 'attendee_customer_role') THEN
        DROP ROLE attendee_customer_role;
    END IF;
END $$;

CREATE ROLE organizer_admin_role WITH LOGIN PASSWORD 'Admin@Secure2026';
CREATE ROLE attendee_customer_role WITH LOGIN PASSWORD 'Customer@Secure2026';

-- ============================================================================
-- 2. GRANT PRIVILEGES TO ORGANIZER / ADMIN ROLE
-- Full administrative management of venues, events, seats, and audits
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON venues TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON concert_events TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON artists TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON artist_genres TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON seats TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON event_riders_nosql TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE ON bookings TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE ON ticket_instances TO organizer_admin_role;
GRANT SELECT ON seat_audit_logs TO organizer_admin_role;

-- Allow execution of admin stored procedures and functions
GRANT EXECUTE ON FUNCTION fn_calculate_dynamic_pricing(INT, INT) TO organizer_admin_role;
GRANT EXECUTE ON PROCEDURE sp_book_tickets_atomic(INT, INT, INT, VARCHAR, VARCHAR, NUMERIC, VARCHAR) TO organizer_admin_role;

-- ============================================================================
-- 3. GRANT PRIVILEGES TO ATTENDEE / CUSTOMER ROLE
-- Restricted access: Read-only on events and venues, write restricted to bookings
-- ============================================================================
-- Attendees can browse catalog and seat maps
GRANT SELECT ON venues TO attendee_customer_role;
GRANT SELECT ON concert_events TO attendee_customer_role;
GRANT SELECT ON artists TO attendee_customer_role;
GRANT SELECT ON artist_genres TO attendee_customer_role;
GRANT SELECT ON seats TO attendee_customer_role;
GRANT SELECT ON concert_vector_embeddings TO attendee_customer_role;

-- Attendees can insert their own bookings and read them
GRANT SELECT, INSERT ON bookings TO attendee_customer_role;
GRANT SELECT, INSERT ON ticket_instances TO attendee_customer_role;

-- Customers MUST NOT be able to modify or delete concert events or venues
REVOKE INSERT, UPDATE, DELETE ON concert_events FROM attendee_customer_role;
REVOKE INSERT, UPDATE, DELETE ON venues FROM attendee_customer_role;
REVOKE INSERT, UPDATE, DELETE ON artists FROM attendee_customer_role;
REVOKE SELECT ON seat_audit_logs FROM attendee_customer_role;

-- Grant execution of booking procedure and dynamic pricing
GRANT EXECUTE ON FUNCTION fn_calculate_dynamic_pricing(INT, INT) TO attendee_customer_role;
GRANT EXECUTE ON PROCEDURE sp_book_tickets_atomic(INT, INT, INT, VARCHAR, VARCHAR, NUMERIC, VARCHAR) TO attendee_customer_role;

-- ============================================================================
-- 4. ROW LEVEL SECURITY (RLS) POLICY DEMONSTRATION
-- Ensures an attendee can strictly query ONLY their own booking records
-- ============================================================================
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS customer_view_own_bookings ON bookings;
CREATE POLICY customer_view_own_bookings ON bookings
    FOR SELECT
    TO attendee_customer_role
    USING (user_id = CURRENT_SETTING('app.current_user_id', true)::INT);

DROP POLICY IF EXISTS admin_view_all_bookings ON bookings;
CREATE POLICY admin_view_all_bookings ON bookings
    FOR ALL
    TO organizer_admin_role
    USING (true);
