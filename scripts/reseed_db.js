const { PGlite } = require('@electric-sql/pglite');
const path = require('path');

async function reseed() {
  const dataDir = path.join(process.cwd(), '.pgdata');
  const db = new PGlite(dataDir);

  console.log('⚡ Reseeding complete multi-city concert reservation database into .pgdata...');

  // 1. Drop and Recreate Schema
  await db.exec(`
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
    DROP TABLE IF EXISTS event_riders_nosql CASCADE;
    DROP TABLE IF EXISTS concert_vector_embeddings CASCADE;

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

    CREATE TABLE artists (
        artist_id SERIAL PRIMARY KEY,
        stage_name VARCHAR(120) NOT NULL UNIQUE,
        bio TEXT,
        country_of_origin VARCHAR(60) DEFAULT 'India',
        billing_rate_per_hour NUMERIC(10, 2) NOT NULL 
            CONSTRAINT chk_artist_rate CHECK (billing_rate_per_hour >= 0.00),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE artist_genres (
        artist_id INT NOT NULL,
        genre VARCHAR(50) NOT NULL,
        PRIMARY KEY (artist_id, genre),
        CONSTRAINT fk_artist_genre FOREIGN KEY (artist_id) 
            REFERENCES artists(artist_id) ON DELETE CASCADE
    );

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

    CREATE TABLE seats (
        seat_id SERIAL PRIMARY KEY,
        venue_id INT NOT NULL,
        section_name VARCHAR(50) NOT NULL 
            CONSTRAINT chk_seat_section CHECK (section_name IN ('VIP_LOUNGE', 'GOLD_FRONT', 'SILVER_MIDDLE', 'BRONZE_BALCONY')),
        seat_row VARCHAR(5) NOT NULL,
        seat_number INT NOT NULL CONSTRAINT chk_seat_num CHECK (seat_number > 0),
        price_multiplier NUMERIC(3, 2) NOT NULL DEFAULT 1.00 
            CONSTRAINT chk_price_multiplier CHECK (price_multiplier >= 1.00 AND price_multiplier <= 5.00),
        CONSTRAINT unq_venue_seat UNIQUE (venue_id, section_name, seat_row, seat_number),
        CONSTRAINT fk_seat_venue FOREIGN KEY (venue_id) 
            REFERENCES venues(venue_id) ON DELETE CASCADE
    );

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

    CREATE TABLE event_feedback_nosql (
        feedback_id SERIAL PRIMARY KEY,
        event_id INT NOT NULL,
        user_id INT NOT NULL,
        review_doc JSONB NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE concert_vector_embeddings (
        embedding_id SERIAL PRIMARY KEY,
        event_id INT NOT NULL,
        event_title VARCHAR(200) NOT NULL,
        vibe_category VARCHAR(50) NOT NULL,
        feature_vector FLOAT8[] NOT NULL,
        tags VARCHAR(100) NOT NULL
    );
  `);

  // 2. Insert Users
  await db.exec(`
    INSERT INTO user_profiles (full_name, email, password_hash, phone_number, role, date_of_birth) VALUES
    ('Aarav Sharma (Admin)', 'aarav.admin@pesevents.edu', '$2b$10$hashed_admin', '+919876543210', 'ADMIN', '1995-04-12'),
    ('Priya Nair (Organizer)', 'priya.organizer@liveconcerts.in', '$2b$10$hashed_org', '+919812345678', 'ORGANIZER', '1998-09-23'),
    ('Rohan Verma (Attendee)', 'rohan.verma@gmail.com', '$2b$10$hashed_usr1', '+919765432109', 'CUSTOMER', '2003-01-15'),
    ('Sneha Reddy (Attendee)', 'sneha.reddy@outlook.com', '$2b$10$hashed_usr2', '+919654321098', 'CUSTOMER', '2002-11-30'),
    ('Vikram Malhotra (Attendee)', 'vikram.m@yahoo.com', '$2b$10$hashed_usr3', '+919543210987', 'CUSTOMER', '2001-07-08');

    -- Venues across 6 major Indian cities
    INSERT INTO venues (venue_id, venue_name, street_address, city, state, postal_code, total_capacity, contact_email) VALUES
    (1, 'PES University Open Arena', '100 Feet Ring Road, BSK III Stage', 'Bengaluru', 'Karnataka', '560085', 8500, 'events@pes.edu'),
    (2, 'Palace Grounds Royal Enclosure', 'Bellary Road, Jayamahal', 'Bengaluru', 'Karnataka', '560006', 25000, 'info@palacegrounds.com'),
    (3, 'DY Patil Multi-Purpose Stadium', 'Sector 7, Nerul', 'Mumbai', 'Maharashtra', '400706', 45000, 'operations@dypatilstadium.com'),
    (4, 'Jawaharlal Nehru Stadium Arena', 'Pragati Vihar, Lodhi Road', 'New Delhi', 'Delhi', '110003', 35000, 'contact@jlnstadium.gov.in'),
    (5, 'G. M. C. Balayogi Athletic Stadium', 'Gachibowli Sports Complex', 'Hyderabad', 'Telangana', '500032', 30000, 'events@gmcstadium.telangana.gov.in'),
    (6, 'Jawaharlal Nehru Stadium Marina', 'Sydenhams Road, Periamet', 'Chennai', 'Tamil Nadu', '600003', 40000, 'support@jlnstadiumchennai.com'),
    (7, 'Eden Gardens Arena Enclosure', 'B.B.D. Bagh, Strand Road', 'Kolkata', 'West Bengal', '700021', 50000, 'booking@edengardensarena.in');

    -- Artists
    INSERT INTO artists (artist_id, stage_name, bio, country_of_origin, billing_rate_per_hour) VALUES
    (1, 'A. R. Rahman Live', 'Oscar & Grammy-winning maestro performing symphonic fusion live.', 'India', 250000.00),
    (2, 'Coldplay Experience', 'Global stadium rock icon performing world tour spectacle.', 'United Kingdom', 750000.00),
    (3, 'Diljit Dosanjh', 'Punjabi pop sensation bringing the high-octane Dil-Luminati tour.', 'India', 350000.00),
    (4, 'Prateek Kuhad', 'Intimate indie acoustic folk singer-songwriter.', 'India', 85000.00),
    (5, 'Dua Lipa Electro', 'Global pop sensation with synth-pop dance beats.', 'United Kingdom', 450000.00),
    (6, 'Arijit Singh', 'Soulful Bollywood maestro and acoustic sensation.', 'India', 400000.00),
    (7, 'Anirudh Live Band', 'Rockstar composer delivering energetic EDM-rock stadium anthems.', 'India', 300000.00),
    (8, 'Karan Aujla', 'Desi hip-hop and trap superstar selling out world arenas.', 'India', 280000.00);

    -- Artist Genres
    INSERT INTO artist_genres (artist_id, genre) VALUES
    (1, 'Sufi'), (1, 'World Fusion'), (1, 'Soundtrack'),
    (2, 'Alternative Rock'), (2, 'Pop Rock'),
    (3, 'Punjabi Pop'), (3, 'Bhangra Hip-Hop'),
    (4, 'Indie Folk'), (4, 'Acoustic Pop'),
    (5, 'Synth-Pop'), (5, 'Dance-Pop'),
    (6, 'Bollywood Romantic'), (6, 'Classical Fusion'),
    (7, 'Tamil Rock'), (7, 'EDM Fusion'),
    (8, 'Punjabi Hip-Hop'), (8, 'Trap Rap');

    -- Concert Events Across All Cities
    INSERT INTO concert_events (event_id, event_title, event_description, artist_id, venue_id, event_date_time, duration_minutes, base_ticket_price, event_status) VALUES
    (1, 'A. R. Rahman: Symphony of India', 'Grand live orchestra featuring 50 musicians and iconic classics.', 1, 1, '2026-11-15 19:00:00+05:30', 180, 2500.00, 'SCHEDULED'),
    (2, 'Coldplay: Music of the Spheres Live', 'Eco-friendly stadium show with LED wristbands and laser pyrotechnics.', 2, 3, '2026-12-05 18:30:00+05:30', 210, 4500.00, 'SCHEDULED'),
    (3, 'Diljit Dosanjh: Dil-Luminati India Tour', 'High-energy national stadium tour with massive LED kinetic stages.', 3, 4, '2026-11-28 20:00:00+05:30', 150, 3200.00, 'SCHEDULED'),
    (4, 'Prateek Kuhad: Silhouettes Under the Stars', 'Intimate acoustic evening under open sky.', 4, 1, '2026-11-08 19:30:00+05:30', 120, 1200.00, 'SCHEDULED'),
    (5, 'Dua Lipa: Radical Optimism World Tour', 'Full stadium synth-pop dance party with live lasers and dancers.', 5, 3, '2026-12-14 19:00:00+05:30', 140, 3800.00, 'SCHEDULED'),
    (6, 'Arijit Singh: Soulful Arena Night', '3-hour heartfelt journey through timeless Bollywood symphonies.', 6, 4, '2026-12-20 18:30:00+05:30', 180, 2800.00, 'SCHEDULED'),
    (7, 'Anirudh Live: Hukum Stadium Extravaganza', 'High-voltage Tamil rock, heavy bass drops, and stadium pyro.', 7, 5, '2026-11-22 19:00:00+05:30', 180, 2200.00, 'SCHEDULED'),
    (8, 'A. R. Rahman: Marakkuma Nenjam Grand Tour', 'Symphonic celebration of 3 decades of timeless film music.', 1, 6, '2026-12-26 19:00:00+05:30', 210, 2600.00, 'SCHEDULED'),
    (9, 'Karan Aujla: It Was All A Dream Arena Tour', 'Top-charting Punjabi hip-hop anthems with international stage production.', 8, 7, '2026-12-08 19:30:00+05:30', 150, 2400.00, 'SCHEDULED'),
    (10, 'Sunburn Arena Bengaluru Edition', 'Electronic dance music extravaganza featuring world-class visual rigs.', 5, 2, '2026-11-30 17:00:00+05:30', 300, 1800.00, 'SCHEDULED');
  `);

  // 3. Generate 130 seats for each of the 7 venues (910 total seats)
  await db.exec(`
    DO $$
    DECLARE
        v_id INT;
    BEGIN
        FOR v_id IN 1..7 LOOP
            -- VIP Lounge (Rows A, B - 10 seats each)
            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'VIP_LOUNGE', 'A', n, 2.50 FROM generate_series(1, 10) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'VIP_LOUNGE', 'B', n, 2.20 FROM generate_series(1, 10) n;

            -- Gold Front (Rows C, D, E - 12 seats each)
            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'GOLD_FRONT', 'C', n, 1.60 FROM generate_series(1, 12) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'GOLD_FRONT', 'D', n, 1.50 FROM generate_series(1, 12) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'GOLD_FRONT', 'E', n, 1.50 FROM generate_series(1, 12) n;

            -- Silver Middle (Rows F, G, H - 14 seats each)
            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'SILVER_MIDDLE', 'F', n, 1.25 FROM generate_series(1, 14) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'SILVER_MIDDLE', 'G', n, 1.20 FROM generate_series(1, 14) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'SILVER_MIDDLE', 'H', n, 1.15 FROM generate_series(1, 14) n;

            -- Bronze Balcony (Rows J, K - 16 seats each)
            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'BRONZE_BALCONY', 'J', n, 1.00 FROM generate_series(1, 16) n;

            INSERT INTO seats (venue_id, section_name, seat_row, seat_number, price_multiplier)
            SELECT v_id, 'BRONZE_BALCONY', 'K', n, 1.00 FROM generate_series(1, 16) n;
        END LOOP;
    END $$;
  `);

  // 4. Initial Bookings & Reserved Seats
  await db.exec(`
    INSERT INTO bookings (booking_reference, user_id, event_id, total_amount, booking_status, payment_method) VALUES
    ('BK-BLR-1001', 3, 1, 12500.00, 'CONFIRMED', 'UPI'),
    ('BK-MUM-2001', 4, 2, 19800.00, 'CONFIRMED', 'CREDIT_CARD'),
    ('BK-DEL-3001', 5, 3, 9600.00, 'CONFIRMED', 'NET_BANKING'),
    ('BK-HYD-4001', 3, 7, 6600.00, 'CONFIRMED', 'UPI'),
    ('BK-CHN-5001', 4, 8, 13000.00, 'CONFIRMED', 'CREDIT_CARD');

    -- Seed reserved seats across cities
    INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status) VALUES
    (1, 1, 3, 6250.00, 'BC-BLR-A3-88492049182', 'RESERVED'),
    (1, 1, 4, 6250.00, 'BC-BLR-A4-88492049183', 'RESERVED');

    -- Mumbai Event 2 seats
    INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status)
    SELECT 2, 2, seat_id, 9900.00, 'BC-MUM-' || seat_id || '-5541289', 'RESERVED'
    FROM seats WHERE venue_id = 3 AND seat_row = 'A' AND seat_number IN (1, 2);

    -- Delhi Event 3 seats
    INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status)
    SELECT 3, 3, seat_id, 4800.00, 'BC-DEL-' || seat_id || '-9981241', 'RESERVED'
    FROM seats WHERE venue_id = 4 AND seat_row = 'C' AND seat_number IN (1, 2);

    -- Initial Audit Logs
    INSERT INTO seat_audit_logs (ticket_id, event_id, seat_id, action_type, old_status, new_status, old_price, new_price, changed_by) VALUES
    (1, 1, 3, 'INSERT', 'AVAILABLE', 'RESERVED', NULL, 6250.00, 'sp_book_tickets_atomic'),
    (2, 1, 4, 'INSERT', 'AVAILABLE', 'RESERVED', NULL, 6250.00, 'sp_book_tickets_atomic');

    -- NoSQL Fan Reviews (JSONB)
    INSERT INTO event_feedback_nosql (event_id, user_id, review_doc) VALUES
    (1, 3, '{"reviewer": "Rohan Verma", "rating": 5, "vibe_tags": ["spiritual", "orchestral"], "comment": "50 violinists playing Roja live was sheer perfection!", "helpful_votes": 42}'),
    (2, 4, '{"reviewer": "Sneha Reddy", "rating": 5, "vibe_tags": ["euphoric", "stadium_anthem"], "comment": "The LED wristbands lit up DY Patil Stadium like magic!", "helpful_votes": 68}'),
    (3, 5, '{"reviewer": "Vikram Malhotra", "rating": 5, "vibe_tags": ["energetic", "party"], "comment": "Non-stop bhangra energy for 2.5 hours in Delhi!", "helpful_votes": 35}');

    -- Vector Embeddings for All 10 Events
    INSERT INTO concert_vector_embeddings (event_id, event_title, vibe_category, feature_vector, tags) VALUES
    (1, 'A. R. Rahman: Symphony of India', 'Symphonic Fusion', ARRAY[0.65, 0.88, 0.45, 0.82, 0.90], 'orchestra,sufi,spiritual,peaceful,bengaluru'),
    (2, 'Coldplay: Music of the Spheres Live', 'Stadium Anthem Rock', ARRAY[0.92, 0.35, 0.78, 0.95, 0.98], 'rock,lights,euphoric,colorful,mumbai'),
    (3, 'Diljit Dosanjh: Dil-Luminati India Tour', 'Bhangra Hip-Hop Pop', ARRAY[0.96, 0.12, 0.98, 0.91, 0.92], 'party,bhangra,loud,club,dancing,delhi'),
    (4, 'Prateek Kuhad: Silhouettes Under the Stars', 'Intimate Indie Folk', ARRAY[0.32, 0.94, 0.38, 0.55, 0.25], 'acoustic,cozy,intimate,calm,gentle,bengaluru'),
    (5, 'Dua Lipa: Radical Optimism World Tour', 'Global Synth-Pop', ARRAY[0.89, 0.20, 0.95, 0.92, 0.94], 'dance,pop,synth,disco,mumbai'),
    (6, 'Arijit Singh: Soulful Arena Night', 'Bollywood Romantic Fusion', ARRAY[0.55, 0.82, 0.40, 0.75, 0.88], 'romantic,melodic,soulful,delhi'),
    (7, 'Anirudh Live: Hukum Stadium Extravaganza', 'EDM Tamil Rock', ARRAY[0.95, 0.15, 0.92, 0.88, 0.95], 'rock,edm,bass,energy,hyderabad'),
    (8, 'A. R. Rahman: Marakkuma Nenjam Grand Tour', 'Tamil Symphonic Classics', ARRAY[0.68, 0.85, 0.48, 0.80, 0.92], 'tamil,classics,orchestra,chennai'),
    (9, 'Karan Aujla: It Was All A Dream Arena Tour', 'Desi Trap Hip-Hop', ARRAY[0.94, 0.18, 0.91, 0.85, 0.90], 'trap,rap,punjabi,kolkata'),
    (10, 'Sunburn Arena Bengaluru Edition', 'EDM Festival Stage', ARRAY[0.98, 0.05, 0.99, 0.96, 0.95], 'edm,festival,dj,lights,bengaluru');
  `);

  const eventsCount = await db.query('SELECT COUNT(*) FROM concert_events;');
  const seatsCount = await db.query('SELECT COUNT(*) FROM seats;');
  const venuesCount = await db.query('SELECT COUNT(*) FROM venues;');

  console.log(`✅ Success! Seeded:`);
  console.log(`   - ${venuesCount.rows[0].count} Venues across 6 Major Cities`);
  console.log(`   - ${eventsCount.rows[0].count} Concert Events`);
  console.log(`   - ${seatsCount.rows[0].count} Arena Seats`);

  await db.close();
}

reseed().catch(console.error);

