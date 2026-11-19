import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// GET /api/seats?eventId=1 - Fetch seat grid with real-time reservation status
export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const eventId = searchParams.get('eventId') || '1';
    const db = await getDb();

    // Fetch all seats in venue, along with whether they are booked for this specific event
    const query = `
      SELECT 
        s.seat_id,
        s.venue_id,
        s.section_name,
        s.seat_row,
        s.seat_number,
        s.price_multiplier,
        CASE 
          WHEN ti.ticket_id IS NOT NULL AND ti.status != 'CANCELLED' THEN 'BOOKED'
          ELSE 'AVAILABLE'
        END AS current_status,
        ti.ticket_id,
        ti.status AS ticket_status,
        ti.allocated_price
      FROM seats s
      JOIN concert_events c ON c.venue_id = s.venue_id
      LEFT JOIN ticket_instances ti ON s.seat_id = ti.seat_id AND ti.event_id = c.event_id AND ti.status != 'CANCELLED'
      WHERE c.event_id = $1
      ORDER BY s.seat_row ASC, s.seat_number ASC;
    `;

    const result = await db.query(query, [parseInt(eventId)]);
    return NextResponse.json({ success: true, seats: result.rows });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
