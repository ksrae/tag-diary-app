import pg from 'pg';
import "dotenv/config";

const { Client } = pg;

const client = new Client({
  connectionString: process.env.SUPABASE_DB_URL,
});

async function testConnection() {
  try {
    console.log("Connecting to:", process.env.SUPABASE_DB_URL.replace(/:[^:@]+@/, ':****@')); // Hide password
    await client.connect();
    console.log("✅ Connection successful!");
    const res = await client.query('SELECT NOW()');
    console.log("Server time:", res.rows[0]);
    await client.end();
  } catch (err) {
    console.error("❌ Connection failed:", err);
  }
}

testConnection();
