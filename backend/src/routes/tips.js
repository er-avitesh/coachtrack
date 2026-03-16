// src/routes/tips.js
const express = require('express');
const router  = express.Router();
const { addTip, getTips } = require('../controllers/tipsController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.post('/add', authenticate, requireCoach, addTip);
router.get('/get',  authenticate, getTips);

module.exports = router;
