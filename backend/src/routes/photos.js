// src/routes/photos.js
const express = require('express');
const router  = express.Router();
const { getUploadUrl, confirmUpload, listPhotos } = require('../controllers/photosController');
const { authenticate } = require('../middleware/auth');

router.get('/upload-url', authenticate, getUploadUrl);
router.post('/confirm',   authenticate, confirmUpload);
router.get('/list',       authenticate, listPhotos);

module.exports = router;
