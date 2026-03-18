// src/server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const authRoutes     = require('./routes/auth');
const profileRoutes  = require('./routes/profile');
const trackingRoutes = require('./routes/tracking');
const mealRoutes     = require('./routes/meals');
const dietRoutes     = require('./routes/diet');
const workoutRoutes  = require('./routes/workout');
const tipsRoutes     = require('./routes/tips');
const photoRoutes    = require('./routes/photos');
const coachRoutes     = require('./routes/coach');
const lifestyleRoutes = require('./routes/lifestyle');

const app = express();

// ── Middleware ────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Routes ────────────────────────────────────────────────
app.use('/api/auth',     authRoutes);
app.use('/api/profile',  profileRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api/meals',    mealRoutes);
app.use('/api/diet',     dietRoutes);
app.use('/api/workout',  workoutRoutes);
app.use('/api/tips',     tipsRoutes);
app.use('/api/photos',   photoRoutes);
app.use('/api/coach',     coachRoutes);
app.use('/api/lifestyle', lifestyleRoutes);

// ── Health check ──────────────────────────────────────────
app.get('/health', (req, res) => res.json({ status: 'ok', timestamp: new Date() }));

// ── Global error handler ──────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 CoachTrack API running on port ${PORT}`);
});
