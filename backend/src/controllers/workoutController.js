// src/controllers/workoutController.js
const db = require('../db');

// GET /api/workout/exercises  - list exercise library
const listExercises = async (req, res) => {
  try {
    const { muscle_group } = req.query;
    let query = 'SELECT * FROM exercises';
    let params = [];

    if (muscle_group) {
      query += ' WHERE muscle_group ILIKE $1';
      params = [`%${muscle_group}%`];
    }

    query += ' ORDER BY muscle_group, exercise_name';
    const result = await db.query(query, params);
    res.json({ success: true, exercises: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/workout/assign  (coach only)
const assignWorkout = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_id, plan_name, exercises } = req.body;
    // exercises = [{ exercise_id, sets, reps, notes, order_index }, ...]

    if (!participant_id || !exercises || !Array.isArray(exercises)) {
      return res.status(400).json({ success: false, message: 'participant_id and exercises array required' });
    }

    // Deactivate existing
    await db.query(
      'UPDATE workout_plans SET is_active = false WHERE participant_id = $1',
      [participant_id]
    );

    const planResult = await db.query(
      `INSERT INTO workout_plans (participant_id, coach_id, plan_name)
       VALUES ($1, $2, $3) RETURNING *`,
      [participant_id, coachId, plan_name || 'Current Workout']
    );

    const planId = planResult.rows[0].id;

    for (let i = 0; i < exercises.length; i++) {
      const ex = exercises[i];
      await db.query(
        `INSERT INTO workout_plan_exercises (workout_plan_id, exercise_id, sets, reps, notes, order_index)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [planId, ex.exercise_id, ex.sets || 3, ex.reps || 10, ex.notes || null, i]
      );
    }

    const fullPlan = await getPlanWithExercises(planId);
    res.status(201).json({ success: true, workout_plan: fullPlan });
  } catch (err) {
    console.error('Assign workout error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/workout/get
const getWorkout = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const planResult = await db.query(
      'SELECT id FROM workout_plans WHERE participant_id = $1 AND is_active = true ORDER BY created_at DESC LIMIT 1',
      [targetId]
    );

    if (planResult.rows.length === 0) {
      return res.json({ success: true, workout_plan: null });
    }

    const plan = await getPlanWithExercises(planResult.rows[0].id);
    res.json({ success: true, workout_plan: plan });
  } catch (err) {
    console.error('Get workout error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

async function getPlanWithExercises(planId) {
  const plan = await db.query('SELECT * FROM workout_plans WHERE id = $1', [planId]);
  const exercises = await db.query(
    `SELECT wpe.*, e.exercise_name, e.muscle_group, e.description
     FROM workout_plan_exercises wpe
     JOIN exercises e ON e.id = wpe.exercise_id
     WHERE wpe.workout_plan_id = $1
     ORDER BY wpe.order_index`,
    [planId]
  );
  return { ...plan.rows[0], exercises: exercises.rows };
}

module.exports = { listExercises, assignWorkout, getWorkout };
