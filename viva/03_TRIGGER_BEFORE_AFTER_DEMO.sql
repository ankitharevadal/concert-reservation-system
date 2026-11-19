-- ============================================================================
-- VIVA DEMONSTRATION FILE 03: DATABASE TRIGGER (BEFORE vs AFTER DIFF)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- Evaluator Requirement: Show the exact difference between BEFORE and AFTER trigger execution.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: TRIGGER ARCHITECTURE EXPLANATION (Tell the evaluator)
-- ----------------------------------------------------------------------------
-- Trigger Name   : trg_audit_seat_status_change
-- Target Table   : ticket_instances
-- Audit Table    : seat_audit_logs
-- Trigger Event  : AFTER INSERT OR UPDATE ON ticket_instances FOR EACH ROW
-- Purpose        : Enforces a strict, tamper-proof security audit log.
--                  Whenever a ticket changes status (e.g. from RESERVED to CHECKED_IN
--                  at the stadium turnstile), the trigger intercepts OLD and NEW record
--                  values and writes an immutable record to seat_audit_logs.

-- ----------------------------------------------------------------------------
-- STEP 2: SHOW THE EXISTING STATE (BEFORE TRIGGER EXECUTION)
-- ----------------------------------------------------------------------------
-- 1. Check current status of Ticket #1
SELECT 
    ticket_id, 
    booking_id, 
    event_id, 
    seat_id, 
    status AS current_ticket_status, 
    allocated_price
FROM ticket_instances 
WHERE ticket_id = 1;

-- 2. Check current audit trail before modification
SELECT 
    log_id, 
    ticket_id, 
    action_type, 
    old_status, 
    new_status, 
    changed_by, 
    change_timestamp 
FROM seat_audit_logs 
ORDER BY log_id DESC 
LIMIT 3;

-- ----------------------------------------------------------------------------
-- STEP 3: EXECUTE THE DML UPDATE (FIRES THE TRIGGER AUTOMATICALLY)
-- ----------------------------------------------------------------------------
-- An attendee enters the arena and gate security scans their pass:
UPDATE ticket_instances 
SET status = 'CHECKED_IN' 
WHERE ticket_id = 1;

-- ----------------------------------------------------------------------------
-- STEP 4: VERIFY THE AFTER DIFF (THE PROOF FOR THE EVALUATOR!)
-- ----------------------------------------------------------------------------
-- 1. Check updated status in target table
SELECT 
    ticket_id, 
    status AS updated_ticket_status 
FROM ticket_instances 
WHERE ticket_id = 1;

-- 2. Inspect newly generated audit record in seat_audit_logs:
SELECT 
    log_id, 
    ticket_id, 
    action_type, 
    old_status, 
    new_status, 
    changed_by, 
    change_timestamp 
FROM seat_audit_logs 
ORDER BY log_id DESC 
LIMIT 1;

-- ============================================================================
-- WHAT TO POINT OUT TO THE EVALUATOR:
-- "Notice log_id #... in seat_audit_logs:
--  - old_status was captured as 'RESERVED'
--  - new_status was captured as 'CHECKED_IN'
--  - action_type was recorded as 'UPDATE'
--  - changed_by was logged automatically by PostgreSQL as CURRENT_USER
--  - change_timestamp was recorded with microsecond precision.
--  No manual INSERT was executed by the application; the trigger handled it
--  entirely at the database engine level!"
-- ============================================================================

