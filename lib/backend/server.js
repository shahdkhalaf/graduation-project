// server.js
require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const app = express();
const path = require('path');
const express = require("express");
const nodemailer = require("nodemailer");
const jwt = require("jsonwebtoken");
require("dotenv").config();
// --- ⬇️ CREATE APP & MIDDLEWARE
const app = express();
app.use(express.json());

const nodemailer = require("nodemailer");

async function sendVerificationEmail(email, link) {
  const transporter = nodemailer.createTransport({
    host: "sandbox.smtp.mailtrap.io",
    port: 2525,
    auth: {
      user: process.env.MAIL_USER,  // ← خزن القيم في .env
      pass: process.env.MAIL_PASS,
    },
  });

  const mailOptions = {
    from: '"Salkah App" <no-reply@salkah.com>',
    to: email,
    subject: "Please verify your email",
    html: `
      <h3>Verify Your Email</h3>
      <p>Click the link below to activate your account:</p>
      <a href="${link}">${link}</a>
      <br /><br />
      <small>This link will expire in 24 hours.</small>
    `,
  };

  await transporter.sendMail(mailOptions);
}
// --- Begin inlined verifyToken middleware ---
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader) return res.sendStatus(401);

  const token = authHeader.split(' ')[1];
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}
// --- End inlined verifyToken middleware ---

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors({
  origin: ['https://graduation-project-production-39f0.up.railway.app'],
  credentials: true,
})); // allow all origins; adjust as needed

// MySQL connection
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});
// Routes
// Signup endpoint
// --- Rate limiting setup ---
const rateLimitMap = new Map(); // { ip: [timestamps] }
const SIGNUP_LIMIT = 5;
const SIGNUP_WINDOW_MS = 10 * 60 * 1000; // 10 minutes

function isRateLimited(ip) {
  const now = Date.now();
  const attempts = rateLimitMap.get(ip) || [];
  // Remove timestamps older than window
  const recentAttempts = attempts.filter(ts => now - ts < SIGNUP_WINDOW_MS);
  rateLimitMap.set(ip, recentAttempts);
  if (recentAttempts.length >= SIGNUP_LIMIT) {
    return true;
  }
  // Add this attempt
  recentAttempts.push(now);
  rateLimitMap.set(ip, recentAttempts);
  return false;
}

app.post("/signup", async (req, res) => {
  const { first_name, last_name, email, password, age, gendar, district } = req.body;

  // 1. Hash the password, validate, etc...

  // 2. Save the user to DB
  const [result] = await db.execute(
    'INSERT INTO users (first_name, last_name, email, password, age, gendar, district, is_verified) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [first_name, last_name, email, hashedPassword, age, gendar, district, false]
  );

  // 3. Generate email verification token
  const verificationToken = jwt.sign(
    { email: email },
    process.env.JWT_SECRET,
    { expiresIn: '1h' }
  );

  // 4. Construct email verification link
  const verifyUrl = `https://yourdomain.com/verify?token=${verificationToken}`;

  // 5. Send email (you need a mailer function)
  await sendVerificationEmail(email, verifyUrl); // ⬅️ إنت بتنفذ دي بنفسك

  res.status(201).json({
    message: "Signup successful. Please verify your email.",
    user: {
      user_id: result.insertId,
      email,
    },
  });
});

// Signin endpoint
app.post('/signin', (req, res) => {
  const { email, password } = req.body;

  if (!email || typeof password !== 'string' || password.trim() === '') {
    return res.status(400).json({ error: 'Email and password are required.' });
  }

  db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
    if (err) {
      console.error("❌ DB error on /signin:", err);
      return res.status(500).json({ error: 'Something went wrong, please try again later.' });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const user = results[0];
    const isPasswordMatch = await bcrypt.compare(password, user.password);

    if (!isPasswordMatch) {
      return res.status(401).json({ error: 'Invalid email or password.' });
    }

    const token = jwt.sign(
      { user_id: user.user_id, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({
      message: 'Login successful',
      token,
      user: {
        user_id: user.user_id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        age: user.age,
        gendar: user.gendar,
        district: user.district
      }
    });
  });
});
// Get user info endpoint
app.post('/get_user', verifyToken, (req, res) => {
  const email = req.body?.email;

  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }

  if (req.user.email !== email) {
    return res.status(403).json({ error: 'Unauthorized access to user data.' });
  }

  db.query(
    'SELECT user_id, first_name, last_name, email, age, gendar, district FROM users WHERE email = ?',
    [email],
    (err, results) => {
      if (err) {
        console.error(err);
        return res.status(500).json({ error: 'Database error.' });
      }
      if (results.length === 0) {
        return res.status(404).json({ error: 'User not found.' });
      }

      const user = results[0];
      return res.json({
        success: true,
        user: {
          user_id: user.user_id,
          first_name: user.first_name,
          last_name: user.last_name,
          email: user.email,
          age: user.age,
          gendar: user.gendar,
          district: user.district
        }
      });
    }
  );
});
/////////1️⃣ API → send_tracking_request
app.post('/send_tracking_request', verifyToken, (req, res) => {
  const from = req.user.user_id;  // من JWT
  const { to_user_id } = req.body;

  if (!to_user_id) {
    return res.status(400).json({ error: 'to_user_id is required.' });
  }

  const to = parseInt(to_user_id);
  if (isNaN(to)) {
    return res.status(400).json({ error: 'Invalid to_user_id. Must be an integer.' });
  }

  if (from === to) {
    return res.status(400).json({ error: 'You cannot track yourself.' });
  }

  // Check for existing pending request
  const checkSql = 'SELECT * FROM user_request_tracking WHERE from_user_id = ? AND to_user_id = ? AND Status = 0';
  db.query(checkSql, [from, to], (checkErr, checkResults) => {
    if (checkErr) {
      return res.status(500).json({ error: 'Database error.', details: checkErr.message });
    }
    if (checkResults.length > 0) {
      return res.status(409).json({ error: 'Request already sent and pending.' });
    }

    console.log(`📥 New tracking request from ${from} to ${to}`);

    const sql = `
      INSERT INTO user_request_tracking(from_user_id, to_user_id, status)
      VALUES (?, ?, 0)
    `;

    db.query(sql, [from, to], (err, result) => {
      if (err) {
        console.error("🔥 DB error in /send_tracking_request:", err?.sqlMessage || err.message || err);
        return res.status(500).json({ error: 'Database error.', details: err.message });
      }

      return res.status(201).json({ message: 'Tracking request sent successfully.' });
    });
  });
});
//////////2️⃣ API → check_tracking_requests
app.get('/check_tracking_requests', verifyToken, (req, res) => {
  const userId = req.user.user_id;  // جاي من التوكن الموثوق

  const sql = `
    SELECT Log_ID, from_user_id, to_user_id, Status
    FROM user_request_tracking
    WHERE to_user_id = ? AND (Status = 0 OR Status = 1);
  `;

  db.query(sql, [userId], (err, results) => {
    if (err) {
      console.error("❌ Error in check_tracking_requests:", err);
      return res.status(500).json({ error: 'Database error.' });
    }

    const formattedResults = results.map(row => ({
      log_id: row.Log_ID,
      from_user_id: row.from_user_id,
      to_user_id: row.to_user_id,
      status: row.Status
    }));

    return res.json({ requests: formattedResults });
  });
});
///////////3️⃣ API → update_tracking_request
app.post('/update_tracking_request', verifyToken, (req, res) => {
  const currentUserId = req.user.user_id; // ده الشخص اللي سجل دخول فعليًا
  const { from_user_id, status } = req.body;

  if (!from_user_id || status === undefined) {
    return res.status(400).json({ error: 'from_user_id and status are required.' });
  }

  const sql = `
    UPDATE user_request_tracking
    SET Status = ?
    WHERE from_user_id = ? AND to_user_id = ? AND Status = 0
  `;

  db.query(sql, [status, from_user_id, currentUserId], (err, result) => {
    if (err) {
      console.error("❌ Error updating tracking request:", err);
      return res.status(500).json({ error: 'Database error.' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'No pending request found.' });
    }

    return res.json({ message: 'Tracking request updated successfully.' });
  });
});
// 4️⃣ API → receive live location
app.post('/send_location', verifyToken, (req, res) => {
  const userIdFromToken = req.user.user_id;
  const { to_user_id, latitude, longitude } = req.body;

  if (!to_user_id || !latitude || !longitude) {
    return res.status(400).json({ error: 'Missing location data.' });
  }

  const insertSql = `
    INSERT INTO user_location_tracking (from_user_id, to_user_id, latitude, longitude, timestamp)
    VALUES (?, ?, ?, ?, NOW())
  `;

  const updateSql = `
    UPDATE location SET lat = ?, lng = ? WHERE user_id = ?
  `;

  // 1. Save full tracking history
  db.query(insertSql, [userIdFromToken, to_user_id, latitude, longitude], (insertErr) => {
    if (insertErr) {
      console.error("❌ Error inserting into user_location_tracking:", insertErr);
      return res.status(500).json({ error: 'Insert error.' });
    }

    // 2. Update current location
    db.query(updateSql, [latitude, longitude, userIdFromToken], (updateErr) => {
      if (updateErr) {
        console.error("❌ Error updating location table:", updateErr);
        return res.status(500).json({ error: 'Update error.' });
      }

      return res.status(201).json({ message: 'Location saved successfully.' });
    });
  });
});
// ✅ API 5: Get latest location of a user (for live tracking)
app.get('/get_latest_location', verifyToken, (req, res) => {
  const to_user_id = req.user.user_id;

  const sql = `
    SELECT from_user_id, to_user_id, latitude, longitude, timestamp
    FROM user_location_tracking
    WHERE to_user_id = ?
    ORDER BY timestamp DESC
    LIMIT 1;
  `;

  db.query(sql, [to_user_id], (err, results) => {
    if (err) {
      console.error('❌ Error fetching latest location:', err);
      return res.status(500).json({ error: 'Database error.' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: 'No location found for user.' });
    }

    return res.json({ latest: results[0] });
  });
});
// ✅ API 6: Get route price from database
app.get('/get_price', verifyToken, (req, res) => {
  const { from, to } = req.query;

  if (!from || !to) {
    return res.status(400).json({ error: 'Both "from" and "to" parameters are required.' });
  }

  const sql = 'SELECT Cost FROM routes_table WHERE `From` = ? AND `To` = ? LIMIT 1';

  db.query(sql, [from, to], (err, results) => {
    if (err) {
      console.error('❌ Error in /get_price:', err);
      return res.status(500).json({ error: 'Database error.' });
    }

    if (results.length === 0) {
      return res.status(404).json({ price: 'Route not found' });
    }

    return res.json({ price: `${results[0].Cost} EGP` });
  });
});
/////////// API 7: send_verification_email
app.post('/send_verification_email', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
  }

  try {
    const token = jwt.sign({ email }, process.env.JWT_SECRET, { expiresIn: '24h' });
    const verificationLink = `https://your-frontend-app.com/verify?token=${token}`;

    await sendVerificationEmail(email, verificationLink);

    return res.status(200).json({ message: 'Verification email sent.' });
  } catch (err) {
    console.error('❌ Error sending verification email:', err);
    return res.status(500).json({ error: 'Failed to send verification email.' });
  }
});

// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🔥 Auth server listening on port ${PORT}`);
});