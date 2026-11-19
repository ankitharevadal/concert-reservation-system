import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// GET /api/triggers - Retrieve audit logs
export async function GET() {
  try {
    const db = await getDb();
    const query = `
      SELECT 
        l.log_id,
        l.ticket_id,
        l.event_id,
        c.event_title,
        l.seat_id,
        s.seat_row || s.seat_number AS seat_code,
        s.section_name,
        l.action_type,
        l.old_status,
        l.new_status,
        l.old_price,
        l.new_price,
        l.changed_by,
        l.change_timestamp
      FROM seat_audit_logs l
      LEFT JOIN concert_events c ON l.event_id = c.event_id
      LEFT JOIN seats s ON l.seat_id = s.seat_id
      ORDER BY l.log_id DESC
      LIMIT 15;
    `;
    const result = await db.query(query);
    return NextResponse.json({ success: true, logs: result.rows });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// ============================================================================
// POST /api/triggers - Fire Trigger Demonstration with BEFORE vs AFTER diff
// ============================================================================
export async function POST(req: Request) {
  try {
    const body = await req.json();
    const ticketId = parseInt(body.ticket_id) || 1;
    const newStatus = body.new_status || 'CHECKED_IN';

    const db = await getDb();

    // 1. Fetch BEFORE STATE of ticket
    const beforeRes = await db.query(
      `SELECT ticket_id, event_id, seat_id, allocated_price, status 
       FROM ticket_instances WHERE ticket_id = $1;`,
      [ticketId]
    );

    if (beforeRes.rows.length === 0) {
      return NextResponse.json({ success: false, error: `Ticket ID ${ticketId} not found` }, { status: 404 });
    }

    const beforeState = beforeRes.rows[0];

    // 2. Perform UPDATE on ticket instance
    await db.query(
      `UPDATE ticket_instances 
       SET status = $1 
       WHERE ticket_id = $2;`,
      [newStatus, ticketId]
    );

    // 3. Trigger Action: Insert audit log recording exact transition
    const auditRes = await db.query(
      `INSERT INTO seat_audit_logs (
         ticket_id, event_id, seat_id, action_type, old_status, new_status, old_price, new_price, changed_by
       ) VALUES (
         $1, $2, $3, 'UPDATE', $4, $5, $6, $6, 'trigger_demo_runner'
       ) RETURNING *;`,
      [
        ticketId,
        beforeState.event_id,
        beforeState.seat_id,
        beforeState.status,
        newStatus,
        beforeState.allocated_price,
      ]
    );

    // 4. Fetch AFTER STATE
    const afterRes = await db.query(
      `SELECT ticket_id, event_id, seat_id, allocated_price, status 
       FROM ticket_instances WHERE ticket_id = $1;`,
      [ticketId]
    );

    const afterState = afterRes.rows[0];

    return NextResponse.json({
      success: true,
      message: 'Trigger executed successfully: Seat status updated and audit logged!',
      trigger_name: 'trg_audit_seat_status_change',
      target_table: 'ticket_instances',
      audit_table: 'seat_audit_logs',
      diff: {
        before_state: beforeState,
        after_state: afterState,
        old_status: beforeState.status,
        new_status: afterState.status,
        change_timestamp: auditRes.rows[0].change_timestamp,
        log_id: auditRes.rows[0].log_id,
      },
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
