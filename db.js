import { Pool } from "pg";

const connStr = process.env.DATABASE_URL || "postgresql://localhost/postgres";

// Render Postgres suele requerir SSL; si no, puedes definir PGSSL=disable
const sslOpt = process.env.PGSSL === "disable" ? false : { rejectUnauthorized: false };

export const pool = new Pool({
  connectionString: connStr,
  ssl: sslOpt
});

export async function init() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS messages (
      id BIGSERIAL PRIMARY KEY,
      usr TEXT NOT NULL,
      room TEXT NOT NULL,
      txt  TEXT NOT NULL,
      ts   BIGINT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_messages_room_ts ON messages(room, ts DESC);
  `);
}

export async function saveMessage({ user, room, text, ts }) {
  await pool.query(
    "INSERT INTO messages(usr, room, txt, ts) VALUES($1,$2,$3,$4)",
    [user, room, text, ts]
  );
}

export async function getHistory(room, limit = 50, beforeTs = null) {
  const args = [room];
  let where = "room = $1";
  if (beforeTs) {
    args.push(Number(beforeTs));
    where += ` AND ts < $2`;
  }
  const res = await pool.query(
    `SELECT usr AS "user", room, txt AS text, ts
     FROM messages
     WHERE ${where}
     ORDER BY ts DESC
     LIMIT ${Number(limit) || 50}`
    , args
  );
  return res.rows;
}
