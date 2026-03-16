// src/routes/coach.js
const express = require('express');
const router  = express.Router();
const { getClients, addClient, getClientSummary } = require('../controllers/coachController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.get('/clients',          authenticate, requireCoach, getClients);
router.post('/clients/add',     authenticate, requireCoach, addClient);
router.get('/client/:id/summary', authenticate, requireCoach, getClientSummary);

module.exports = router;
