// src/controllers/tipsController.js
const db = require('../db');

// POST /api/tips/add (coach only)
const addTip = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_id, content } = req.body;

    if (!participant_id || !content) {
      return res.status(400).json({ success: false, message: 'participant_id and content required' });
    }

    const result = await db.query(
      `INSERT INTO tips (participant_id, coach_id, content)
       VALUES ($1, $2, $3) RETURNING *`,
      [participant_id, coachId, content]
    );

    res.status(201).json({ success: true, tip: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/tips/get
const getTips = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const result = await db.query(
      `SELECT t.*, u.full_name as coach_name
       FROM tips t
       JOIN users u ON u.id = t.coach_id
       WHERE t.participant_id = $1
       ORDER BY t.created_at DESC`,
      [targetId]
    );

    res.json({ success: true, tips: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { addTip, getTips };
