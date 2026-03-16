// src/routes/meals.js
const express = require('express');
const router  = express.Router();
const { createMeal, listMeals, deleteMeal, calculateMeal } = require('../controllers/mealsController');
const { authenticate } = require('../middleware/auth');

router.post('/create',    authenticate, createMeal);
router.get('/list',       authenticate, listMeals);
router.delete('/:id',     authenticate, deleteMeal);
router.post('/calculate', authenticate, calculateMeal);

module.exports = router;
