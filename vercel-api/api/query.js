const db = require('../lib/database');

export default async function handler(req, res) {
  // Handle CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

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
    const { sql, values = [] } = req.body;

    // Basic validation
    if (!sql || typeof sql !== 'string') {
      return res.status(400).json({
        success: false,
        error: 'SQL query is required and must be a string'
      });
    }

    // Security: Prevent dangerous operations (optional)
    const dangerousKeywords = ['DROP', 'DELETE', 'TRUNCATE', 'ALTER', 'CREATE'];
    const hasDangerousKeyword = dangerousKeywords.some(keyword => 
      sql.toUpperCase().includes(keyword)
    );

    if (hasDangerousKeyword) {
      console.warn('⚠️ Potentially dangerous SQL detected:', sql);
      // Uncomment the next line to block dangerous operations
      // return res.status(403).json({ success: false, error: 'Operation not allowed' });
    }

    console.log('🔍 Executing query:', sql);
    console.log('📊 Values:', values);

    const startTime = Date.now();
    const results = await db.query(sql, values);
    const executionTime = Date.now() - startTime;

    console.log(`✅ Query executed in ${executionTime}ms`);

    res.status(200).json({
      success: true,
      data: results,
      executionTime: executionTime,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('❌ Query error:', error);
    
    res.status(500).json({
      success: false,
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
} 