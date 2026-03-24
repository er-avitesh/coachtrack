// src/controllers/workoutController.js
const db = require('../db');

const listExercises = async (req, res) => {
  try {
    const { muscle_group } = req.query;
    let query = 'SELECT * FROM exercises'; let params = [];
    if (muscle_group) { query += ' WHERE muscle_group ILIKE $1'; params = [`%${muscle_group}%`]; }
    query += ' ORDER BY muscle_group, exercise_name';
    const result = await db.query(query, params);
    res.json({ success: true, exercises: result.rows });
  } catch (err) { res.status(500).json({ success: false, message: 'Server error' }); }
};

const assignWorkout = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_id, plan_name, days, start_date, end_date } = req.body;
    if (!participant_id || !days || !Array.isArray(days) || days.length === 0) {
      return res.status(400).json({ success: false, message: 'participant_id and days array required' });
    }
    await db.query('UPDATE workout_plans SET is_active = false WHERE participant_id = $1', [participant_id]);
    const planResult = await db.query(
      `INSERT INTO workout_plans (participant_id, coach_id, plan_name, total_days, start_date, end_date) VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [participant_id, coachId, plan_name || 'Workout Plan', days.length, start_date || null, end_date || null]
    );
    const planId = planResult.rows[0].id;
    for (let d = 0; d < days.length; d++) {
      const day = days[d];
      const dayResult = await db.query(
        `INSERT INTO workout_days (workout_plan_id, day_number, day_name, order_index) VALUES ($1,$2,$3,$4) RETURNING id`,
        [planId, d + 1, day.day_name, d]
      );
      const dayId = dayResult.rows[0].id;
      for (let e = 0; e < (day.exercises || []).length; e++) {
        const ex = day.exercises[e];
        await db.query(
          `INSERT INTO workout_day_exercises (workout_day_id, exercise_id, sets, reps, notes, order_index) VALUES ($1,$2,$3,$4,$5,$6)`,
          [dayId, ex.exercise_id, ex.sets || 3, ex.reps || 10, ex.notes || null, e]
        );
      }
    }
    const fullPlan = await getPlanWithDays(planId);
    res.status(201).json({ success: true, workout_plan: fullPlan });
  } catch (err) {
    console.error('Assign workout error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const getWorkout = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id) : req.user.id;
    const planResult = await db.query(
      'SELECT id FROM workout_plans WHERE participant_id = $1 AND is_active = true ORDER BY created_at DESC LIMIT 1',
      [targetId]
    );
    if (planResult.rows.length === 0) return res.json({ success: true, workout_plan: null });
    const plan = await getPlanWithDays(planResult.rows[0].id);
    res.json({ success: true, workout_plan: plan });
  } catch (err) {
    console.error('Get workout error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

async function getPlanWithDays(planId) {
  const [planResult, daysResult, exResult] = await Promise.all([
    db.query('SELECT * FROM workout_plans WHERE id = $1', [planId]),
    db.query('SELECT * FROM workout_days WHERE workout_plan_id = $1 ORDER BY order_index', [planId]),
    db.query(
      `SELECT wde.*, e.exercise_name, e.muscle_group, e.description, e.youtube_video_id
       FROM workout_day_exercises wde
       JOIN exercises e ON e.id = wde.exercise_id
       JOIN workout_days wd ON wd.id = wde.workout_day_id
       WHERE wd.workout_plan_id = $1
       ORDER BY wd.order_index, wde.order_index`,
      [planId]
    ),
  ]);

  const exByDay = {};
  for (const ex of exResult.rows) {
    (exByDay[ex.workout_day_id] ??= []).push(ex);
  }

  return {
    ...planResult.rows[0],
    days: daysResult.rows.map(day => ({ ...day, exercises: exByDay[day.id] ?? [] })),
  };
}

const saveSession = async (req, res) => {
  try {
    const userId = req.user.id;
    const { workout_plan_id, workout_day_id, day_name, set_logs } = req.body;
    if (!set_logs || !Array.isArray(set_logs) || set_logs.length === 0) {
      return res.status(400).json({ success: false, message: 'set_logs array required' });
    }
    const sessionResult = await db.query(
      `INSERT INTO workout_sessions (user_id, workout_plan_id, workout_day_id, day_name)
       VALUES ($1,$2,$3,$4) RETURNING id`,
      [userId, workout_plan_id || null, workout_day_id || null, day_name || null]
    );
    const sessionId = sessionResult.rows[0].id;
    for (const log of set_logs) {
      await db.query(
        `INSERT INTO workout_set_logs (session_id, exercise_id, exercise_name, set_number, reps_done, weight_kg)
         VALUES ($1,$2,$3,$4,$5,$6)`,
        [sessionId, log.exercise_id, log.exercise_name, log.set_number,
         log.reps_done || null, log.weight_kg || null]
      );
    }
    res.json({ success: true, session_id: sessionId });
  } catch (err) {
    console.error('Save session error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const getHistory = async (req, res) => {
  try {
    const userId = req.user.id;
    const sessions = await db.query(
      `SELECT id, day_name, completed_at FROM workout_sessions
       WHERE user_id = $1 ORDER BY completed_at DESC LIMIT 30`,
      [userId]
    );
    if (sessions.rows.length === 0) return res.json({ success: true, sessions: [] });

    const sessionIds = sessions.rows.map(s => s.id);
    const logs = await db.query(
      `SELECT * FROM workout_set_logs WHERE session_id = ANY($1) ORDER BY session_id, exercise_name, set_number`,
      [sessionIds]
    );

    const logsBySession = {};
    for (const log of logs.rows) {
      (logsBySession[log.session_id] ??= []).push(log);
    }

    const result = sessions.rows.map(s => ({
      ...s,
      logs: logsBySession[s.id] ?? [],
    }));

    res.json({ success: true, sessions: result });
  } catch (err) {
    console.error('Get history error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const updateExerciseVideo = async (req, res) => {
  try {
    const { id } = req.params;
    const { youtube_video_id } = req.body;
    await db.query(
      'UPDATE exercises SET youtube_video_id = $1 WHERE id = $2',
      [youtube_video_id || null, id]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Update exercise video error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { listExercises, assignWorkout, getWorkout, updateExerciseVideo, saveSession, getHistory };
