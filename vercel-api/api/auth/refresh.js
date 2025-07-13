const jwt = require('jsonwebtoken');
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
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        error: 'Refresh token is required'
      });
    }

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_SECRET);
    } catch (error) {
      return res.status(401).json({
        success: false,
        error: 'Invalid refresh token'
      });
    }

    // Check if token exists in database and is not expired
    const tokenCheck = await db.query(
      `SELECT t.*, sr.id, sr.name, sr.phoneNumber, sr.email, sr.role, sr.countryId 
       FROM Token t 
       JOIN SalesRep sr ON t.salesRepId = sr.id 
       WHERE t.token = ? AND t.tokenType = 'refresh' AND t.expiresAt > NOW() AND (t.blacklisted = 0 OR t.blacklisted IS NULL)`,
      [refreshToken]
    );

    if (tokenCheck.length === 0) {
      return res.status(401).json({
        success: false,
        error: 'Refresh token not found or expired'
      });
    }

    const user = tokenCheck[0];

    // Generate new access token
    const newAccessToken = jwt.sign(
      { 
        userId: user.id, 
        phoneNumber: user.phoneNumber,
        role: user.role 
      },
      process.env.JWT_SECRET,
      { expiresIn: '12h' }
    );

    // Update token last used time
    await db.query(
      'UPDATE Token SET lastUsedAt = NOW() WHERE token = ?',
      [refreshToken]
    );

    res.status(200).json({
      success: true,
      accessToken: newAccessToken,
      expiresIn: 43200, // 12 hours in seconds
      user: {
        id: user.id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        email: user.email,
        role: user.role,
        countryId: user.countryId
      },
      message: 'Token refreshed successfully'
    });

  } catch (error) {
    console.error('❌ Token refresh error:', error);
    
    res.status(500).json({
      success: false,
      error: 'Token refresh failed'
    });
  }
} 