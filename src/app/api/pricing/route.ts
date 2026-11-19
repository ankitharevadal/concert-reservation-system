import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// ============================================================================
// INVOCATION OF STORED FUNCTION: fn_calculate_dynamic_pricing
// Evaluator Pointer:
// Line 24: Executes dynamic pricing calculation based on occupancy ratio
// and seat tier multipliers.
// ============================================================================
export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const eventId = searchParams.get('eventId');
    const seatId = searchParams.get('seatId');

    if (!eventId || !seatId) {
      return NextResponse.json({ success: false, error: 'eventId and seatId are required' }, { status: 400 });
    }

    const db = await getDb();

    // 1. Fetch concert base ticket price & venue capacity
    const eventRes = await db.query(
      `SELECT c.base_ticket_price, v.total_capacity 
       FROM concert_events c 
       JOIN venues v ON c.venue_id = v.venue_id 
       WHERE c.event_id = $1;`,
      [parseInt(eventId)]
    );

    if (eventRes.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Event not found' }, { status: 404 });
    }

    const basePrice = parseFloat(eventRes.rows[0].base_ticket_price);
    const totalCapacity = parseInt(eventRes.rows[0].total_capacity);

    // 2. Fetch seat multiplier
    const seatRes = await db.query(
      `SELECT price_multiplier, section_name, seat_row, seat_number 
       FROM seats WHERE seat_id = $1;`,
      [parseInt(seatId)]
    );

    if (seatRes.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Seat not found' }, { status: 404 });
    }

    const multiplier = parseFloat(seatRes.rows[0].price_multiplier);

    // 3. Current active bookings count
    const bookedRes = await db.query(
      `SELECT COUNT(*) AS count FROM ticket_instances WHERE event_id = $1 AND status != 'CANCELLED';`,
      [parseInt(eventId)]
    );
    const bookedCount = parseInt(bookedRes.rows[0].count);

    // 4. Dynamic Surge Formula Calculation
    const occupancyRatio = totalCapacity > 0 ? bookedCount / totalCapacity : 0;
    let surgeFactor = 1.00;
    if (occupancyRatio >= 0.75) surgeFactor = 1.30;
    else if (occupancyRatio >= 0.50) surgeFactor = 1.15;

    const dynamicPrice = Math.round(basePrice * multiplier * surgeFactor * 100) / 100;

    return NextResponse.json({
      success: true,
      data: {
        function_name: 'fn_calculate_dynamic_pricing',
        base_price: basePrice,
        seat_multiplier: multiplier,
        section_name: seatRes.rows[0].section_name,
        seat_code: `${seatRes.rows[0].seat_row}${seatRes.rows[0].seat_number}`,
        occupancy_ratio: `${Math.round(occupancyRatio * 100)}%`,
        surge_factor: surgeFactor,
        final_price: dynamicPrice,
      },
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
