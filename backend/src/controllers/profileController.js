// src/controllers/profileController.js
const db = require('../db');

// POST /api/profile/create  (or upsert)
const createOrUpdate = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      dob, gender, height_cm, current_weight_kg, goal_weight_kg,
      activity_level, health_conditions, medications, injuries,
      family_type, family_members_count, diet_preference, allergies,
    } = req.body;

    const result = await db.query(
      `INSERT INTO profiles (
        user_id, dob, gender, height_cm, current_weight_kg, goal_weight_kg,
        activity_level, health_conditions, medications, injuries,
        family_type, family_members_count, diet_preference, allergies, updated_at
      ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,NOW())
      ON CONFLICT (user_id) DO UPDATE SET
        dob = EXCLUDED.dob,
        gender = EXCLUDED.gender,
        height_cm = EXCLUDED.height_cm,
        current_weight_kg = EXCLUDED.current_weight_kg,
        goal_weight_kg = EXCLUDED.goal_weight_kg,
        activity_level = EXCLUDED.activity_level,
        health_conditions = EXCLUDED.health_conditions,
        medications = EXCLUDED.medications,
        injuries = EXCLUDED.injuries,
        family_type = EXCLUDED.family_type,
        family_members_count = EXCLUDED.family_members_count,
        diet_preference = EXCLUDED.diet_preference,
        allergies = EXCLUDED.allergies,
        updated_at = NOW()
      RETURNING *`,
      [
        userId, dob, gender, height_cm, current_weight_kg, goal_weight_kg,
        activity_level, health_conditions, medications, injuries,
        family_type, family_members_count || 1, diet_preference, allergies,
      ]
    );

    res.json({ success: true, profile: result.rows[0] });
  } catch (err) {
    console.error('Profile upsert error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/profile/get
const getProfile = async (req, res) => {
  try {
    // Coach can view any participant profile via ?user_id=X
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const result = await db.query(
      `SELECT p.*, u.full_name, u.email, u.username
       FROM profiles p
       JOIN users u ON u.id = p.user_id
       WHERE p.user_id = $1`,
      [targetId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Profile not found' });
    }

    // Get latest photos
    const photos = await db.query(
      `SELECT DISTINCT ON (photo_type) photo_type, s3_url, uploaded_at
       FROM body_photos WHERE user_id = $1
       ORDER BY photo_type, uploaded_at DESC`,
      [targetId]
    );

    res.json({
      success: true,
      profile: result.rows[0],
      photos: photos.rows,
    });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { createOrUpdate, getProfile };
