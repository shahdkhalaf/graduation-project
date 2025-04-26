// server.js
require('dotenv').config();
const express = require('express');
const mysql = require('mysql');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors()); // allow all origins; adjust as needed

// 1) Set up MySQL connection pool
const db = mysql.createPool({
  host:     process.env.DB_HOST,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  database: process.env.DB_NAME
});

// 2) SIMPLE SIGN‐UP ENDPOINT
app.post('/signup', async (req, res) => {
  const { first_name, last_name, email, password, age, gendar, district } = req.body;
  if (!first_name || !last_name || !email || !password || !age || !gendar || !district) {
    return res.status(400).json({ error: 'All fields are required.' });
  }

  try {
    // Check if user already exists
    db.query(
      'SELECT email FROM `users` WHERE email = ?',
      [email],
      async (err, results) => {
        if (err) {
          console.error(err);
          return res.status(500).json({ error: 'Database error.' });
        }
        if (results.length > 0) {
          return res.status(409).json({ error: 'Email already registered.' });
        }

        // Hash password
        const hashed = await bcrypt.hash(password, 10);

        // Insert new user
        db.query(
          'INSERT INTO `users` (first_name, last_name, email, age, gendar, password, district) VALUES (?, ?, ?, ?, ?, ?, ?)',
          [first_name, last_name, email, age, gendar, hashed, district],
          (err2, result2) => {
            if (err2) {
              console.error(err2);
              return res.status(500).json({ error: 'Database insert error.' });
            }
            return res.status(201).json({ message: 'User created successfully.' });
          }
        );
      }
    );
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Unknown server error.' });
  }
});

// 3) SIMPLE SIGN‐IN ENDPOINT
app.post('/signin', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email and password required.' });
  }

  // Look up user by email
  db.query('SELECT * FROM `users` WHERE email = ?', [email], async (err, results) => {
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

    // (Optional) create a JWT
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

// 4) TEST CONNECTIVITY / HEALTH CHECK
app.get('/health', (req, res) => {
  db.query('SELECT 1 + 1 AS solution', (err) => {
    if (err) return res.status(500).json({ status: 'Database connection failed' });
    return res.json({ status: 'OK' });
  });
});

// 5) START SERVER
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🔥 Auth server listening on port ${PORT}`);
});
