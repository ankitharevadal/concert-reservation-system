-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 01_ddl.sql (Data Definition Language with Complete Constraints, Indexes & Views)
-- ============================================================================

-- Clean up existing tables respecting reverse dependency order:
DROP VIEW IF EXISTS v_event_occupancy_summary CASCADE;
DROP VIEW IF EXISTS v_attendee_confirmed_tickets CASCADE;
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

-- 1. STRONG ENTITY: user_profiles
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

-- 2. STRONG ENTITY: venues (Stadiums and Arenas across Indian Cities)
CREATE TABLE venues (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(150) NOT NULL,
    street_address VARCHAR(200) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    postal_code VARCHAR(15) NOT NULL,
    total_capacity INT NOT NULL 
        CONSTRAINT chk_venue_capacity CHECK (total_capacity > 0),
    contact_email VARCHAR(120) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. STRONG ENTITY: artists
CREATE TABLE artists (
    artist_id SERIAL PRIMARY KEY,
    stage_name VARCHAR(120) NOT NULL UNIQUE,
    bio TEXT,
    country_of_origin VARCHAR(60) DEFAULT 'India',
    billing_rate_per_hour NUMERIC(10, 2) NOT NULL 
        CONSTRAINT chk_artist_rate CHECK (billing_rate_per_hour >= 0.00),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. MULTI-VALUED ATTRIBUTE NORMALIZATION: artist_genres
CREATE TABLE artist_genres (
    artist_id INT NOT NULL,
    genre VARCHAR(50) NOT NULL,
    PRIMARY KEY (artist_id, genre),
    CONSTRAINT fk_artist_genre FOREIGN KEY (artist_id) 
        REFERENCES artists(artist_id) ON DELETE CASCADE
);

-- 5. STRONG ENTITY: concert_events
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

-- 6. WEAK ENTITY: seats (Identified by host venue)
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

-- 7. STRONG ENTITY: bookings
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

-- 8. WEAK / ASSOCIATIVE ENTITY: ticket_instances (Concurrency Lock)
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

-- 9. AUDIT TRAIL TABLE: seat_audit_logs (Trigger Destination)
CREATE TABLE seat_audit_logs (
    log_id SERIAL PRIMARY KEY,
    ticket_id INT,
    event_id INT NOT NULL,
    seat_id INT NOT NULL,
    action_type VARCHAR(20) NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    old_price NUMERIC(10, 2),
    new_price NUMERIC(10, 2),
    changed_by VARCHAR(100) DEFAULT CURRENT_USER,
    change_timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 10. NoSQL DOCUMENT STORE: event_feedback_nosql (JSONB)
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

-- 11. VECTOR EMBEDDING STORE: concert_vector_embeddings
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

-- 12. INDEXES
CREATE INDEX IF NOT EXISTS idx_concert_venue ON concert_events(venue_id);
CREATE INDEX IF NOT EXISTS idx_concert_artist ON concert_events(artist_id);
CREATE INDEX IF NOT EXISTS idx_booking_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_ticket_event_seat ON ticket_instances(event_id, seat_id);
CREATE INDEX IF NOT EXISTS idx_seat_venue ON seats(venue_id);
CREATE INDEX IF NOT EXISTS idx_gin_review_doc ON event_feedback_nosql USING gin (review_doc);
CREATE INDEX IF NOT EXISTS idx_gin_review_tags ON event_feedback_nosql USING gin ((review_doc->'vibe_tags'));

-- 13. VIEWS
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
