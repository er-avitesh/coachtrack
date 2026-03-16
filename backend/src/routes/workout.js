// src/routes/workout.js
const express = require('express');
const router  = express.Router();
const { listExercises, assignWorkout, getWorkout } = require('../controllers/workoutController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.get('/exercises', authenticate, listExercises);
router.post('/assign',   authenticate, requireCoach, assignWorkout);
router.get('/get',       authenticate, getWorkout);

module.exports = router;
