-- ============================================================================
-- VIVA DEMONSTRATION FILE 08: ROLE-BASED ACCESS CONTROL (RBAC) & ROW-LEVEL SECURITY
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: Show database roles, grants, and security isolation.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DATABASE ROLE CREATION
-- ----------------------------------------------------------------------------
-- Role A: Event Organizer & Admin
-- Full operational permissions over concert catalog, venues, and pricing.
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'organizer_admin_role') THEN
        CREATE ROLE organizer_admin_role WITH LOGIN PASSWORD 'Admin@Pass2026';
    END IF;
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'attendee_customer_role') THEN
        CREATE ROLE attendee_customer_role WITH LOGIN PASSWORD 'Customer@Pass2026';
    END IF;
END $$;


-- ----------------------------------------------------------------------------
-- 2. PRIVILEGE DELEGATION (GRANT STATEMENTS)
-- ----------------------------------------------------------------------------
-- A. Organizer Permissions:
GRANT SELECT, INSERT, UPDATE, DELETE ON concert_events TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE ON venues TO organizer_admin_role;
GRANT SELECT, INSERT, UPDATE ON seats TO organizer_admin_role;
GRANT SELECT ON bookings TO organizer_admin_role;
GRANT SELECT ON ticket_instances TO organizer_admin_role;
GRANT SELECT ON seat_audit_logs TO organizer_admin_role;

-- B. Attendee Permissions:
-- Customers can browse concerts and seats, but cannot alter event definitions.
GRANT SELECT ON concert_events TO attendee_customer_role;
GRANT SELECT ON venues TO attendee_customer_role;
GRANT SELECT ON seats TO attendee_customer_role;
GRANT SELECT, INSERT ON bookings TO attendee_customer_role;
GRANT SELECT, INSERT ON ticket_instances TO attendee_customer_role;
-- Attendees are explicitly DENIED access to internal trigger audit logs:
REVOKE ALL ON seat_audit_logs FROM attendee_customer_role;


-- ----------------------------------------------------------------------------
-- 3. ROW-LEVEL SECURITY (RLS) POLICIES
-- Purpose: Ensures that even if an attendee executes "SELECT * FROM bookings;",
--          PostgreSQL filters out all rows except those belonging to that user!
-- ----------------------------------------------------------------------------
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_instances ENABLE ROW LEVEL SECURITY;

-- Drop prior policies if existing
DROP POLICY IF EXISTS customer_view_own_bookings ON bookings;
DROP POLICY IF EXISTS customer_view_own_tickets ON ticket_instances;

-- Policy 1: Customer can only view their own booking headers
CREATE POLICY customer_view_own_bookings ON bookings
FOR SELECT
TO attendee_customer_role
USING (
    user_id = NULLIF(CURRENT_SETTING('app.current_user_id', true), '')::INT
);

-- Policy 2: Customer can only view ticket passes for their own bookings
CREATE POLICY customer_view_own_tickets ON ticket_instances
FOR SELECT
TO attendee_customer_role
USING (
    booking_id IN (
        SELECT booking_id FROM bookings
        WHERE user_id = NULLIF(CURRENT_SETTING('app.current_user_id', true), '')::INT
    )
);

-- Policy 3: Organizer bypasses RLS and can view all bookings
CREATE POLICY organizer_view_all_bookings ON bookings
FOR ALL
TO organizer_admin_role
USING (true);

