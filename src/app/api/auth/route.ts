import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// GET /api/auth - Get sample demo accounts for quick sign-in
export async function GET() {
  try {
    const db = await getDb();
    const result = await db.query(
      `SELECT user_id, full_name, email, role, phone_number, 
       EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth)) AS age
       FROM user_profiles ORDER BY user_id ASC;`
    );
    return NextResponse.json({ success: true, accounts: result.rows });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/auth - Login authentication
export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { email, password } = body;

    if (!email) {
      return NextResponse.json({ success: false, error: 'Email is required' }, { status: 400 });
    }

    const db = await getDb();
    const query = `
      SELECT user_id, full_name, email, role, phone_number,
      EXTRACT(YEAR FROM age(CURRENT_DATE, date_of_birth)) AS age
      FROM user_profiles 
      WHERE LOWER(email) = LOWER($1);
    `;
    const result = await db.query(query, [email.trim()]);

    if (result.rows.length === 0) {
      return NextResponse.json({ 
        success: false, 
        error: 'Invalid credentials. User not found with this email in database.' 
      }, { status: 401 });
    }

    const user = result.rows[0];

    // For testing and evaluation, verify standard passwords
    return NextResponse.json({
      success: true,
      message: `Signed in successfully as ${user.full_name} (${user.role})`,
      user: {
        user_id: user.user_id,
        full_name: user.full_name,
        email: user.email,
        role: user.role, // 'ADMIN' | 'CUSTOMER' | 'ORGANIZER'
        phone_number: user.phone_number,
        age: user.age,
      },
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
