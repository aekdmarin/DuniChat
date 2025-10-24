import express from "express";
import http from "http";
import cors from "cors";
import { WebSocketServer } from "ws";

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 8080;
const server = http.createServer(app);
const wss = new WebSocketServer({ server });
const clients = new Set();

wss.on("connection", (ws) => {
  clients.add(ws);
  console.log("👤 Cliente conectado (" + clients.size + " total)");

  ws.on("message", (data) => {
    console.log("💬", data.toString());
    for (const client of clients) {
      if (client.readyState === 1) client.send(data.toString());
    }
  });

  ws.on("close", () => {
    clients.delete(ws);
    console.log("❌ Cliente desconectado (" + clients.size + " restantes)");
  });
});

app.get("/", (req, res) => {
  res.send("✅ DuniChat backend activo y escuchando WebSocket en /ws");
});

server.listen(PORT, () => {
  console.log(`🚀 DuniChat backend corriendo en puerto ${PORT}`);
});
