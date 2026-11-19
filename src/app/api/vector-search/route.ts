import { NextResponse } from 'next/server';
import { getDb } from '@/lib/db';

// Preset vibe vectors in 5D audio feature space:
// [Energy, Acousticness, Danceability, Valence/Happiness, Crowd Scale]
const VIBE_PRESETS: Record<string, { label: string; vector: number[] }> = {
  acoustic_peace: {
    label: 'Calm & Cozy Acoustic Folk',
    vector: [0.30, 0.90, 0.35, 0.50, 0.30],
  },
  stadium_rock: {
    label: 'Euphoric Stadium Lights & Anthems',
    vector: [0.90, 0.35, 0.75, 0.95, 0.98],
  },
  party_bhangra: {
    label: 'High-Energy Dance & Club Beats',
    vector: [0.95, 0.15, 0.98, 0.90, 0.92],
  },
  symphonic_fusion: {
    label: 'Spiritual Orchestra & World Fusion',
    vector: [0.65, 0.85, 0.45, 0.80, 0.90],
  },
};

function cosineSimilarity(a: number[], b: number[]): number {
  let dotProduct = 0;
  let mA = 0;
  let mB = 0;
  for (let i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    mA += a[i] * a[i];
    mB += b[i] * b[i];
  }
  mA = Math.sqrt(mA);
  mB = Math.sqrt(mB);
  if (mA === 0 || mB === 0) return 0;
  return dotProduct / (mA * mB);
}

// GET /api/vector-search?preset=acoustic_peace
export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const preset = searchParams.get('preset') || 'acoustic_peace';
    const target = VIBE_PRESETS[preset] || VIBE_PRESETS.acoustic_peace;

    const db = await getDb();
    const result = await db.query(
      `SELECT embedding_id, event_id, event_title, vibe_category, feature_vector, tags 
       FROM concert_vector_embeddings;`
    );

    const scored = result.rows.map((row: any) => {
      // Ensure feature_vector is parsed as numbers
      const vec = Array.isArray(row.feature_vector) 
        ? row.feature_vector.map(Number)
        : (row.feature_vector || '').replace(/[{}]/g, '').split(',').map(Number);
      
      const score = cosineSimilarity(target.vector, vec);

      return {
        event_id: row.event_id,
        event_title: row.event_title,
        vibe_category: row.vibe_category,
        tags: row.tags,
        feature_vector: vec,
        similarity_score: Math.round(score * 10000) / 10000,
        match_percentage: `${Math.round(score * 100)}%`,
        recommended_seat_tier: score > 0.95 ? 'VIP_LOUNGE (Best Experience)' : score > 0.85 ? 'GOLD_FRONT' : 'SILVER_MIDDLE',
      };
    });

    // Rank highest similarity first
    scored.sort((a: any, b: any) => b.similarity_score - a.similarity_score);

    const vectorSqlCode = `
-- Vector Cosine Similarity Query in PostgreSQL
WITH user_target AS (
    SELECT ARRAY[${target.vector.join(', ')}]::FLOAT8[] AS u_vec
)
SELECT 
    cve.event_id,
    cve.event_title,
    cve.vibe_category,
    ROUND(
        (
            (cve.feature_vector[1]*u_vec[1] + cve.feature_vector[2]*u_vec[2] + 
             cve.feature_vector[3]*u_vec[3] + cve.feature_vector[4]*u_vec[4] + 
             cve.feature_vector[5]*u_vec[5])
            /
            (
                SQRT(POWER(cve.feature_vector[1],2) + POWER(cve.feature_vector[2],2) + POWER(cve.feature_vector[3],2) + POWER(cve.feature_vector[4],2) + POWER(cve.feature_vector[5],2))
                *
                SQRT(POWER(u_vec[1],2) + POWER(u_vec[2],2) + POWER(u_vec[3],2) + POWER(u_vec[4],2) + POWER(u_vec[5],2))
            )
        )::NUMERIC, 4
    ) AS cosine_similarity_score
FROM concert_vector_embeddings cve, user_target
ORDER BY cosine_similarity_score DESC;
    `;

    return NextResponse.json({
      success: true,
      selected_preset: preset,
      preset_label: target.label,
      target_vector: target.vector,
      vector_sql_query: vectorSqlCode.trim(),
      ranked_recommendations: scored,
    });
  } catch (error: any) {
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}
