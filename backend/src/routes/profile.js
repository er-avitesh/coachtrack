// src/routes/profile.js
const express = require('express');
const router  = express.Router();
const { createOrUpdate, getProfile } = require('../controllers/profileController');
const { authenticate } = require('../middleware/auth');

router.post('/create', authenticate, createOrUpdate);
router.get('/get',     authenticate, getProfile);

module.exports = router;
