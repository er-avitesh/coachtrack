const express = require('express');
const router  = express.Router();
const {
  createSeries, updateSeries, deleteSeries,
  createAdhoc, updateAppointment, cancelAppointment,
  getAppointments, getTodayAppointments, getSeriesForClient,
} = require('../controllers/appointmentController');
const { authenticate, requireCoach } = require('../middleware/auth');

// Both roles
router.get('/',       authenticate, getAppointments);
router.get('/today',  authenticate, getTodayAppointments);

// Coach only
router.post('/series',              authenticate, requireCoach, createSeries);
router.patch('/series/:id',         authenticate, requireCoach, updateSeries);
router.delete('/series/:id',        authenticate, requireCoach, deleteSeries);
router.get('/series/client/:client_id', authenticate, requireCoach, getSeriesForClient);
router.post('/adhoc',               authenticate, requireCoach, createAdhoc);
router.patch('/:id',                authenticate, requireCoach, updateAppointment);
router.delete('/:id',               authenticate, requireCoach, cancelAppointment);

module.exports = router;
