-- ============================================================================
-- VIVA DEMONSTRATION FILE 01: ALL DDL COMMANDS, SCHEMAS & CONSTRAINTS
-- Project: Concert and Live Event Management & Intelligent Arena Reservation System
-- Course: Database Management System Mini-Project (Aug - Dec 2026)
-- Evaluator Requirement: Show all CREATE TABLE, CHECK, UNIQUE, FK, PK, Indexes & Views
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ARCHITECTURAL OVERVIEW FOR EVALUATOR:
-- The relational schema consists of 11 tables designed strictly in 3NF and BCNF:
-- 1. user_profiles             (Strong Entity: System users & RBAC roles)
-- 2. venues                    (Strong Entity: Arenas & Stadiums across India)
-- 3. artists                   (Strong Entity: Headline performers & billing)
-- 4. artist_genres             (Normalized Multi-Valued Attribute)
-- 5. concert_events            (Strong Entity: Scheduled tour dates)
-- 6. seats                     (Weak Entity: Identified by parent venue)
-- 7. bookings                  (Strong Entity: Transaction checkout header)
-- 8. ticket_instances          (Weak Associative Entity: Double-booking lock)
-- 9. seat_audit_logs           (Audit Trail Table: Trigger destination)
-- 10. event_feedback_nosql     (NoSQL Document Store: JSONB fan reviews)
-- 11. concert_vector_embeddings(Vector Store: 5D audio feature embeddings)
-- ----------------------------------------------------------------------------

-- Clean up existing tables respecting reverse dependency order:
DROP TABLE IF EXISTS seat_audit_logs CASCADE;
DROP TABLE IF EXISTS ticket_instances CASCADE;
DROP TABLE IF EXISTS bookings CASCADE;
DROP TABLE IF EXISTS seats CASCADE;
DROP TABLE IF EXISTS concert_events CASCADE;
DROP TABLE IF EXISTS artist_genres CASCADE;
DROP TABLE IF EXISTS artists CASCADE;
DROP TABLE IF EXISTS venues CASCADE;
DROP TABLE IF EXISTS user_profiles CASCADE;
DROP TABLE IF EXISTS event_feedback_nosql CASCADE;
DROP TABLE IF EXISTS concert_vector_embeddings CASCADE;

-- ============================================================================
-- 1. STRONG ENTITY: user_profiles
-- Represents system users (Customers, Event Organizers, System Administrators)
-- ============================================================================
CREATE TABLE user_profiles (
    user_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15),
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER' 
        CONSTRAINT chk_user_role CHECK (role IN ('ADMIN', 'ORGANIZER', 'CUSTOMER')),
    date_of_birth DATE NOT NULL 
        CONSTRAINT chk_user_dob CHECK (date_of_birth <= CURRENT_DATE),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Point out to teacher:
-- 1. PRIMARY KEY: user_id (surrogate key)
-- 2. UNIQUE: email (candidate key, prevents duplicate accounts)
-- 3. CHECK (role IN (...)): Enforces domain integrity for Role-Based Access Control
-- 4. CHECK (date_of_birth <= CURRENT_DATE): Prevents future birth dates
-- 5. DERIVED ATTRIBUTE: 'age' is computed on-the-fly as:
--    EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth))


-- ============================================================================
-- 2. STRONG ENTITY: venues
-- Represents physical stadiums, open arenas, and auditoriums across Indian cities
-- ============================================================================
CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(150) NOT NULL,
    -- Composite attribute 'Address' decomposed into atomic components:
    street_address VARCHAR(200) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    postal_code VARCHAR(15) NOT NULL,
    total_capacity INT NOT NULL 
        CONSTRAINT chk_venue_capacity CHECK (total_capacity > 0),
    contact_email VARCHAR(120) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Point out to teacher:
-- 1. COMPOSITE ATTRIBUTE: Address is decomposed into street, city, state, postal_code.
-- 2. CHECK (total_capacity > 0): Ensures arena capacity is strictly positive.


-- ============================================================================
-- 3. STRONG ENTITY: artists
-- Represents headline performers, touring bands, DJs, and live acts
-- ============================================================================
CREATE TABLE artists (
    artist_id SERIAL PRIMARY KEY,
    stage_name VARCHAR(120) NOT NULL UNIQUE,
    bio TEXT,
    country_of_origin VARCHAR(60) DEFAULT 'India',
    billing_rate_per_hour NUMERIC(10, 2) NOT NULL 
        CONSTRAINT chk_artist_rate CHECK (billing_rate_per_hour >= 0.00),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Point out to teacher:
-- 1. UNIQUE: stage_name prevents duplicate performer entries.
-- 2. CHECK (billing_rate_per_hour >= 0.00): Prevents negative artist rates.


-- ============================================================================
-- 4. MULTI-VALUED ATTRIBUTE NORMALIZATION: artist_genres
-- Normalizes the multi-valued attribute 'genres' of the artist entity (1NF requirement)
-- ============================================================================
CREATE TABLE artist_genres (
    artist_id INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    PRIMARY KEY (artist_id, genre),
    CONSTRAINT fk_artist_genre FOREIGN KEY (artist_id) 
        REFERENCES artists(artist_id) ON DELETE CASCADE
);

-- Point out to teacher:
-- 1. COMPOSITE PRIMARY KEY: (artist_id, genre)
-- 2. ON DELETE CASCADE: If an artist is removed, their associated genre records
--    cascade automatically.


-- ============================================================================
-- 5. STRONG ENTITY: concert_events
-- Represents scheduled live concert tour dates in specific arenas
-- ============================================================================
CREATE TABLE concert_events (
    event_id SERIAL PRIMARY KEY,
    event_title VARCHAR(200) NOT NULL,
    event_description TEXT,
    artist_id INT NOT NULL,
    venue_id INT NOT NULL,
    event_date_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INT NOT NULL 
        CONSTRAINT chk_event_duration CHECK (duration_minutes >= 30 AND duration_minutes <= 600),
    base_ticket_price NUMERIC(10, 2) NOT NULL 
        CONSTRAINT chk_base_price CHECK (base_ticket_price > 0),
    event_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED' 
        CONSTRAINT chk_event_status CHECK (event_status IN ('SCHEDULED', 'ONGOING', 'COMPLETED', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_event_artist FOREIGN KEY (artist_id) 
        REFERENCES artists(artist_id) ON DELETE RESTRICT,
    CONSTRAINT fk_event_venue FOREIGN KEY (venue_id) 
        REFERENCES venues(venue_id) ON DELETE RESTRICT
);

-- Point out to teacher:
-- 1. ON DELETE RESTRICT: Prevents accidental deletion of an artist or venue if
--    tickets have already been scheduled! (Critical business integrity rule).
-- 2. CHECK (duration_minutes BETWEEN 30 AND 600): Ensures concerts are between 30 mins and 10 hours.
-- 3. CHECK (base_ticket_price > 0): Guarantees valid ticket pricing.


-- ============================================================================
-- 6. WEAK ENTITY: seats
-- Identifying Owner: venues (A seat cannot exist without its host stadium)
-- Partial Key: (section_name, seat_row, seat_number)
-- Composite Unique: (venue_id, section_name, seat_row, seat_number)
-- ============================================================================
CREATE TABLE seats (
    seat_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    section_name VARCHAR(50) NOT NULL 
        CONSTRAINT chk_seat_section CHECK (section_name IN ('VIP_LOUNGE', 'GOLD_FRONT', 'SILVER_MIDDLE', 'BRONZE_BALCONY')),
    seat_row VARCHAR(5) NOT NULL,
    seat_number INT NOT NULL 
        CONSTRAINT chk_seat_num CHECK (seat_number > 0),
    price_multiplier NUMERIC(3, 2) NOT NULL DEFAULT 1.00 
        CONSTRAINT chk_price_multiplier CHECK (price_multiplier >= 1.00 AND price_multiplier <= 5.00),
    CONSTRAINT unq_venue_seat UNIQUE (venue_id, section_name, seat_row, seat_number),
    CONSTRAINT fk_seat_venue FOREIGN KEY (venue_id) 
        REFERENCES venues(venue_id) ON DELETE CASCADE
);

-- Point out to teacher:
-- 1. IDENTIFYING RELATIONSHIP: Seat belongs to venue. If venue is destroyed, seats CASCADE.
-- 2. UNIQUE (venue_id, section_name, seat_row, seat_number): Prevents duplicate seat labels in an arena.
-- 3. CHECK (price_multiplier BETWEEN 1.00 AND 5.00): Enforces dynamic pricing bounds.


-- ============================================================================
-- 7. STRONG ENTITY: bookings
-- Represents the atomic financial order placed by an attendee
-- ============================================================================
CREATE TABLE bookings (
    booking_id SERIAL PRIMARY KEY,
    booking_reference VARCHAR(32) NOT NULL UNIQUE,
    user_id INT NOT NULL,
    event_id INT NOT NULL,
    booking_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) NOT NULL 
        CONSTRAINT chk_booking_total CHECK (total_amount >= 0.00),
    booking_status VARCHAR(20) NOT NULL DEFAULT 'CONFIRMED' 
        CONSTRAINT chk_booking_status CHECK (booking_status IN ('PENDING', 'CONFIRMED', 'CANCELLED', 'REFUNDED')),
    payment_method VARCHAR(30) NOT NULL DEFAULT 'UPI' 
        CONSTRAINT chk_payment_method CHECK (payment_method IN ('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING')),
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) 
        REFERENCES user_profiles(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_booking_event FOREIGN KEY (event_id) 
        REFERENCES concert_events(event_id) ON DELETE RESTRICT
);

-- Point out to teacher:
-- 1. UNIQUE: booking_reference is a human-readable booking code (e.g. 'BK-BLR-1001').
-- 2. ON DELETE RESTRICT on event_id: You cannot delete a concert if users have active bookings.


-- ============================================================================
-- 8. WEAK / ASSOCIATIVE ENTITY: ticket_instances
-- Represents individual allocated concert seats inside a booking
-- Prevents double-booking race conditions via UNIQUE(event_id, seat_id)
-- ============================================================================
CREATE TABLE ticket_instances (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    event_id INT NOT NULL,
    seat_id INT NOT NULL,
    allocated_price NUMERIC(10, 2) NOT NULL 
        CONSTRAINT chk_ticket_price CHECK (allocated_price > 0),
    barcode_hash VARCHAR(64) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'RESERVED' 
        CONSTRAINT chk_ticket_status CHECK (status IN ('RESERVED', 'CHECKED_IN', 'CANCELLED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unq_event_seat_booking UNIQUE (event_id, seat_id),
    CONSTRAINT fk_ticket_booking FOREIGN KEY (booking_id) 
        REFERENCES bookings(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_event FOREIGN KEY (event_id) 
        REFERENCES concert_events(event_id) ON DELETE RESTRICT,
    CONSTRAINT fk_ticket_seat FOREIGN KEY (seat_id) 
        REFERENCES seats(seat_id) ON DELETE RESTRICT
);

-- Point out to teacher:
-- 1. CRITICAL CONCURRENCY CONSTRAINT:
--    CONSTRAINT unq_event_seat_booking UNIQUE (event_id, seat_id)
--    This constraint mathematically guarantees that two people CANNOT hold the same seat
--    at the same concert simultaneously, even under massive multi-threaded race conditions!
-- 2. UNIQUE: barcode_hash guarantees each entry ticket has a unique digital pass code.


-- ============================================================================
-- 9. AUDIT TRAIL TABLE: seat_audit_logs
-- Directly populated by our Database TRIGGER to capture BEFORE vs AFTER diffs!
-- ============================================================================
CREATE TABLE seat_audit_logs (
    log_id SERIAL PRIMARY KEY,
    ticket_id INT,
    event_id INT NOT NULL,
    seat_id INT NOT NULL,
    action_type VARCHAR(20) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    old_price NUMERIC(10, 2),
    new_price NUMERIC(10, 2),
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    change_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Point out to teacher:
-- Automatically populated by trigger 'trg_audit_seat_status_change' whenever
-- an attendee scans their barcode pass at the arena turnstile!


-- ============================================================================
-- 10. NoSQL DOCUMENT STORE: event_feedback_nosql
-- Stores unstructured attendee fan reviews and multi-tag vibes using PostgreSQL JSONB
-- ============================================================================
CREATE TABLE event_feedback_nosql (
    feedback_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    review_doc JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_feedback_event FOREIGN KEY (event_id) 
        REFERENCES concert_events(event_id) ON DELETE CASCADE,
    CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) 
        REFERENCES user_profiles(user_id) ON DELETE CASCADE
);


-- ============================================================================
-- 11. VECTOR EMBEDDING STORE: concert_vector_embeddings
-- Stores 5D audio feature embeddings [Energy, Acoustic, Dance, Valence, Scale]
-- ============================================================================
CREATE TABLE concert_vector_embeddings (
    embedding_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    event_title VARCHAR(200) NOT NULL,
    vibe_category VARCHAR(50) NOT NULL,
    feature_vector FLOAT8[] NOT NULL,
    tags VARCHAR(100) NOT NULL,
    CONSTRAINT fk_vector_event FOREIGN KEY (event_id) 
        REFERENCES concert_events(event_id) ON DELETE CASCADE
);


-- ============================================================================
-- 12. DDL INDEXES (High-Performance Query Optimization)
-- ============================================================================
-- B-Tree indexes for fast foreign key navigation:
CREATE INDEX IF NOT EXISTS idx_concert_venue ON concert_events(venue_id);
CREATE INDEX IF NOT EXISTS idx_concert_artist ON concert_events(artist_id);
CREATE INDEX IF NOT EXISTS idx_booking_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_event_seat ON ticket_instances(event_id, seat_id);
CREATE INDEX IF NOT EXISTS idx_seat_venue ON seats(venue_id);

-- GIN (Generalized Inverted Index) for NoSQL JSONB tag containment:
CREATE INDEX IF NOT EXISTS idx_gin_review_doc ON event_feedback_nosql USING gin (review_doc);
CREATE INDEX IF NOT EXISTS idx_gin_review_tags ON event_feedback_nosql USING gin ((review_doc->'vibe_tags'));


-- ============================================================================
-- 13. DDL DATABASE VIEWS (Security & Abstraction)
-- ============================================================================
-- View 1: Real-Time Event Seating & Occupancy Summary
CREATE OR REPLACE VIEW v_event_occupancy_summary AS
SELECT 
    ce.event_id,
    ce.event_title,
    v.venue_name,
    v.city,
    v.total_capacity,
    COUNT(ti.ticket_id) AS seats_booked,
    (v.total_capacity - COUNT(ti.ticket_id)) AS available_seats,
    ROUND((COUNT(ti.ticket_id)::NUMERIC / NULLIF(v.total_capacity, 0)::NUMERIC) * 100.0, 2) AS occupancy_percentage
FROM concert_events ce
JOIN venues v ON ce.venue_id = v.venue_id
LEFT JOIN ticket_instances ti ON ce.event_id = ti.event_id AND ti.status != 'CANCELLED'
GROUP BY ce.event_id, ce.event_title, v.venue_name, v.city, v.total_capacity;

-- View 2: Attendee Confirmed Passes Wallet
CREATE OR REPLACE VIEW v_attendee_confirmed_tickets AS
SELECT 
    b.booking_reference,
    u.full_name AS attendee_name,
    u.email AS attendee_email,
    ce.event_title,
    ce.event_date_time,
    v.venue_name,
    v.city,
    s.section_name,
    s.seat_row || s.seat_number AS seat_code,
    ti.allocated_price,
    ti.barcode_hash,
    ti.status AS admission_status
FROM bookings b
JOIN user_profiles u ON b.user_id = u.user_id
JOIN concert_events ce ON b.event_id = ce.event_id
JOIN venues v ON ce.venue_id = v.venue_id
JOIN ticket_instances ti ON b.booking_id = ti.booking_id
JOIN seats s ON ti.seat_id = s.seat_id
WHERE b.booking_status = 'CONFIRMED';

