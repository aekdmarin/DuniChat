import express from "express";
import http from "http";
import { WebSocketServer } from "ws";
import pkg from "pg";
import cors from "cors";
import dotenv from "dotenv";
dotenv.config();

const { Pool } = pkg;
const app = express();
app.use(express.json());
app.use(cors());

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
});

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// --- WebSocket Real-Time Chat ---
wss.on("connection", (ws) => {
  ws.on("message", async (data) => {
    try {
      const msg = JSON.parse(data);
      const { sender, room, text } = msg;

      // Guardar en DB
      await pool.query(
        "INSERT INTO messages (sender, room, message) VALUES ($1, $2, $3)",
        [sender, room, text]
      );

      // Enviar a todos los clientes del mismo room
      wss.clients.forEach((client) => {
        if (client.readyState === 1) {
          client.send(JSON.stringify({ sender, text, room, timestamp: new Date() }));
        }
      });
    } catch (err) {
      console.error("❌ Error procesando mensaje:", err);
    }
  });
});

// --- Endpoint para historial ---
app.get("/history", async (req, res) => {
  const { room } = req.query;
  try {
    const result = await pool.query(
      "SELECT sender, message, timestamp FROM messages WHERE room=$1 ORDER BY timestamp ASC",
      [room]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).send("Error recuperando historial");
  }
});

app.get("/", (req, res) => res.send("✅ DuniChat backend activo"));
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`🌐 Servidor corriendo en puerto ${PORT}`));
