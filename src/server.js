const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const messageRoutes = require('./routes/messageRoutes');
const setupSocketHandlers = require('./socket/socketHandler');

// Inicializar Express
const app = express();
const server = http.createServer(app);

// Configurar Socket.io con CORS
const io = socketIo(server, {
  cors: {
    origin: "*", // En producción, cambiar por el dominio específico
    methods: ["GET", "POST"],
    credentials: true
  }
});

// Middleware globales
app.use(cors({
  origin: "*", // En producción, cambiar por el dominio específico
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Rutas de la API
app.use('/api/auth', authRoutes);
app.use('/api/messages', messageRoutes);

// Ruta de health check
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok',
    message: 'DuniChat API funcionando correctamente! 🚀',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Ruta de verificación de salud
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// Configurar manejadores de Socket.io
setupSocketHandlers(io);

// Hacer io accesible en toda la app
app.set('io', io);

// Manejo de errores global
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Error interno del servidor',
    status: err.status || 500
  });
});

// Manejo de rutas no encontradas
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Ruta no encontrada',
    path: req.originalUrl
  });
});

// Puerto del servidor
const PORT = process.env.PORT || 3000;

// Iniciar servidor
server.listen(PORT, () => {
  console.log('=================================');
  console.log('🚀 DuniChat Backend iniciado');
  console.log(`📡 Servidor corriendo en puerto ${PORT}`);
  console.log(`🌍 Entorno: ${process.env.NODE_ENV || 'development'}`);
  console.log(`⏰ Hora: ${new Date().toLocaleString()}`);
  console.log('=================================');
});

// Manejo de cierre graceful
process.on('SIGTERM', () => {
  console.log('SIGTERM recibido, cerrando servidor...');
  server.close(() => {
    console.log('Servidor cerrado');
    process.exit(0);
  });
});

module.exports = { app, server, io };