// src/controllers/mealsController.js
const db = require('../db');

// POST /api/meals/create
const createMeal = async (req, res) => {
  try {
    const userId = req.user.id;
    const { meal_name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g } = req.body;

    if (!meal_name || !calories_per_100g) {
      return res.status(400).json({ success: false, message: 'meal_name and calories_per_100g required' });
    }

    const result = await db.query(
      `INSERT INTO meals (user_id, meal_name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
      [userId, meal_name, calories_per_100g, protein_per_100g || 0, carbs_per_100g || 0, fat_per_100g || 0]
    );

    res.status(201).json({ success: true, meal: result.rows[0] });
  } catch (err) {
    console.error('Create meal error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/meals/list
const listMeals = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM meals WHERE user_id = $1 ORDER BY meal_name ASC',
      [req.user.id]
    );
    res.json({ success: true, meals: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// DELETE /api/meals/:id
const deleteMeal = async (req, res) => {
  try {
    await db.query(
      'DELETE FROM meals WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    res.json({ success: true, message: 'Meal deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/meals/calculate
// Body: { meal_id, target_calories }
// Returns: { grams_needed, nutrition_breakdown }
const calculateMeal = async (req, res) => {
  try {
    const { meal_id, target_calories } = req.body;

    if (!meal_id || !target_calories) {
      return res.status(400).json({ success: false, message: 'meal_id and target_calories required' });
    }

    const result = await db.query(
      'SELECT * FROM meals WHERE id = $1',
      [meal_id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Meal not found' });
    }

    const meal = result.rows[0];
    const gramsNeeded = (target_calories / meal.calories_per_100g) * 100;

    const nutrition = {
      grams_needed: Math.round(gramsNeeded),
      calories: Math.round(target_calories),
      protein_g: Math.round((meal.protein_per_100g / 100) * gramsNeeded * 10) / 10,
      carbs_g:   Math.round((meal.carbs_per_100g   / 100) * gramsNeeded * 10) / 10,
      fat_g:     Math.round((meal.fat_per_100g     / 100) * gramsNeeded * 10) / 10,
    };

    res.json({ success: true, meal_name: meal.meal_name, nutrition });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { createMeal, listMeals, deleteMeal, calculateMeal };
