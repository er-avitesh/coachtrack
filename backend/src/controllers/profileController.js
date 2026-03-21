// src/controllers/profileController.js
const db = require('../db');

// POST /api/profile/create  (upsert)
const createOrUpdate = async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      // existing
      dob, gender, height_cm, current_weight_kg, goal_weight_kg,
      activity_level, health_conditions, medications, injuries,
      family_type, family_members_count, diet_preference, allergies,
      health_goal,
      // eating pattern
      meals_per_day, meal_timings,
      // what you eat
      typical_breakfast, typical_lunch, typical_snacks, typical_dinner, tea_coffee,
      // eating out
      eating_out_frequency, eating_out_preference,
      // activity
      currently_workout, workout_type,
      // lifestyle baselines
      typical_sleep_hours, typical_daily_steps, typical_stress_level,
    } = req.body;

    const result = await db.query(
      `INSERT INTO profiles (
        user_id, dob, gender, height_cm, current_weight_kg, goal_weight_kg,
        activity_level, health_conditions, medications, injuries,
        family_type, family_members_count, diet_preference, allergies, health_goal,
        meals_per_day, meal_timings,
        typical_breakfast, typical_lunch, typical_snacks, typical_dinner, tea_coffee,
        eating_out_frequency, eating_out_preference,
        currently_workout, workout_type,
        typical_sleep_hours, typical_daily_steps, typical_stress_level,
        updated_at
      ) VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,
        $16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,NOW()
      )
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
        health_goal = EXCLUDED.health_goal,
        meals_per_day = EXCLUDED.meals_per_day,
        meal_timings = EXCLUDED.meal_timings,
        typical_breakfast = EXCLUDED.typical_breakfast,
        typical_lunch = EXCLUDED.typical_lunch,
        typical_snacks = EXCLUDED.typical_snacks,
        typical_dinner = EXCLUDED.typical_dinner,
        tea_coffee = EXCLUDED.tea_coffee,
        eating_out_frequency = EXCLUDED.eating_out_frequency,
        eating_out_preference = EXCLUDED.eating_out_preference,
        currently_workout = EXCLUDED.currently_workout,
        workout_type = EXCLUDED.workout_type,
        typical_sleep_hours = EXCLUDED.typical_sleep_hours,
        typical_daily_steps = EXCLUDED.typical_daily_steps,
        typical_stress_level = EXCLUDED.typical_stress_level,
        updated_at = NOW()
      RETURNING *`,
      [
        userId, dob, gender, height_cm, current_weight_kg, goal_weight_kg,
        activity_level, health_conditions || null, medications || null,
        injuries || null, family_type, family_members_count || 1,
        diet_preference, allergies || null, health_goal || null,
        meals_per_day || null, meal_timings || null,
        typical_breakfast || null, typical_lunch || null,
        typical_snacks || null, typical_dinner || null, tea_coffee || null,
        eating_out_frequency || null, eating_out_preference || null,
        currently_workout !== undefined ? currently_workout : null,
        workout_type || null,
        typical_sleep_hours || null, typical_daily_steps || null,
        typical_stress_level || null,
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
      return res.json({ success: true, profile: null });
    }

    const photos = await db.query(
      `SELECT DISTINCT ON (photo_type) photo_type, s3_url, uploaded_at
       FROM body_photos WHERE user_id = $1
       ORDER BY photo_type, uploaded_at DESC`,
      [targetId]
    );

    res.json({ success: true, profile: result.rows[0], photos: photos.rows });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { createOrUpdate, getProfile };
