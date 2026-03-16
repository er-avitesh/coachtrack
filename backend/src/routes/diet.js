// src/routes/diet.js
const express = require('express');
const router  = express.Router();
const { assignDiet, getDiet } = require('../controllers/dietController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.post('/assign', authenticate, requireCoach, assignDiet);
router.get('/get',     authenticate, getDiet);

module.exports = router;
