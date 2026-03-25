// src/controllers/trackingController.js
const db = require('../db');

// POST /api/tracking/add
const addTracking = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      date, weight_kg, stress_level, water_intake_liters,
      steps, sleep_hours, mood, deviation_notes,
    } = req.body;

    const trackDate = date || new Date().toISOString().split('T')[0];

    const result = await db.query(
      `INSERT INTO daily_tracking (
        user_id, date, weight_kg, stress_level, water_intake_liters,
        steps, sleep_hours, mood, deviation_notes
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      ON CONFLICT (user_id, date) DO UPDATE SET
        weight_kg           = COALESCE(EXCLUDED.weight_kg,           daily_tracking.weight_kg),
        stress_level        = COALESCE(EXCLUDED.stress_level,        daily_tracking.stress_level),
        water_intake_liters = COALESCE(EXCLUDED.water_intake_liters, daily_tracking.water_intake_liters),
        steps               = COALESCE(EXCLUDED.steps,               daily_tracking.steps),
        sleep_hours         = COALESCE(EXCLUDED.sleep_hours,         daily_tracking.sleep_hours),
        mood                = COALESCE(EXCLUDED.mood,                daily_tracking.mood),
        deviation_notes     = COALESCE(EXCLUDED.deviation_notes,     daily_tracking.deviation_notes)
      RETURNING *`,
      [
        userId, trackDate, weight_kg, stress_level, water_intake_liters,
        steps, sleep_hours, mood, deviation_notes,
      ]
    );

    res.json({ success: true, tracking: result.rows[0] });
  } catch (err) {
    console.error('Add tracking error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/tracking/get?days=30&user_id=X
const getTracking = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const days = parseInt(req.query.days) || 30;

    const result = await db.query(
      `SELECT * FROM daily_tracking
       WHERE user_id = $1 AND date >= NOW() - INTERVAL '${days} days'
       ORDER BY date DESC`,
      [targetId]
    );

    res.json({ success: true, tracking: result.rows });
  } catch (err) {
    console.error('Get tracking error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/tracking/today
const getToday = async (req, res) => {
  try {
    const today = new Date().toISOString().split('T')[0];
    const result = await db.query(
      'SELECT * FROM daily_tracking WHERE user_id = $1 AND date = $2',
      [req.user.id, today]
    );
    res.json({ success: true, tracking: result.rows[0] || null });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { addTracking, getTracking, getToday };
