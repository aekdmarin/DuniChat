import express from 'express';
import http from 'http';
import { WebSocketServer } from 'ws';
import bodyParser from 'body-parser';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { pool, init } from './db.js';

const app = express();
app.use(bodyParser.json());
await init();

const SECRET = process.env.JWT_SECRET || 'dunichat_secret';

// ============ AUTH ROUTES ==============
app.post('/signup', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ error: 'username y password requeridos' });

    const hash = await bcrypt.hash(password, 10);
    await pool.query('INSERT INTO users (username, password_hash) VALUES (,)', [username, hash]);
    res.json({ message: 'Usuario creado correctamente' });
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: 'Error creando usuario (puede existir)' });
  }
});

app.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const r = await pool.query('SELECT * FROM users WHERE username=', [username]);
    if (r.rows.length === 0) return res.status(401).json({ error: 'Usuario no encontrado' });

    const user = r.rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Contraseña incorrecta' });

    const token = jwt.sign({ username: user.username }, SECRET, { expiresIn: '7d' });
    res.json({ token });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error en login' });
  }
});

// ============ MESSAGE ROUTES ==============
app.get('/history/:room', async (req, res) => {
  const { room } = req.params;
  const limit = parseInt(req.query.limit || '30');
  const result = await pool.query(
    'SELECT username AS user, text, ts FROM messages WHERE room= ORDER BY ts DESC LIMIT ',
    [room, limit]
  );
  res.json(result.rows);
});

// ============ WEBSOCKET CHAT ==============
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

wss.on('connection', (ws, req) => {
  let username = 'anon';
  let room = 'global';

  ws.on('message', async (msg) => {
    try {
      const data = JSON.parse(msg.toString());
      if (data.token) {
        const decoded = jwt.verify(data.token, SECRET);
        username = decoded.username;
      }
      if (data.user) username = data.user;
      if (data.room) room = data.room;
      const ts = Date.now();

      if (data.text && data.text.trim() !== '') {
        await pool.query(
          'INSERT INTO messages (room, username, text, ts) VALUES (,,,)',
          [room, username, data.text, ts]
        );
      }

      const payload = JSON.stringify({ user: username, room, text: data.text, ts });
      wss.clients.forEach((c) => {
        if (c.readyState === 1) c.send(payload);
      });
      console.log("💾 Guardado en DB:", payload);
    } catch (err) {
      console.error('Error WS:', err.message);
      ws.send(JSON.stringify({ error: 'Token inválido o mensaje incorrecto' }));
    }
  });

  ws.on('close', () => console.log('🔌 Cliente desconectado'));
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => console.log('🚀 DuniChat con JWT activo en puerto', PORT));
