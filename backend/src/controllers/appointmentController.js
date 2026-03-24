const db = require('../db');

// ── Helpers ────────────────────────────────────────────────────────────────

// Generate recurring appointment dates for next N weeks starting from next occurrence
function nextOccurrences(dayOfWeek, timeOfDay, weeksAhead = 8) {
  const dates = [];
  const now = new Date();
  const [h, m] = timeOfDay.split(':').map(Number);

  // Find the next occurrence of dayOfWeek from today
  const next = new Date(now);
  next.setHours(h, m, 0, 0);
  const diff = (dayOfWeek - now.getDay() + 7) % 7;
  next.setDate(now.getDate() + (diff === 0 && next <= now ? 7 : diff));

  for (let i = 0; i < weeksAhead; i++) {
    const d = new Date(next);
    d.setDate(next.getDate() + i * 7);
    dates.push(new Date(d));
  }
  return dates;
}

// ── Coach: create weekly series ────────────────────────────────────────────
async function createSeries(req, res) {
  const coachId = req.user.id;
  const { client_id, title, day_of_week, time_of_day, duration_minutes } = req.body;

  if (day_of_week === undefined || !time_of_day || !client_id) {
    return res.status(400).json({ success: false, message: 'client_id, day_of_week and time_of_day are required' });
  }

  // Verify coach-client relationship
  const rel = await db.query(
    'SELECT id FROM coach_clients WHERE coach_id=$1 AND participant_id=$2',
    [coachId, client_id]
  );
  if (!rel.rows.length) {
    return res.status(403).json({ success: false, message: 'This client is not assigned to you' });
  }

  const seriesTitle = title || 'Weekly Connect';
  const duration = duration_minutes || 30;

  // Upsert series (replace if already exists for this pair)
  const existing = await db.query(
    'SELECT id FROM appointment_series WHERE coach_id=$1 AND client_id=$2',
    [coachId, client_id]
  );

  let seriesId;
  if (existing.rows.length) {
    seriesId = existing.rows[0].id;
    await db.query(
      `UPDATE appointment_series
       SET title=$1, day_of_week=$2, time_of_day=$3, duration_minutes=$4, is_active=true
       WHERE id=$5`,
      [seriesTitle, day_of_week, time_of_day, duration, seriesId]
    );
    // Cancel all future unmodified recurring appointments for this series
    await db.query(
      `UPDATE appointments SET status='cancelled'
       WHERE series_id=$1 AND scheduled_at > NOW() AND is_exception=false AND status='scheduled'`,
      [seriesId]
    );
  } else {
    const s = await db.query(
      `INSERT INTO appointment_series (coach_id, client_id, title, day_of_week, time_of_day, duration_minutes)
       VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
      [coachId, client_id, seriesTitle, day_of_week, time_of_day, duration]
    );
    seriesId = s.rows[0].id;
  }

  // Generate next 8 weeks of occurrences
  const dates = nextOccurrences(day_of_week, time_of_day, 8);
  for (const d of dates) {
    await db.query(
      `INSERT INTO appointments (coach_id, client_id, series_id, title, type, scheduled_at, duration_minutes)
       VALUES ($1,$2,$3,$4,'recurring',$5,$6)`,
      [coachId, client_id, seriesId, seriesTitle, d.toISOString(), duration]
    );
  }

  res.json({ success: true, message: 'Weekly series created', series_id: seriesId });
}

// ── Coach: reschedule entire series ───────────────────────────────────────
async function updateSeries(req, res) {
  const coachId = req.user.id;
  const { id } = req.params;
  const { day_of_week, time_of_day, duration_minutes, title } = req.body;

  const series = await db.query(
    'SELECT * FROM appointment_series WHERE id=$1 AND coach_id=$2',
    [id, coachId]
  );
  if (!series.rows.length) return res.status(404).json({ success: false, message: 'Series not found' });

  const s = series.rows[0];
  const newDay  = day_of_week      ?? s.day_of_week;
  const newTime = time_of_day      ?? s.time_of_day;
  const newDur  = duration_minutes ?? s.duration_minutes;
  const newTitle = title           ?? s.title;

  await db.query(
    `UPDATE appointment_series SET day_of_week=$1, time_of_day=$2, duration_minutes=$3, title=$4 WHERE id=$5`,
    [newDay, newTime, newDur, newTitle, id]
  );

  // Cancel all future non-exception recurring appointments
  await db.query(
    `UPDATE appointments SET status='cancelled'
     WHERE series_id=$1 AND scheduled_at > NOW() AND is_exception=false AND status='scheduled'`,
    [id]
  );

  // Regenerate next 8 weeks
  const dates = nextOccurrences(newDay, newTime, 8);
  for (const d of dates) {
    await db.query(
      `INSERT INTO appointments (coach_id, client_id, series_id, title, type, scheduled_at, duration_minutes)
       VALUES ($1,$2,$3,$4,'recurring',$5,$6)`,
      [coachId, s.client_id, id, newTitle, d.toISOString(), newDur]
    );
  }

  res.json({ success: true, message: 'Series rescheduled' });
}

// ── Coach: cancel entire series ────────────────────────────────────────────
async function deleteSeries(req, res) {
  const coachId = req.user.id;
  const { id } = req.params;

  const series = await db.query(
    'SELECT id FROM appointment_series WHERE id=$1 AND coach_id=$2',
    [id, coachId]
  );
  if (!series.rows.length) return res.status(404).json({ success: false, message: 'Series not found' });

  await db.query(
    `UPDATE appointments SET status='cancelled'
     WHERE series_id=$1 AND scheduled_at > NOW() AND status='scheduled'`,
    [id]
  );
  await db.query('UPDATE appointment_series SET is_active=false WHERE id=$1', [id]);

  res.json({ success: true, message: 'Series cancelled' });
}

// ── Coach: create adhoc appointment ───────────────────────────────────────
async function createAdhoc(req, res) {
  const coachId = req.user.id;
  const { client_id, title, scheduled_at, duration_minutes, notes } = req.body;

  if (!client_id || !scheduled_at) {
    return res.status(400).json({ success: false, message: 'client_id and scheduled_at are required' });
  }

  const rel = await db.query(
    'SELECT id FROM coach_clients WHERE coach_id=$1 AND participant_id=$2',
    [coachId, client_id]
  );
  if (!rel.rows.length) return res.status(403).json({ success: false, message: 'Client not assigned to you' });

  const result = await db.query(
    `INSERT INTO appointments (coach_id, client_id, title, type, scheduled_at, duration_minutes, notes)
     VALUES ($1,$2,$3,'adhoc',$4,$5,$6) RETURNING *`,
    [coachId, client_id, title || 'Ad-hoc Call', scheduled_at, duration_minutes || 30, notes || null]
  );

  res.json({ success: true, appointment: result.rows[0] });
}

// ── Coach: reschedule single occurrence ───────────────────────────────────
async function updateAppointment(req, res) {
  const coachId = req.user.id;
  const { id } = req.params;
  const { scheduled_at, duration_minutes, notes, title } = req.body;

  const appt = await db.query(
    'SELECT * FROM appointments WHERE id=$1 AND coach_id=$2',
    [id, coachId]
  );
  if (!appt.rows.length) return res.status(404).json({ success: false, message: 'Appointment not found' });

  await db.query(
    `UPDATE appointments
     SET scheduled_at=COALESCE($1,scheduled_at),
         duration_minutes=COALESCE($2,duration_minutes),
         notes=COALESCE($3,notes),
         title=COALESCE($4,title),
         is_exception=true
     WHERE id=$5`,
    [scheduled_at, duration_minutes, notes, title, id]
  );

  res.json({ success: true, message: 'Appointment rescheduled' });
}

// ── Coach: cancel single occurrence ───────────────────────────────────────
async function cancelAppointment(req, res) {
  const coachId = req.user.id;
  const { id } = req.params;

  const appt = await db.query(
    'SELECT id FROM appointments WHERE id=$1 AND coach_id=$2',
    [id, coachId]
  );
  if (!appt.rows.length) return res.status(404).json({ success: false, message: 'Appointment not found' });

  await db.query('UPDATE appointments SET status=$1 WHERE id=$2', ['cancelled', id]);
  res.json({ success: true, message: 'Appointment cancelled' });
}

// ── Get my appointments (coach or client) ─────────────────────────────────
async function getAppointments(req, res) {
  const userId = req.user.id;
  const isCoach = req.user.role === 'coach';
  const { from, to } = req.query;

  const fromDate = from || new Date().toISOString();
  const toDate   = to   || new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(); // 60 days

  const col = isCoach ? 'coach_id' : 'client_id';
  const otherCol = isCoach ? 'client_id' : 'coach_id';

  const result = await db.query(
    `SELECT a.*,
            u.full_name AS other_name,
            u.username  AS other_username,
            s.day_of_week, s.time_of_day
     FROM appointments a
     JOIN users u ON u.id = a.${otherCol}
     LEFT JOIN appointment_series s ON s.id = a.series_id
     WHERE a.${col} = $1
       AND a.scheduled_at BETWEEN $2 AND $3
       AND a.status = 'scheduled'
     ORDER BY a.scheduled_at ASC`,
    [userId, fromDate, toDate]
  );

  res.json({ success: true, appointments: result.rows });
}

// ── Today's appointments ───────────────────────────────────────────────────
async function getTodayAppointments(req, res) {
  const userId = req.user.id;
  const isCoach = req.user.role === 'coach';
  const col = isCoach ? 'coach_id' : 'client_id';
  const otherCol = isCoach ? 'client_id' : 'coach_id';

  const result = await db.query(
    `SELECT a.*,
            u.full_name AS other_name,
            u.username  AS other_username
     FROM appointments a
     JOIN users u ON u.id = a.${otherCol}
     WHERE a.${col} = $1
       AND a.scheduled_at::date = CURRENT_DATE
       AND a.status = 'scheduled'
     ORDER BY a.scheduled_at ASC`,
    [userId]
  );

  res.json({ success: true, appointments: result.rows });
}

// ── Get series for a client (coach only) ──────────────────────────────────
async function getSeriesForClient(req, res) {
  const coachId = req.user.id;
  const { client_id } = req.params;

  const result = await db.query(
    `SELECT * FROM appointment_series
     WHERE coach_id=$1 AND client_id=$2 AND is_active=true`,
    [coachId, client_id]
  );

  res.json({ success: true, series: result.rows[0] || null });
}

module.exports = {
  createSeries,
  updateSeries,
  deleteSeries,
  createAdhoc,
  updateAppointment,
  cancelAppointment,
  getAppointments,
  getTodayAppointments,
  getSeriesForClient,
};
