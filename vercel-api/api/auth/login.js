const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const db = require('../../lib/database');

export default async function handler(req, res) {
  // Handle CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ 
      success: false, 
      error: 'Method not allowed. Use POST.' 
    });
  }

  try {
    const { phoneNumber, password } = req.body;

    // Validation
    if (!phoneNumber || !password) {
      return res.status(400).json({
        success: false,
        error: 'Phone number and password are required'
      });
    }

    // Query user from database
    const sql = `
      SELECT id, name, phoneNumber, email, role, password, countryId 
      FROM SalesRep 
      WHERE phoneNumber = ?
    `;
    
    const users = await db.query(sql, [phoneNumber]);
    
    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    const user = users[0];

    // Secure password check with bcrypt
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }

    // Generate JWT tokens
    const accessToken = jwt.sign(
      { 
        userId: user.id, 
        phoneNumber: user.phoneNumber,
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '12h' }  // 12 hours - convenient for full work day
    );

    const refreshToken = jwt.sign(
      { 
        userId: user.id,
        type: 'refresh'
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }  // 30 days - remember login for a month
    );

    // Store refresh token in database
    await db.query(
      'INSERT INTO Token (token, salesRepId, expiresAt, tokenType) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 7 DAY), ?)',
      [refreshToken, user.id, 'refresh']
    );

    // Remove password from response
    const { password: _, ...userWithoutPassword } = user;

    res.status(200).json({
      success: true,
      salesRep: userWithoutPassword,
      user: userWithoutPassword, // Alternative field your app might expect
      accessToken,
      refreshToken,
      expiresIn: 43200, // 12 hours in seconds
      message: 'Login successful'
    });

  } catch (error) {
    console.error('❌ Login error:', error);
    
    res.status(500).json({
      success: false,
      error: 'Login failed'
    });
  }
} 