// src/controllers/photosController.js
const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const db = require('../db');

const s3 = new S3Client({
  region: process.env.AWS_REGION || 'ap-south-1',
  credentials: {
    accessKeyId:     process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const BUCKET = process.env.AWS_S3_BUCKET;

// GET /api/photos/upload-url?type=front|side|back
// Returns a presigned S3 URL the client can PUT directly
const getUploadUrl = async (req, res) => {
  try {
    const { type } = req.query;
    if (!['front', 'side', 'back'].includes(type)) {
      return res.status(400).json({ success: false, message: 'type must be front, side, or back' });
    }

    const key = `photos/${req.user.id}/${type}/${Date.now()}.jpg`;

    const command = new PutObjectCommand({
      Bucket:      BUCKET,
      Key:         key,
      ContentType: 'image/jpeg',
    });

    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 }); // 5 min

    res.json({ success: true, upload_url: uploadUrl, key });
  } catch (err) {
    console.error('Get upload URL error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// POST /api/photos/confirm
// After client uploads to S3, they call this to save the record
const confirmUpload = async (req, res) => {
  try {
    const { photo_type, s3_key } = req.body;

    if (!photo_type || !s3_key) {
      return res.status(400).json({ success: false, message: 'photo_type and s3_key required' });
    }

    const s3_url = `https://${BUCKET}.s3.${process.env.AWS_REGION || 'ap-south-1'}.amazonaws.com/${s3_key}`;

    const result = await db.query(
      `INSERT INTO body_photos (user_id, photo_type, s3_url, s3_key)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, photo_type, s3_url, s3_key]
    );

    res.json({ success: true, photo: result.rows[0] });
  } catch (err) {
    console.error('Confirm upload error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/photos/list
const listPhotos = async (req, res) => {
  try {
    const targetId = (req.user.role === 'coach' && req.query.user_id)
      ? parseInt(req.query.user_id)
      : req.user.id;

    const result = await db.query(
      `SELECT DISTINCT ON (photo_type) photo_type, s3_url, uploaded_at
       FROM body_photos WHERE user_id = $1
       ORDER BY photo_type, uploaded_at DESC`,
      [targetId]
    );

    res.json({ success: true, photos: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { getUploadUrl, confirmUpload, listPhotos };
