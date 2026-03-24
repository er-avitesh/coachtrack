// src/routes/workout.js
const express = require('express');
const router  = express.Router();
const { listExercises, assignWorkout, getWorkout, updateExerciseVideo, saveSession, getHistory } = require('../controllers/workoutController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.get('/exercises',              authenticate,              listExercises);
router.post('/assign',                authenticate, requireCoach, assignWorkout);
router.get('/get',                    authenticate,              getWorkout);
router.patch('/exercises/:id/video',  authenticate, requireCoach, updateExerciseVideo);
router.post('/sessions',              authenticate,              saveSession);
router.get('/history',                authenticate,              getHistory);

module.exports = router;
