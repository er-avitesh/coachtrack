// src/middleware/auth.js
const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer <token>

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, username, role }
    next();
  } catch (err) {
    return res.status(401).json({ success: false, message: 'Invalid or expired token' });
  }
};

const requireCoach = (req, res, next) => {
  if (req.user.role !== 'coach') {
    return res.status(403).json({ success: false, message: 'Coach access required' });
  }
  next();
};

const requireParticipant = (req, res, next) => {
  if (req.user.role !== 'participant') {
    return res.status(403).json({ success: false, message: 'Participant access required' });
  }
  next();
};

module.exports = { authenticate, requireCoach, requireParticipant };
