// src/routes/tracking.js
const express = require('express');
const router  = express.Router();
const { addTracking, getTracking, getToday } = require('../controllers/trackingController');
const { authenticate } = require('../middleware/auth');

router.post('/add',   authenticate, addTracking);
router.get('/get',    authenticate, getTracking);
router.get('/today',  authenticate, getToday);

module.exports = router;
