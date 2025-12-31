const mysql = require("mysql2");
require("dotenv").config();

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

const promisePool = pool.promise();

// Auto-retry test connection
async function testConnection(retries = 5) {
  try {
    const conn = await promisePool.getConnection();
    console.log("DB connected!");
    conn.release();
  } catch (err) {
    if (retries > 0) {
      console.log(`DB not ready, retrying... (${retries})`);
      await new Promise(res => setTimeout(res, 3000));
      await testConnection(retries - 1);
    } else {
      console.error("DB connection failed:", err.message);
    }
  }
}

testConnection();

module.exports = promisePool;
