// src/controllers/coachController.js
const db = require('../db');

// GET /api/coach/clients  - list all clients for this coach
const getClients = async (req, res) => {
  try {
    const coachId = req.user.id;

    const result = await db.query(
      `SELECT u.id, u.username, u.full_name, u.email,
              p.current_weight_kg, p.goal_weight_kg, p.diet_preference,
              (SELECT date FROM daily_tracking WHERE user_id = u.id ORDER BY date DESC LIMIT 1) as last_tracked
       FROM coach_clients cc
       JOIN users u ON u.id = cc.participant_id
       LEFT JOIN profiles p ON p.user_id = u.id
       WHERE cc.coach_id = $1
       ORDER BY u.full_name`,
      [coachId]
    );

    res.json({ success: true, clients: result.rows });
  } catch (err) {
    console.error('Get clients error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/coach/clients/add  - link a participant to this coach
const addClient = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_username } = req.body;

    const userResult = await db.query(
      "SELECT id, full_name FROM users WHERE LOWER(username) = LOWER($1) AND role = 'participant'",
      [participant_username]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Participant not found' });
    }

    const participant = userResult.rows[0];

    await db.query(
      'INSERT INTO coach_clients (coach_id, participant_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [coachId, participant.id]
    );

    res.json({ success: true, message: `${participant.full_name} added as client` });
  } catch (err) {
    console.error('Add client error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/coach/client/:id/summary  - full client summary for coach
const getClientSummary = async (req, res) => {
  try {
    const coachId  = req.user.id;
    const clientId = parseInt(req.params.id);

    // Verify this client belongs to this coach + fetch program dates
    const access = await db.query(
      'SELECT id, program_start_date, program_end_date FROM coach_clients WHERE coach_id = $1 AND participant_id = $2',
      [coachId, clientId]
    );

    if (access.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    // User info + profile
    const userResult = await db.query(
      `SELECT u.id, u.full_name, u.email, u.username, p.*
       FROM users u LEFT JOIN profiles p ON p.user_id = u.id
       WHERE u.id = $1`,
      [clientId]
    );

    // Last 30 days tracking
    const tracking = await db.query(
      `SELECT * FROM daily_tracking
       WHERE user_id = $1 ORDER BY date DESC LIMIT 30`,
      [clientId]
    );

    // Active diet plan
    const dietPlan = await db.query(
      `SELECT dp.*, json_agg(dpm ORDER BY dpm.meal_slot) as meals
       FROM diet_plans dp
       LEFT JOIN diet_plan_meals dpm ON dpm.diet_plan_id = dp.id
       WHERE dp.participant_id = $1 AND dp.is_active = true
       GROUP BY dp.id
       ORDER BY dp.created_at DESC LIMIT 1`,
      [clientId]
    );

    // Active workout plan (summary only — full plan fetched via /workout/get?user_id=)
    const workoutPlan = await db.query(
      `SELECT id, plan_name, total_days, start_date, end_date, created_at
       FROM workout_plans
       WHERE participant_id = $1 AND is_active = true
       ORDER BY created_at DESC LIMIT 1`,
      [clientId]
    );

    // Latest photos
    const photos = await db.query(
      `SELECT DISTINCT ON (photo_type) photo_type, s3_url, uploaded_at
       FROM body_photos WHERE user_id = $1
       ORDER BY photo_type, uploaded_at DESC`,
      [clientId]
    );

    res.json({
      success: true,
      client: {
        ...userResult.rows[0],
        program_start_date: access.rows[0].program_start_date,
        program_end_date:   access.rows[0].program_end_date,
      },
      tracking: tracking.rows,
      diet_plan: dietPlan.rows[0] || null,
      workout_plan: workoutPlan.rows[0] || null,
      photos: photos.rows,
    });
  } catch (err) {
    console.error('Client summary error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

const updateProgramDates = async (req, res) => {
  try {
    const coachId  = req.user.id;
    const clientId = parseInt(req.params.id);
    const { program_start_date, program_end_date } = req.body;
    const result = await db.query(
      `UPDATE coach_clients SET program_start_date = $1, program_end_date = $2
       WHERE coach_id = $3 AND participant_id = $4 RETURNING id`,
      [program_start_date || null, program_end_date || null, coachId, clientId]
    );
    if (result.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error('Update program dates error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/coach/client/:id/goal-tracking — last 14 days of goal completion for a client
const getClientGoalTracking = async (req, res) => {
  try {
    const coachId  = req.user.id;
    const clientId = parseInt(req.params.id);

    // Verify access
    const access = await db.query(
      'SELECT id FROM coach_clients WHERE coach_id = $1 AND participant_id = $2',
      [coachId, clientId]
    );
    if (access.rows.length === 0) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    // Daily tracking for last 14 days
    const tracking = await db.query(
      `SELECT date, steps, water_intake_liters, sleep_hours, stress_level, mood
       FROM daily_tracking
       WHERE user_id = $1
         AND date >= CURRENT_DATE - INTERVAL '13 days'
       ORDER BY date DESC`,
      [clientId]
    );

    // Active lifestyle plan goals
    const lifestyle = await db.query(
      `SELECT lp.id, lp.plan_name,
              json_agg(li ORDER BY li.id) AS items
       FROM lifestyle_plans lp
       LEFT JOIN lifestyle_items li ON li.lifestyle_plan_id = lp.id
       WHERE lp.participant_id = $1 AND lp.is_active = true
       GROUP BY lp.id
       ORDER BY lp.created_at DESC LIMIT 1`,
      [clientId]
    );

    // Client name
    const user = await db.query(
      'SELECT full_name FROM users WHERE id = $1',
      [clientId]
    );

    res.json({
      success: true,
      client_name: user.rows[0]?.full_name ?? '',
      tracking: tracking.rows,
      lifestyle_plan: lifestyle.rows[0] ?? null,
    });
  } catch (err) {
    console.error('Goal tracking error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/coach/clients/available — participants not yet assigned to any coach
const getAvailableClients = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.username, u.full_name
       FROM users u
       WHERE u.role = 'participant'
         AND NOT EXISTS (
           SELECT 1 FROM coach_clients cc WHERE cc.participant_id = u.id
         )
       ORDER BY u.full_name`
    );
    res.json({ success: true, clients: result.rows });
  } catch (err) {
    console.error('Get available clients error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getClients, addClient, getClientSummary, updateProgramDates, getAvailableClients, getClientGoalTracking };
