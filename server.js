import express from "express";
import http from "http";
import cors from "cors";
import { WebSocketServer } from "ws";
import { init, saveMessage, getHistory } from "./db.js";

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 8080;
const server = http.createServer(app);

// WS en /ws
const wss = new WebSocketServer({ server, path: "/ws" });

// Salas en memoria (para broadcast en vivo)
const rooms = new Map(); // room -> Set<WebSocket>
function roomSet(room) {
  if (!rooms.has(room)) rooms.set(room, new Set());
  return rooms.get(room);
}

// Heartbeat para limpiar sockets muertos
function heartbeat() { this.isAlive = true; }

wss.on("connection", (ws, req) => {
  ws.isAlive = true;
  ws.on("pong", heartbeat);

  ws.meta = { user: "anon", room: "global" };
  roomSet("global").add(ws);

  // anunciar join
  broadcast(ws.meta.room, {
    sys: true, type: "join", text: `${ws.meta.user} se unió a ${ws.meta.room}`, ts: Date.now()
  });

  ws.on("message", async raw => {
    const txt = raw.toString();
    let msg;
    try { msg = JSON.parse(txt); }
    catch { msg = { text: txt }; }

    // user/room opcionales
    if (msg.user) ws.meta.user = String(msg.user).slice(0, 32);
    const targetRoom = msg.room ? String(msg.room).slice(0, 32) : ws.meta.room;

    // mover de sala si cambió
    if (targetRoom !== ws.meta.room) {
      roomSet(ws.meta.room).delete(ws);
      ws.meta.room = targetRoom;
      roomSet(ws.meta.room).add(ws);
      broadcast(ws.meta.room, {
        sys: true, type: "join", text: `${ws.meta.user} se unió a ${ws.meta.room}`, ts: Date.now()
      });
    }

    const payload = {
      user: ws.meta.user,
      room: ws.meta.room,
      text: msg.text ?? "",
      ts: Date.now()
    };

    // broadcast en vivo
    broadcast(ws.meta.room, payload);

    // guardar en DB (sin bloquear)
    try {
  await saveMessage(payload);
  console.log(`💾 Guardado en DB: ${payload.user} -> ${payload.room} :: "${payload.text}"`);
} catch (err) {
  console.error("❌ Error guardando mensaje en DB:", err?.message || err);
}
  });

  ws.on("close", () => {
    roomSet(ws.meta.room).delete(ws);
    broadcast(ws.meta.room, {
      sys: true, type: "leave",
      text: `${ws.meta.user} salió de ${ws.meta.room}`, ts: Date.now()
    });
  });
});

// ping periódico
const interval = setInterval(() => {
  wss.clients.forEach(ws => {
    if (ws.isAlive === false) return ws.terminate();
    ws.isAlive = false; ws.ping();
  });
}, 30000);
wss.on("close", () => clearInterval(interval));

function broadcast(room, obj) {
  const payload = JSON.stringify(obj);
  for (const client of roomSet(room)) {
    if (client.readyState === 1) client.send(payload);
  }
}

// REST: raíz
app.get("/", (req, res) => {
  res.json({ ok: true, ws: "/ws", history: "/history/:room?limit=50&before=ts" });
});

// REST: historial por sala
app.get("/history/:room", async (req, res) => {
  try {
    const room = String(req.params.room || "global");
    const limit = Number(req.query.limit || 50);
    const before = req.query.before ? Number(req.query.before) : null;
    const rows = await getHistory(room, limit, before);
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "history_error" });
  }
});

// Inicialización DB + arranque
await init();

server.listen(PORT, () => {
  console.log(`🚀 DuniChat backend en puerto ${PORT} (WS /ws, DB ready)`);
});

