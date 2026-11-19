-- ============================================================================
-- PES University - Department of Computer Science & Engineering
-- Course: Database Management System (Aug - Dec 2026)
-- Project: Concert and Live Event Management & Intelligent Seat Reservation System
-- File: 02_dml.sql (Data Manipulation Language - Complete Nationwide Seed Data)
-- ============================================================================

-- 1. INSERT USERS (Admins, Organizers, Customers)
INSERT INTO user_profiles (full_name, email, password_hash, phone_number, role, date_of_birth) VALUES
('Aarav Sharma (Admin)', 'aarav.admin@pesevents.edu', '$2b$10$hashed_admin', '+919876543210', 'ADMIN', '1995-04-12'),
('Priya Nair (Organizer)', 'priya.organizer@liveconcerts.in', '$2b$10$hashed_org', '+919812345678', 'ORGANIZER', '1998-09-23'),
('Rohan Verma (Attendee)', 'rohan.verma@gmail.com', '$2b$10$hashed_usr1', '+919765432109', 'CUSTOMER', '2003-01-15'),
('Sneha Reddy (Attendee)', 'sneha.reddy@outlook.com', '$2b$10$hashed_usr2', '+919654321098', 'CUSTOMER', '2002-11-30'),
('Vikram Malhotra (Attendee)', 'vikram.m@yahoo.com', '$2b$10$hashed_usr3', '+919543210987', 'CUSTOMER', '2001-07-08');

-- 2. INSERT VENUES (Arenas across 6 Major Indian Metropolitan Hubs)
INSERT INTO venues (venue_id, venue_name, street_address, city, state, postal_code, total_capacity, contact_email) VALUES
(1, 'PES University Open Arena', '100 Feet Ring Road, BSK III Stage', 'Bengaluru', 'Karnataka', '560085', 8500, 'events@pes.edu'),
(2, 'Palace Grounds Royal Enclosure', 'Bellary Road, Jayamahal', 'Bengaluru', 'Karnataka', '560006', 25000, 'info@palacegrounds.com'),
(3, 'DY Patil Multi-Purpose Stadium', 'Sector 7, Nerul', 'Mumbai', 'Maharashtra', '400706', 45000, 'operations@dypatilstadium.com'),
(4, 'Jawaharlal Nehru Stadium Arena', 'Pragati Vihar, Lodhi Road', 'New Delhi', 'Delhi', '110003', 35000, 'contact@jlnstadium.gov.in'),
(5, 'G. M. C. Balayogi Athletic Stadium', 'Gachibowli Sports Complex', 'Hyderabad', 'Telangana', '500032', 30000, 'events@gmcstadium.telangana.gov.in'),
(6, 'Jawaharlal Nehru Stadium Marina', 'Sydenhams Road, Periamet', 'Chennai', 'Tamil Nadu', '600003', 40000, 'support@jlnstadiumchennai.com'),
(7, 'Eden Gardens Arena Enclosure', 'B.B.D. Bagh, Strand Road', 'Kolkata', 'West Bengal', '700021', 50000, 'booking@edengardensarena.in');

-- 3. INSERT ARTISTS
INSERT INTO artists (artist_id, stage_name, bio, country_of_origin, billing_rate_per_hour) VALUES
(1, 'A. R. Rahman Live', 'Oscar & Grammy-winning maestro performing symphonic fusion live.', 'India', 250000.00),
(2, 'Coldplay Experience', 'Global stadium rock icon performing world tour spectacle.', 'United Kingdom', 750000.00),
(3, 'Diljit Dosanjh', 'Punjabi pop sensation bringing the high-octane Dil-Luminati tour.', 'India', 350000.00),
(4, 'Prateek Kuhad', 'Intimate indie acoustic folk singer-songwriter.', 'India', 85000.00),
(5, 'Dua Lipa Electro', 'Global pop sensation with synth-pop dance beats.', 'United Kingdom', 450000.00),
(6, 'Arijit Singh', 'Soulful Bollywood maestro and acoustic sensation.', 'India', 400000.00),
(7, 'Anirudh Live Band', 'Rockstar composer delivering energetic EDM-rock stadium anthems.', 'India', 300000.00),
(8, 'Karan Aujla', 'Desi hip-hop and trap superstar selling out world arenas.', 'India', 280000.00);

-- 4. INSERT MULTI-VALUED ATTRIBUTE (artist_genres)
INSERT INTO artist_genres (artist_id, genre) VALUES
(1, 'Sufi'), (1, 'World Fusion'), (1, 'Soundtrack'),
(2, 'Alternative Rock'), (2, 'Pop Rock'),
(3, 'Punjabi Pop'), (3, 'Bhangra Hip-Hop'),
(4, 'Indie Folk'), (4, 'Acoustic Pop'),
(5, 'Synth-Pop'), (5, 'Dance-Pop'),
(6, 'Bollywood Romantic'), (6, 'Classical Fusion'),
(7, 'Tamil Rock'), (7, 'EDM Fusion'),
(8, 'Punjabi Hip-Hop'), (8, 'Trap Rap');

-- 5. INSERT CONCERTS ACROSS ALL MAJOR CITIES
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

-- 6. POPULATE 130 SEATS PER VENUE FOR ALL 7 VENUES (910 TOTAL SEATS)
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

-- 7. INITIAL CONFIRMED BOOKINGS
INSERT INTO bookings (booking_reference, user_id, event_id, total_amount, booking_status, payment_method) VALUES
('BK-BLR-1001', 3, 1, 12500.00, 'CONFIRMED', 'UPI'),
('BK-MUM-2001', 4, 2, 19800.00, 'CONFIRMED', 'CREDIT_CARD'),
('BK-DEL-3001', 5, 3, 9600.00, 'CONFIRMED', 'NET_BANKING'),
('BK-HYD-4001', 3, 7, 6600.00, 'CONFIRMED', 'UPI'),
('BK-CHN-5001', 4, 8, 13000.00, 'CONFIRMED', 'CREDIT_CARD');

-- 8. INITIAL TICKET PASSES
INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status) VALUES
(1, 1, 3, 6250.00, 'BC-BLR-A3-88492049182', 'RESERVED'),
(1, 1, 4, 6250.00, 'BC-BLR-A4-88492049183', 'RESERVED');

INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status)
SELECT 2, 2, seat_id, 9900.00, 'BC-MUM-' || seat_id || '-5541289', 'RESERVED'
FROM seats WHERE venue_id = 3 AND seat_row = 'A' AND seat_number IN (1, 2);

INSERT INTO ticket_instances (booking_id, event_id, seat_id, allocated_price, barcode_hash, status)
SELECT 3, 3, seat_id, 4800.00, 'BC-DEL-' || seat_id || '-9981241', 'RESERVED'
FROM seats WHERE venue_id = 4 AND seat_row = 'C' AND seat_number IN (1, 2);

-- 9. AUDIT LOG INITIAL SEED
INSERT INTO seat_audit_logs (ticket_id, event_id, seat_id, action_type, old_status, new_status, old_price, new_price, changed_by) VALUES
(1, 1, 3, 'INSERT', 'AVAILABLE', 'RESERVED', NULL, 6250.00, 'sp_book_tickets_atomic'),
(2, 1, 4, 'INSERT', 'AVAILABLE', 'RESERVED', NULL, 6250.00, 'sp_book_tickets_atomic');

-- 10. NoSQL JSONB FEEDBACK
INSERT INTO event_feedback_nosql (event_id, user_id, review_doc) VALUES
(1, 3, '{"reviewer": "Rohan Verma", "rating": 5, "vibe_tags": ["spiritual", "orchestral"], "comment": "50 violinists playing Roja live was sheer perfection!", "helpful_votes": 42}'),
(2, 4, '{"reviewer": "Sneha Reddy", "rating": 5, "vibe_tags": ["euphoric", "stadium_anthem"], "comment": "The LED wristbands lit up DY Patil Stadium like magic!", "helpful_votes": 68}'),
(3, 5, '{"reviewer": "Vikram Malhotra", "rating": 5, "vibe_tags": ["energetic", "party"], "comment": "Non-stop bhangra energy for 2.5 hours in Delhi!", "helpful_votes": 35}');

-- 11. VECTOR EMBEDDINGS (5D Embeddings for All 10 Events)
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
