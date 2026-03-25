// src/routes/coach.js
const express = require('express');
const router  = express.Router();
const { getClients, addClient, getClientSummary, updateProgramDates, getAvailableClients, getClientGoalTracking } = require('../controllers/coachController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.get('/clients',                authenticate, requireCoach, getClients);
router.get('/clients/available',      authenticate, requireCoach, getAvailableClients);
router.post('/clients/add',           authenticate, requireCoach, addClient);
router.get('/client/:id/summary',        authenticate, requireCoach, getClientSummary);
router.get('/client/:id/goal-tracking',  authenticate, requireCoach, getClientGoalTracking);
router.patch('/client/:id/program-dates', authenticate, requireCoach, updateProgramDates);

module.exports = router;
