// src/controllers/lifestyleController.js
const db = require('../db');

// POST /api/lifestyle/assign  (coach only)
const assignLifestyle = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_id, plan_name, items, start_date, end_date } = req.body;
    if (!participant_id || !items || !Array.isArray(items)) {
      return res.status(400).json({ success: false, message: 'participant_id and items required' });
    }
    await db.query('UPDATE lifestyle_plans SET is_active = false WHERE participant_id = $1', [participant_id]);
    const planResult = await db.query(
      `INSERT INTO lifestyle_plans (participant_id, coach_id, plan_name, start_date, end_date) VALUES ($1,$2,$3,$4,$5) RETURNING *`,
      [participant_id, coachId, plan_name || 'Lifestyle Plan', start_date || null, end_date || null]
    );
    const planId = planResult.rows[0].id;
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      await db.query(
        `INSERT INTO lifestyle_items (lifestyle_plan_id, category, title, target_value, unit, notes, order_index)
         VALUES ($1,$2,$3,$4,$5,$6,$7)`,
        [planId, item.category, item.title, item.target_value || null, item.unit || null, item.notes || null, i]
      );
    }
    const full = await getPlanWithItems(planId);
    res.status(201).json({ success: true, lifestyle_plan: full });
  } catch (err) {
    console.error('Assign lifestyle error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/lifestyle/get
const getLifestyle = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id) : req.user.id;
    const planResult = await db.query(
      'SELECT id FROM lifestyle_plans WHERE participant_id = $1 AND is_active = true ORDER BY created_at DESC LIMIT 1',
      [targetId]
    );
    if (planResult.rows.length === 0) return res.json({ success: true, lifestyle_plan: null });
    const plan = await getPlanWithItems(planResult.rows[0].id);
    res.json({ success: true, lifestyle_plan: plan });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

async function getPlanWithItems(planId) {
  const plan  = await db.query('SELECT * FROM lifestyle_plans WHERE id = $1', [planId]);
  const items = await db.query('SELECT * FROM lifestyle_items WHERE lifestyle_plan_id = $1 ORDER BY order_index', [planId]);
  return { ...plan.rows[0], items: items.rows };
}

module.exports = { assignLifestyle, getLifestyle };
