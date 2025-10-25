import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { init, pool } from "./db.js";
import { WebSocketServer } from "ws";
import http from "http";

const app = express();
app.use(cors());
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || "dunichat_secret";
const PORT = process.env.PORT || 3000;

// Inicializar base de datos
await init();

// ------------------------
// 🔹 Registro de usuario (corregido)
// ------------------------
app.post("/signup", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: "Faltan datos" });
    }

    const hash = await bcrypt.hash(password, 10);
    const queryText = `
      INSERT INTO users (username, password_hash)
      VALUES ($1, $2)
      ON CONFLICT (username) DO NOTHING
      RETURNING username;
    `;

    const result = await pool.query(queryText, [username, hash]);

    if (result.rows.length === 0) {
      console.log(`⚠️ Usuario existente: ${username}`);
      return res.status(400).json({ error: "Usuario ya existe" });
    }

    console.log(`✅ Usuario registrado: ${username}`);
    res.status(200).json({ message: "Usuario registrado correctamente" });
  } catch (err) {
    console.error("❌ Error en /signup:", err);
    res.status(500).json({ error: "Error interno en registro" });
  }
});

// ------------------------
// 🔹 Inicio de sesión
// ------------------------
app.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ error: "Faltan datos" });
    }

    const result = await pool.query(
      "SELECT * FROM users WHERE username = $1",
      [username]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: "Usuario no existe" });
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: "Contraseña incorrecta" });
    }

    const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: "24h" });
    console.log(`✅ Login exitoso: ${username}`);
    res.status(200).json({ token });
  } catch (err) {
    console.error("❌ Error en /login:", err);
    res.status(500).json({ error: "Error en login" });
  }
});

// ------------------------
// 🔹 Servidor HTTP + WebSocket (Render-compatible)
// ------------------------
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

wss.on("connection", (ws) => {
  console.log("🟢 Nueva conexión WebSocket");
  ws.on("message", (msg) => {
    console.log("💬 Mensaje recibido:", msg.toString());
  });
});

server.listen(PORT, () => {
  console.log(`🚀 Servidor HTTP+WS corriendo en puerto ${PORT}`);
});
