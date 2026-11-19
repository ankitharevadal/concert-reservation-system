import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// GET /api/nosql - Read documents with JSONB query filtering
export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const tag = searchParams.get('tag');
    const db = await getDb();

    let query = `
      SELECT 
        feedback_id,
        event_id,
        user_id,
        review_doc->>'reviewer' AS reviewer_name,
        (review_doc->>'rating')::INT AS star_rating,
        review_doc->'vibe_tags' AS vibe_tags,
        review_doc->>'comment' AS comment,
        (review_doc->>'helpful_votes')::INT AS helpful_votes,
        review_doc,
        created_at
      FROM event_feedback_nosql
    `;

    const params: any[] = [];
    if (tag) {
      // JSON containment operator @>
      query += ` WHERE review_doc @> $1::jsonb`;
      params.push(JSON.stringify({ vibe_tags: [tag] }));
    }
    query += ` ORDER BY feedback_id DESC;`;

    const result = await db.query(query, params);
    return NextResponse.json({ success: true, count: result.rows.length, documents: result.rows });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// POST /api/nosql - [CREATE] Insert new nested JSON review document
export async function POST(req: Request) {
  try {
    const body = await req.json();
    const { event_id, user_id, reviewer, rating, comment, vibe_tags } = body;
    const db = await getDb();

    const reviewDoc = {
      reviewer: reviewer || 'Anonymous Fan',
      rating: parseInt(rating) || 5,
      comment: comment || 'Sensational concert experience!',
      vibe_tags: Array.isArray(vibe_tags) ? vibe_tags : (vibe_tags || 'live,music').split(',').map((s: string) => s.trim()),
      helpful_votes: 1,
      submission_source: 'Next.js Fan Portal Web UI',
    };

    const query = `
      INSERT INTO event_feedback_nosql (event_id, user_id, review_doc)
      VALUES ($1, $2, $3::jsonb)
      RETURNING feedback_id, review_doc, created_at;
    `;

    const result = await db.query(query, [parseInt(event_id) || 1, parseInt(user_id) || 3, JSON.stringify(reviewDoc)]);
    return NextResponse.json({
      success: true,
      message: 'NoSQL JSON document inserted successfully!',
      document: result.rows[0],
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// PUT /api/nosql - [UPDATE] In-place update of nested JSON document via jsonb_set
export async function PUT(req: Request) {
  try {
    const body = await req.json();
    const { feedback_id } = body;
    const db = await getDb();

    // Increment helpful_votes inside JSONB document using jsonb_set
    const query = `
      UPDATE event_feedback_nosql
      SET review_doc = jsonb_set(
        review_doc,
        '{helpful_votes}',
        to_jsonb(COALESCE((review_doc->>'helpful_votes')::INT, 0) + 1)
      )
      WHERE feedback_id = $1
      RETURNING feedback_id, review_doc;
    `;

    const result = await db.query(query, [parseInt(feedback_id)]);
    if (result.rows.length === 0) {
      return NextResponse.json({ success: false, error: 'Document not found' }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      message: 'NoSQL document field updated in-place via jsonb_set!',
      document: result.rows[0],
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

// DELETE /api/nosql - [DELETE] Remove NoSQL document
export async function DELETE(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const feedbackId = searchParams.get('feedbackId');
    if (!feedbackId) {
      return NextResponse.json({ success: false, error: 'feedbackId is required' }, { status: 400 });
    }

    const db = await getDb();
    const result = await db.query('DELETE FROM event_feedback_nosql WHERE feedback_id = $1 RETURNING feedback_id;', [parseInt(feedbackId)]);

    return NextResponse.json({
      success: true,
      message: `NoSQL Document ID ${feedbackId} deleted successfully.`,
      deletedCount: result.rows.length,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
