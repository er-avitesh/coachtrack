// src/routes/food.js
const express = require('express');
const router  = express.Router();
const { searchFood, logMeal, getMealLog, deleteMealLogEntry } = require('../controllers/foodController');
const { authenticate } = require('../middleware/auth');

router.get('/search',    authenticate, searchFood);
router.post('/log',      authenticate, logMeal);
router.get('/log',       authenticate, getMealLog);
router.delete('/log/:id', authenticate, deleteMealLogEntry);

module.exports = router;
