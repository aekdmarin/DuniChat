import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import { init, pool } from "./db.js";
import { WebSocketServer } from "ws";

const app = express();
app.use(cors());
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || "dunichat_secret";

// Inicializa la base de datos
await init();

// ------------------------
// 🔹 Registro de usuario
// ------------------------
app.post("/signup", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: "Faltan datos" });

    const hash = await bcrypt.hash(password, 10);
    await pool.query(
      "INSERT INTO users (username, password_hash) VALUES ($1, $2)",
      [username, hash]
    );

    console.log(`✅ Usuario registrado: ${username}`);
    res.status(200).json({ message: "Usuario registrado correctamente" });
  } catch (err) {
    console.error("❌ Error en /signup:", err);
    if (err.code === "23505")
      res.status(400).json({ error: "Usuario ya existe" });
    else
      res.status(500).json({ error: "Error creando usuario" });
  }
});

// ------------------------
// 🔹 Inicio de sesión
// ------------------------
app.post("/login", async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: "Faltan datos" });

    const result = await pool.query(
      "SELECT * FROM users WHERE username = $1",
      [username]
    );

    if (result.rows.length === 0)
      return res.status(401).json({ error: "Usuario no existe" });

    const user = result.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid)
      return res.status(401).json({ error: "Contraseña incorrecta" });

    const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: "24h" });
    console.log(`✅ Login exitoso: ${username}`);
    res.status(200).json({ token });
  } catch (err) {
    console.error("❌ Error en /login:", err);
    res.status(500).json({ error: "Error en login" });
  }
});

// ------------------------
// 🔹 Servidor WebSocket
// ------------------------
const wss = new WebSocketServer({ port: 10000 });
wss.on("connection", (ws) => {
  console.log("🟢 Nueva conexión WebSocket");
  ws.on("message", (msg) => {
    console.log("💬 Mensaje recibido:", msg.toString());
  });
});

// ------------------------
// 🔹 Servidor HTTP
// ------------------------
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚀 API corriendo en puerto ${PORT}`));
