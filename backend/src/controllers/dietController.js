// src/controllers/dietController.js
const db = require('../db');

// POST /api/diet/assign  (coach only)
const assignDiet = async (req, res) => {
  try {
    const coachId = req.user.id;
    const { participant_id, plan_name, meals, start_date, end_date } = req.body;
    // meals = [{ meal_slot, calories, protein_g, carbs_g, fat_g }, ...]

    if (!participant_id || !meals || !Array.isArray(meals)) {
      return res.status(400).json({ success: false, message: 'participant_id and meals array required' });
    }

    // Deactivate existing plans
    await db.query(
      'UPDATE diet_plans SET is_active = false WHERE participant_id = $1',
      [participant_id]
    );

    // Create new plan
    const planResult = await db.query(
      `INSERT INTO diet_plans (participant_id, coach_id, plan_name, start_date, end_date)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [participant_id, coachId, plan_name || 'Current Plan', start_date || null, end_date || null]
    );

    const planId = planResult.rows[0].id;

    // Insert meal slots
    for (const meal of meals) {
      await db.query(
        `INSERT INTO diet_plan_meals (diet_plan_id, meal_slot, calories, protein_g, carbs_g, fat_g)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [planId, meal.meal_slot, meal.calories, meal.protein_g, meal.carbs_g, meal.fat_g]
      );
    }

    const fullPlan = await getPlanWithMeals(planId);
    res.status(201).json({ success: true, diet_plan: fullPlan });
  } catch (err) {
    console.error('Assign diet error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/diet/get
const getDiet = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const planResult = await db.query(
      'SELECT id FROM diet_plans WHERE participant_id = $1 AND is_active = true ORDER BY created_at DESC LIMIT 1',
      [targetId]
    );

    if (planResult.rows.length === 0) {
      return res.json({ success: true, diet_plan: null });
    }

    const plan = await getPlanWithMeals(planResult.rows[0].id);
    res.json({ success: true, diet_plan: plan });
  } catch (err) {
    console.error('Get diet error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

async function getPlanWithMeals(planId) {
  const plan = await db.query('SELECT * FROM diet_plans WHERE id = $1', [planId]);
  const meals = await db.query(
    'SELECT * FROM diet_plan_meals WHERE diet_plan_id = $1 ORDER BY meal_slot',
    [planId]
  );
  return { ...plan.rows[0], meals: meals.rows };
}

module.exports = { assignDiet, getDiet };
