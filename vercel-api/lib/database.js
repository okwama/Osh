const mysql = require('mysql2/promise');

// Database configuration from environment variables
const dbConfig = {
  host: process.env.DB_HOST || '102.218.215.35',
  user: process.env.DB_USER || 'citlogis_bryan',
  password: process.env.DB_PASSWORD || '@bo9511221.qwerty',
  database: process.env.DB_NAME || 'citlogis_ws',
  port: parseInt(process.env.DB_PORT) || 3306,
  // Connection pool settings for serverless
  connectionLimit: 10,
  connectTimeout: 60000,
  acquireTimeout: 60000,
  timeout: 60000,
  reconnect: true,
  charset: 'utf8mb4'
};

// Create connection pool
let pool = null;

async function getPool() {
  if (!pool) {
    pool = mysql.createPool(dbConfig);
  }
  return pool;
}

async function query(sql, values = []) {
  const connectionPool = await getPool();
  try {
    const [results] = await connectionPool.execute(sql, values);
    return results;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
}

async function transaction(callback) {
  const connectionPool = await getPool();
  const connection = await connectionPool.getConnection();
  
  try {
    await connection.beginTransaction();
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}

module.exports = {
  query,
  transaction,
  getPool
}; 