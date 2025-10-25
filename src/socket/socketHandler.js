const pool = require('../config/database');
const jwt = require('jsonwebtoken');

const setupSocketHandlers = (io) => {
  // Map para mantener usuarios conectados: userId -> socketId
  const onlineUsers = new Map();

  // Middleware de autenticación para Socket.io
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      
      if (!token) {
        return next(new Error('Token no proporcionado'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.userId;
      socket.username = decoded.username;
      next();
    } catch (error) {
      next(new Error('Token inválido'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.userId;
    
    console.log(`✅ Usuario conectado: ${socket.username} (ID: ${userId}, Socket: ${socket.id})`);

    // Agregar usuario a la lista de online
    onlineUsers.set(userId, socket.id);

    // Actualizar estado en base de datos
    pool.query(
      'UPDATE users SET is_online = true, last_seen = CURRENT_TIMESTAMP WHERE id = $1',
      [userId]
    ).catch(err => console.error('Error actualizando estado online:', err));

    // Notificar a otros usuarios que este usuario está online
    socket.broadcast.emit('user_online', { userId });

    // Usuario se une a su sala personal
    socket.join(`user_${userId}`);

    // ==================== ENVIAR MENSAJE ====================
    socket.on('send_message', async (data) => {
      try {
        const { receiverId, content, messageType = 'text', mediaUrl } = data;

        console.log(`📨 Mensaje de ${userId} a ${receiverId}: ${content}`);

        // Guardar mensaje en base de datos
        const result = await pool.query(
          `INSERT INTO messages (sender_id, receiver_id, content, message_type, media_url, is_delivered) 
           VALUES ($1, $2, $3, $4, $5, $6) 
           RETURNING *`,
          [userId, receiverId, content, messageType, mediaUrl, true]
        );

        const message = result.rows[0];

        // Preparar objeto de mensaje
        const messageData = {
          id: message.id,
          senderId: message.sender_id,
          receiverId: message.receiver_id,
          content: message.content,
          messageType: message.message_type,
          mediaUrl: message.media_url,
          isRead: message.is_read,
          isDelivered: message.is_delivered,
          createdAt: message.created_at
        };

        // Enviar al receptor si está conectado
        const receiverSocketId = onlineUsers.get(receiverId);
        if (receiverSocketId) {
          io.to(receiverSocketId).emit('receive_message', messageData);
          console.log(`✅ Mensaje entregado a ${receiverId}`);
        } else {
          console.log(`⏳ Usuario ${receiverId} está offline. Mensaje guardado.`);
        }

        // Confirmar al emisor
        socket.emit('message_sent', {
          ...messageData,
          tempId: data.tempId // Para sincronizar con el frontend
        });

      } catch (error) {
        console.error('❌ Error enviando mensaje:', error);
        socket.emit('message_error', { 
          error: 'Error al enviar mensaje',
          tempId: data.tempId 
        });
      }
    });

    // ==================== TYPING INDICATOR ====================
    socket.on('typing_start', (data) => {
      const { receiverId } = data;
      const receiverSocketId = onlineUsers.get(receiverId);
      
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_typing', { 
          userId,
          username: socket.username 
        });
      }
    });

    socket.on('typing_stop', (data) => {
      const { receiverId } = data;
      const receiverSocketId = onlineUsers.get(receiverId);
      
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('user_stopped_typing', { userId });
      }
    });

    // ==================== MARCAR COMO LEÍDO ====================
    socket.on('mark_as_read', async (data) => {
      try {
        const { messageIds, senderId } = data;

        if (!Array.isArray(messageIds) || messageIds.length === 0) {
          return;
        }

        // Actualizar mensajes como leídos
        await pool.query(
          `UPDATE messages 
           SET is_read = true, read_at = CURRENT_TIMESTAMP 
           WHERE id = ANY($1) AND receiver_id = $2`,
          [messageIds, userId]
        );

        // Notificar al remitente
        const senderSocketId = onlineUsers.get(senderId);
        if (senderSocketId) {
          io.to(senderSocketId).emit('messages_read', {
            messageIds,
            readBy: userId
          });
        }

        console.log(`✅ ${messageIds.length} mensajes marcados como leídos`);

      } catch (error) {
        console.error('❌ Error marcando mensajes como leídos:', error);
      }
    });

    // ==================== DESCONEXIÓN ====================
    socket.on('disconnect', () => {
      console.log(`❌ Usuario desconectado: ${socket.username} (ID: ${userId})`);

      // Remover de usuarios online
      onlineUsers.delete(userId);

      // Actualizar estado en base de datos
      pool.query(
        'UPDATE users SET is_online = false, last_seen = CURRENT_TIMESTAMP WHERE id = $1',
        [userId]
      ).catch(err => console.error('Error actualizando estado offline:', err));

      // Notificar a otros usuarios
      socket.broadcast.emit('user_offline', { 
        userId,
        lastSeen: new Date()
      });
    });

    // ==================== ERROR HANDLING ====================
    socket.on('error', (error) => {
      console.error('❌ Socket error:', error);
    });
  });

  // Función helper para obtener usuarios online
  io.getOnlineUsers = () => {
    return Array.from(onlineUsers.keys());
  };

  console.log('✅ Socket.io handlers configurados');
};

module.exports = setupSocketHandlers;
```

**Guarda:** `Ctrl + S`

---

## 🎉 ¡ESTRUCTURA COMPLETA!

Ya tienes todos los archivos creados. Tu estructura debería verse así:
```
C:\DuniChat\backend\
├── node_modules/
├── src/
│   ├── config/
│   │   └── database.js ✅
│   ├── controllers/
│   │   ├── authController.js ✅
│   │   └── messageController.js ✅
│   ├── middleware/
│   │   └── authMiddleware.js ✅
│   ├── routes/
│   │   ├── authRoutes.js ✅
│   │   └── messageRoutes.js ✅
│   ├── socket/
│   │   └── socketHandler.js ✅
│   └── server.js ✅
├── .env ✅
├── .gitignore ✅
├── package.json ✅
└── README.md ✅
```

---

## 🔥 PASO 3: Probar el servidor localmente (SIN base de datos)

Antes de conectar la base de datos, vamos a probar que el servidor arranca correctamente.

### 3.1 Modificar temporalmente .env

Abre `.env` y comenta la línea de DATABASE_URL:
```
PORT=3000
# DATABASE_URL=postgresql://localhost:5432/dunichat
JWT_SECRET=dunichat_secreto_super_seguro_2024_cambiar
NODE_ENV=development