// src/controllers/foodController.js
const db = require('../db');

// ── FatSecret OAuth2 token cache ──────────────────────────────────────────────
let _fsToken = null;
let _fsTokenExpiry = 0;

async function getFatSecretToken() {
  if (_fsToken && Date.now() < _fsTokenExpiry) return _fsToken;

  const clientId     = process.env.FATSECRET_CLIENT_ID;
  const clientSecret = process.env.FATSECRET_CLIENT_SECRET;
  if (!clientId || !clientSecret) return null;

  const credentials = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const res = await fetch('https://oauth.fatsecret.com/connect/token', {
    method: 'POST',
    headers: {
      'Content-Type':  'application/x-www-form-urlencoded',
      'Authorization': `Basic ${credentials}`,
    },
    body: 'grant_type=client_credentials&scope=basic',
  });

  if (!res.ok) throw new Error(`FatSecret token error: ${res.status}`);
  const data = await res.json();

  _fsToken       = data.access_token;
  _fsTokenExpiry = Date.now() + (data.expires_in - 120) * 1000; // 2 min buffer
  return _fsToken;
}

// Parse the description string from foods.search response
// e.g. "Per 100g - Calories: 91kcal | Fat: 0.35g | Carbs: 15.09g | Prot: 6.27g"
function parseFsDescription(desc = '') {
  const cal     = parseFloat((desc.match(/Calories:\s*([\d.]+)kcal/i) || [])[1] || '0');
  const fat     = parseFloat((desc.match(/Fat:\s*([\d.]+)g/i)        || [])[1] || '0');
  const carbs   = parseFloat((desc.match(/Carbs:\s*([\d.]+)g/i)      || [])[1] || '0');
  const protein = parseFloat((desc.match(/Prot:\s*([\d.]+)g/i)       || [])[1] || '0');
  return { cal, fat, carbs, protein };
}

// ── GET /api/food/search?q=dal ────────────────────────────────────────────────
const searchFood = async (req, res) => {
  const q = (req.query.q || '').trim();
  if (q.length < 2) return res.json({ success: true, foods: [] });

  try {
    // 1. Check our cached results first (includes FatSecret items stored previously)
    const cached = await db.query(
      `SELECT * FROM food_cache
       WHERE LOWER(name) LIKE $1 OR LOWER(name_hi) LIKE $1
       ORDER BY search_count DESC
       LIMIT 20`,
      [`%${q.toLowerCase()}%`]
    );

    const foods = cached.rows.map(r => ({
      id:               r.food_id,
      name:             r.name,
      name_hi:          r.name_hi || '',
      calories_per_100g: parseFloat(r.calories_per_100g) || 0,
      protein_g:        parseFloat(r.protein_g) || 0,
      carbs_g:          parseFloat(r.carbs_g) || 0,
      fat_g:            parseFloat(r.fat_g) || 0,
      fiber_g:          parseFloat(r.fiber_g) || 0,
      servings:         r.servings_json || [{ label: '100g', grams: 100 }],
      source:           r.source,
    }));

    // 2. If fewer than 5 cached results, also query FatSecret
    if (foods.length < 5) {
      try {
        const token = await getFatSecretToken();
        if (token) {
          const url = `https://platform.fatsecret.com/rest/server.api?method=foods.search&search_expression=${encodeURIComponent(q)}&format=json&max_results=10`;
          const fsRes = await fetch(url, {
            headers: { Authorization: `Bearer ${token}` },
          });

          if (fsRes.ok) {
            const fsData = await fsRes.json();
            const fsList = fsData?.foods?.food ?? [];
            const arr = Array.isArray(fsList) ? fsList : [fsList];

            for (const f of arr) {
              const foodId = `fs_${f.food_id}`;
              if (foods.some(c => c.id === foodId)) continue;

              const macros = parseFsDescription(f.food_description);
              const newFood = {
                id:               foodId,
                name:             f.food_name,
                name_hi:          '',
                calories_per_100g: macros.cal,
                protein_g:        macros.protein,
                carbs_g:          macros.carbs,
                fat_g:            macros.fat,
                fiber_g:          0,
                servings: [
                  { label: '100g',                  grams: 100 },
                  { label: '1 serving (150g)',       grams: 150 },
                  { label: '1 cup / 1 कप  (240ml)', grams: 240 },
                ],
                source: 'fatsecret',
              };
              foods.push(newFood);

              // Cache non-blocking
              db.query(
                `INSERT INTO food_cache (food_id, name, calories_per_100g, protein_g, carbs_g, fat_g, fiber_g, servings_json, source)
                 VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
                 ON CONFLICT (food_id) DO UPDATE SET search_count = food_cache.search_count + 1`,
                [foodId, f.food_name, macros.cal, macros.protein, macros.carbs, macros.fat, 0,
                 JSON.stringify(newFood.servings), 'fatsecret']
              ).catch(() => {});
            }
          }
        }
      } catch (fsErr) {
        // FatSecret failure is non-critical — just return cached results
        console.warn('FatSecret search error:', fsErr.message);
      }
    }

    res.json({ success: true, foods });
  } catch (err) {
    console.error('Food search error:', err);
    res.status(500).json({ success: false, message: 'Search failed' });
  }
};

// ── POST /api/food/log ────────────────────────────────────────────────────────
const logMeal = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      food_id, food_name, food_name_hi,
      serving_label, serving_grams,
      calories, protein_g, carbs_g, fat_g, fiber_g,
      date,
    } = req.body;

    if (!food_name || !calories) {
      return res.status(400).json({ success: false, message: 'food_name and calories are required' });
    }

    const logDate = date || new Date().toISOString().split('T')[0];

    const result = await db.query(
      `INSERT INTO meal_logs
         (user_id, date, food_id, food_name, food_name_hi, serving_label, serving_grams, calories, protein_g, carbs_g, fat_g, fiber_g)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      [userId, logDate, food_id, food_name, food_name_hi,
       serving_label, serving_grams, calories, protein_g || 0,
       carbs_g || 0, fat_g || 0, fiber_g || 0]
    );

    res.status(201).json({ success: true, log: result.rows[0] });
  } catch (err) {
    console.error('Log meal error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── GET /api/food/log?date=YYYY-MM-DD ────────────────────────────────────────
const getMealLog = async (req, res) => {
  try {
    const userId = req.user.id;
    const date   = req.query.date || new Date().toISOString().split('T')[0];

    const result = await db.query(
      'SELECT * FROM meal_logs WHERE user_id = $1 AND date = $2 ORDER BY created_at ASC',
      [userId, date]
    );

    res.json({ success: true, logs: result.rows });
  } catch (err) {
    console.error('Get meal log error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// ── DELETE /api/food/log/:id ──────────────────────────────────────────────────
const deleteMealLogEntry = async (req, res) => {
  try {
    await db.query(
      'DELETE FROM meal_logs WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Delete log entry error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { searchFood, logMeal, getMealLog, deleteMealLogEntry };
