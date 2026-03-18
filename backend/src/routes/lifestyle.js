const express = require('express');
const router  = express.Router();
const { assignLifestyle, getLifestyle } = require('../controllers/lifestyleController');
const { authenticate, requireCoach } = require('../middleware/auth');

router.post('/assign', authenticate, requireCoach, assignLifestyle);
router.get('/get',     authenticate, getLifestyle);

module.exports = router;
