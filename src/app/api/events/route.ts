import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// GET /api/events - Retrieve all concert events with artist and venue details
export async function GET() {
  try {
    const db = await getDb();
    const query = `
      SELECT 
        c.event_id,
        c.event_title,
        c.event_description,
        c.artist_id,
        a.stage_name AS artist_name,
        c.venue_id,
        v.venue_name,
        v.city,
        v.total_capacity,
        c.event_date_time,
        c.duration_minutes,
        c.base_ticket_price,
        c.event_status,
        -- Derived Attribute: Available Seats
        (v.total_capacity - COALESCE(
          (SELECT COUNT(*) FROM ticket_instances ti WHERE ti.event_id = c.event_id AND ti.status != 'CANCELLED'), 0
        )) AS available_seats
      FROM concert_events c
      JOIN artists a ON c.artist_id = a.artist_id
      JOIN venues v ON c.venue_id = v.venue_id
      ORDER BY c.event_date_time ASC;
    `;
    const result = await db.query(query);
    return NextResponse.json({ success: true, events: result.rows });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/events - [DML INSERT] Organizer/Admin creates a new concert event
export async function POST(req: Request) {
  try {
    const db = await getDb();
    const body = await req.json();
    const { event_title, event_description, artist_id, venue_id, event_date_time, duration_minutes, base_ticket_price } = body;

    const query = `
      INSERT INTO concert_events (
        event_title, event_description, artist_id, venue_id, 
        event_date_time, duration_minutes, base_ticket_price, event_status
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, 'SCHEDULED'
      ) RETURNING *;
    `;
    const params = [
      event_title || 'New Headline Tour',
      event_description || 'High-profile live musical concert performance.',
      parseInt(artist_id) || 1,
      parseInt(venue_id) || 1,
      event_date_time || new Date(Date.now() + 86400000 * 14).toISOString(),
      parseInt(duration_minutes) || 180,
      parseFloat(base_ticket_price) || 2000.00,
    ];

    const result = await db.query(query, params);
    return NextResponse.json({ 
      success: true, 
      event: result.rows[0], 
      message: 'DML INSERT successful: Concert created in database!' 
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// PUT /api/events - [DML UPDATE] Organizer/Admin updates a concert's price or status
export async function PUT(req: Request) {
  try {
    const db = await getDb();
    const body = await req.json();
    const { event_id, base_ticket_price, event_status, event_title } = body;

    if (!event_id) {
      return NextResponse.json({ success: false, error: 'event_id is required' }, { status: 400 });
    }

    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (base_ticket_price !== undefined) {
      updates.push(`base_ticket_price = $${paramIndex++}`);
      params.push(parseFloat(base_ticket_price));
    }

    if (event_status !== undefined) {
      updates.push(`event_status = $${paramIndex++}`);
      params.push(event_status);
    }

    if (event_title !== undefined) {
      updates.push(`event_title = $${paramIndex++}`);
      params.push(event_title);
    }

    if (updates.length === 0) {
      return NextResponse.json({ success: false, error: 'No fields provided to update' }, { status: 400 });
    }

    params.push(parseInt(event_id));
    const query = `
      UPDATE concert_events 
      SET ${updates.join(', ')} 
      WHERE event_id = $${paramIndex} 
      RETURNING *;
    `;

    const result = await db.query(query, params);
    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Event not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      message: `DML UPDATE successful: Concert ID ${event_id} updated in database!`,
      event: result.rows[0],
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// DELETE /api/events - [DML DELETE] Organizer/Admin deletes a concert event
export async function DELETE(req: Request) {
  try {
    const db = await getDb();
    const { searchParams } = new URL(req.url);
    const eventId = searchParams.get('eventId');

    if (!eventId) {
      return NextResponse.json({ success: false, error: 'Event ID is required' }, { status: 400 });
    }

    await db.query('DELETE FROM ticket_instances WHERE event_id = $1;', [parseInt(eventId)]);
    await db.query('DELETE FROM bookings WHERE event_id = $1;', [parseInt(eventId)]);
    await db.query('DELETE FROM event_riders_nosql WHERE event_id = $1;', [parseInt(eventId)]);
    await db.query('DELETE FROM concert_vector_embeddings WHERE event_id = $1;', [parseInt(eventId)]);
    const res = await db.query('DELETE FROM concert_events WHERE event_id = $1 RETURNING event_id;', [parseInt(eventId)]);

    return NextResponse.json({ 
      success: true, 
      message: `DML DELETE successful: Concert ID ${eventId} removed from database.`, 
      deletedCount: res.rows.length 
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
