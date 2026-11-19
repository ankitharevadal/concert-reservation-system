import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const queryType = searchParams.get('type') || 'join';
    const db = await getDb();

    let sqlCode = '';
    let description = '';
    let rows: any[] = [];

    switch (queryType) {
      case 'join':
        sqlCode = `
          SELECT 
            b.booking_reference,
            u.full_name AS customer_name,
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
        `;
        description = '4-Table Multi-Table Join with Left Outer Join linking Bookings, Users, Concerts, Artists, Venues, and Seats.';
        break;

      case 'nested':
        sqlCode = `
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
            SELECT AVG(total_amount) 
            FROM bookings 
            WHERE booking_status = 'CONFIRMED'
          )
          ORDER BY total_spent_by_user DESC;
        `;
        description = 'Nested Subquery in HAVING clause: Finds customers whose cumulative spending exceeds system-wide average booking value.';
        break;

      case 'correlated':
        sqlCode = `
          SELECT 
            c1.event_id,
            c1.event_title,
            c1.base_ticket_price,
            v.venue_name,
            ROUND((
              SELECT AVG(c2.base_ticket_price) 
              FROM concert_events c2 
              WHERE c2.venue_id = c1.venue_id
            ), 2) AS venue_average_price
          FROM concert_events c1
          JOIN venues v ON c1.venue_id = v.venue_id
          WHERE c1.base_ticket_price > (
            SELECT AVG(c2.base_ticket_price)
            FROM concert_events c2
            WHERE c2.venue_id = c1.venue_id
          );
        `;
        description = 'Correlated Subquery: Identifies concerts priced strictly higher than the average ticket price within the SAME venue.';
        break;

      case 'recursive_cte':
        sqlCode = `
          WITH RECURSIVE seat_tier_hierarchy AS (
            SELECT 
              1 AS tier_level,
              'BRONZE_BALCONY'::VARCHAR(50) AS tier_name,
              1.00::NUMERIC(3, 2) AS multiplier,
              'Base admission tier with standard view'::TEXT AS perks
            UNION ALL
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
        `;
        description = 'Recursive Common Table Expression (CTE): Dynamically generates the 4-level seat tier pricing ladder and multiplier progression.';
        break;

      default:
        return NextResponse.json({ success: false, error: 'Invalid query type' }, { status: 400 });
    }

    const result = await db.query(sqlCode);
    rows = result.rows;

    return NextResponse.json({
      success: true,
      queryType,
      description,
      sqlCode: sqlCode.trim(),
      rows,
      rowCount: rows.length,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
