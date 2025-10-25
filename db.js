import pkg from "pg";
const { Pool } = pkg;

const connectionString =
  process.env.DATABASE_URL ||
  "postgresql://duniuser:2CDlvXngU9tFou9DIO7RO7BAPd4nsdFW@dpg-d3t4lqe3jp1c738h21o0-a/dunichatdb";

export const pool = new Pool({
  connectionString,
  ssl: process.env.PGSSLMODE === "disable" ? false : { rejectUnauthorized: false },
});

export async function init() {
  try {
    console.log("📡 Conectando a PostgreSQL...");
    const client = await pool.connect();

    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        username TEXT NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);

    client.release();
    console.log("✅ Tablas 'users' y 'messages' listas.");
  } catch (err) {
    console.error("❌ Error inicializando la base de datos:", err);
    throw err;
  }
}
