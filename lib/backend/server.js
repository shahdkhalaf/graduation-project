// server.js
require('dotenv').config();
const express = require('express');
const mysql = require('mysql2');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();

// Middlewares
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cors()); // allow all origins; adjust as needed

// MySQL connection
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

// Routes

// Health check
app.get('/health', (req, res) => {
  console.log("Trying to connect with:", {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME
  });

  db.query('SELECT 1 + 1 AS solution', (err, results) => {
    if (err) {
      console.error("❌ Error connecting to DB:", err);
      return res.status(500).json({ status: 'Database connection failed', error: err });
    }
    return res.json({ status: 'OK' });
  });
});

// Signup endpoint
app.post('/signup', async (req, res) => {
  const { first_name, last_name, email, password, age, gendar, district } = req.body;
  if (!first_name || !last_name || !email || !password || !age || !gendar || !district) {
    return res.status(400).json({ error: 'All fields are required.' });
  }

  try {
    db.query(
      'SELECT email FROM users WHERE email = ?',
      [email],
      async (err, results) => {
        if (err) {
          console.error(err);
          return res.status(500).json({ error: 'Database error.', details: err.message });

        }
        if (results.length > 0) {
          return res.status(409).json({ error: 'Email already registered.' });
        }

        const hashed = await bcrypt.hash(password, 10);

        db.query(
          'INSERT INTO users (first_name, last_name, email, age, gendar, password, district) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [first_name, last_name, email, age, gendar, hashed, district],
          (err2, result2) => {
            if (err2) {
              console.error(err2);
              return res.status(500).json({ error: 'Database insert error.' });
            }

            // Get inserted user_id:
            const newUserId = result2.insertId;

            return res.status(201).json({
              message: 'User created successfully.',
              user: {
                user_id: newUserId
              }
            });
          }
        );
      }
    );
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Unknown server error.' });
  }
});

// Signin endpoint
app.post('/signin', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required.' });
  }

  db.query('SELECT * FROM users WHERE email = ?', [email], async (err, results) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Database error.' });
    }
    if (results.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials.' });
    }

    const user = results[0];
    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({ error: 'Invalid credentials.' });
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
app.post('/get_user', (req, res) => {
  console.log('Received request on /get_user', req.body);
const email = req.body?.email || req.body?.['email'];

if (!email) {
  return res.status(400).json({ error: 'Email is required.', details: req.body });
}

  if (!email) {
    return res.status(400).json({ error: 'Email is required.' });
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
app.post('/send_tracking_request', (req, res) => {
  const { from_user_id, to_user_id } = req.body;

  if (!from_user_id || !to_user_id) {
    return res.status(400).json({ error: 'Both from_user_id and to_user_id are required.' });
  }

  const sql =
    'INSERT INTO user_request_tracking(from_user_id, to_user_id, status) VALUES (?, ?, ?);'

  db.query(sql, [from_user_id, to_user_id, 0], (err, result) => {
    if (err) {
      console.error("🔥 Database error in /send_tracking_request:", err);  // ← هنا هيطبع ال error الحقيقي
      return res.status(500).json({ error: 'Database error.', details: err.message });
    }

    return res.status(201).json({ message: 'Tracking request sent successfully.' });
  });
});
//////////2️⃣ API → check_tracking_requests
app.get('/check_tracking_requests', (req, res) => {
  const { user_id } = req.query;

  if (!user_id) {
    return res.status(400).json({ error: 'user_id is required.' });
  }

  const sql ='SELECT Log_ID, from_user_id, to_user_id, Status FROM user_request_tracking WHERE to_user_id = ? AND Status = 0;'

  db.query(sql, [user_id], (err, results) => {
    if (err) {
      console.error(err);
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
app.post('/update_tracking_request', (req, res) => {
  const { from_user_id, to_user_id, status } = req.body;

  if (!from_user_id || !to_user_id || status === undefined) {
    return res.status(400).json({ error: 'from_user_id, to_user_id, and status are required.' });
  }

  const sql = 'UPDATE user_request_tracking SET Status = ? WHERE from_user_id = ? AND to_user_id = ? AND Status = 0'
  ;

  db.query(sql, [status, from_user_id, to_user_id], (err, result) => {
    if (err) {
      console.error(err);
      return res.status(500).json({ error: 'Database error.' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'No pending request found.' });
    }

    return res.json({ message: 'Tracking request updated successfully.' });
  });
});
////////////
// Start server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`🔥 Auth server listening on port ${PORT}`);
});